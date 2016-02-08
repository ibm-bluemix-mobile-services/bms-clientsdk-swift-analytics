/*
*     Copyright 2015 IBM Corp.
*     Licensed under the Apache License, Version 2.0 (the "License");
*     you may not use this file except in compliance with the License.
*     You may obtain a copy of the License at
*     http://www.apache.org/licenses/LICENSE-2.0
*     Unless required by applicable law or agreed to in writing, software
*     distributed under the License is distributed on an "AS IS" BASIS,
*     WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
*     See the License for the specific language governing permissions and
*     limitations under the License.
*/


import BMSCore


// Stores all logs (for both Logger and Analytics) to the device's file system
public class LogRecorder: LogSaverProtocol {
    
    
    // MARK: Dispatch queues
    
    // We use serial queues to prevent race conditions when multiple threads try to read/modify the same file
    
    internal static let loggerFileIOQueue: dispatch_queue_t = dispatch_queue_create("com.ibm.mobilefirstplatform.clientsdk.swift.BMSCore.Logger.loggerFileIOQueue", DISPATCH_QUEUE_SERIAL)
    
    
    internal static let analyticsFileIOQueue: dispatch_queue_t = dispatch_queue_create("com.ibm.mobilefirstplatform.clientsdk.swift.BMSCore.Logger.analyticsFileIOQueue", DISPATCH_QUEUE_SERIAL)
    
    
    
    // MARK: Methods (public)
    
    // This is the master function that handles all of the logging, including level checking, printing to console, and writing to file
    // All other log functions below this one are helpers for this function
    
    public func logMessageToFile(message: String, level: LogLevel, loggerName: String, calledFile: String, calledFunction: String, calledLineNumber: Int, additionalMetadata: [String: AnyObject]? = nil) {
        
        let group :dispatch_group_t = dispatch_group_create()
        
        // Writing to file
        
        if level == LogLevel.Analytics {
            guard Analytics.enabled else {
                return
            }
        }
        else {
            guard Logger.logStoreEnabled else {
                return
            }
        }
        
        // Get file names and the dispatch queue needed to access those files
        let (logFile, logOverflowFile, fileDispatchQueue) = LogRecorder.getFilesForLogLevel(level)
        
        dispatch_group_async(group, fileDispatchQueue) { () -> Void in
            // Check if the log file is larger than the maxLogStoreSize. If so, move the log file to the "overflow" file, and start logging to a new log file. If an overflow file already exists, those logs get overwritten.
            if LogRecorder.fileLogIsFull(logFile) {
                do {
                    try LogRecorder.moveOldLogsToOverflowFile(logFile, overflowFile: logOverflowFile)
                }
                catch let error {
                    let logFileName = LogRecorder.extractFileNameFromPath(logFile)
                    print("Log file \(logFileName) is full but the old logs could not be removed. Try sending the logs. Error: \(error)")
                    return
                }
            }
            
            let timeStampString = Logger.dateFormatter.stringFromDate(NSDate())
            var logAsJsonString = LogRecorder.convertLogToJson(message, level: level, loggerName: loggerName, timeStamp: timeStampString, additionalMetadata: additionalMetadata)
            
            guard logAsJsonString != nil else {
                let errorMessage = "Failed to write logs to file. This is likely because the analytics metadata could not be parsed."
                Logger.printLogToConsole(errorMessage, loggerName:loggerName, level: .Error, calledFunction: __FUNCTION__, calledFile: __FILE__, calledLineNumber: __LINE__)
                return
            }
            
            logAsJsonString! += "," // Logs must be comma-separated
            
            LogRecorder.writeToFile(logFile, logMessage: logAsJsonString!, loggerName: loggerName)
            
        }
        
        // The wait is necessary to prevent race conditions - Only one operation can occur on this queue at a time
        dispatch_group_wait(group, DISPATCH_TIME_FOREVER)
    }
    
    
    
    // MARK: Methods (internal/private)
    
    // Get the full path to the log file and overflow file, and get the dispatch queue that they need to be operated on.
    internal static func getFilesForLogLevel(level: LogLevel) -> (String, String, dispatch_queue_t) {
        
        var logFile: String = Logger.logsDocumentPath
        var logOverflowFile: String = Logger.logsDocumentPath
        var fileDispatchQueue: dispatch_queue_t
        
        if level == LogLevel.Analytics {
            logFile += Logger.FILE_ANALYTICS_LOGS
            logOverflowFile += Logger.FILE_ANALYTICS_OVERFLOW
            fileDispatchQueue = LogRecorder.analyticsFileIOQueue
        }
        else {
            logFile += Logger.FILE_LOGGER_LOGS
            logOverflowFile += Logger.FILE_LOGGER_OVERFLOW
            fileDispatchQueue = LogRecorder.loggerFileIOQueue
        }
        
        return (logFile, logOverflowFile, fileDispatchQueue)
    }
    
    
    // Check if the log file size exceeds the limit set by the Logger.maxLogStoreSize property
    // Logs are actually distributed evenly between a "normal" log file and an "overflow" file, but we only care if the "normal" log file is full (half of the total maxLogStoreSize)
    internal static func fileLogIsFull(logFileName: String) -> Bool {
        
        if (Logger.fileManager.fileExistsAtPath(logFileName)) {
            
            do {
                let attr : NSDictionary? = try NSFileManager.defaultManager().attributesOfItemAtPath(logFileName)
                if let currentLogFileSize = attr?.fileSize() {
                    return currentLogFileSize > Logger.maxLogStoreSize / 2 // Divide by 2 since the total log storage gets shared between the log file and the overflow file
                }
            }
            catch let error {
                let logFile = LogRecorder.extractFileNameFromPath(logFileName)
                print("Cannot determine the size of file:\(logFile) due to error: \(error). In case the file size is greater than the specified max log storage size, logs will not be written to file.")
            }
        }
        
        return false
    }
    
    
    // When the log file is full, the old logs are moved to the overflow file to make room for new logs
    internal static func moveOldLogsToOverflowFile(logFile: String, overflowFile: String) throws {
        
        if Logger.fileManager.fileExistsAtPath(overflowFile) && Logger.fileManager.isDeletableFileAtPath(overflowFile) {
            try Logger.fileManager.removeItemAtPath(overflowFile)
        }
        try Logger.fileManager.moveItemAtPath(logFile, toPath: overflowFile)
    }
    
    
    // Convert log message and metadata into JSON format. This is the actual string that gets written to the log files.
    internal static func convertLogToJson(logMessage: String, level: LogLevel, loggerName: String, timeStamp: String, additionalMetadata: [String: AnyObject]?) -> String? {
        
        var logMetadata: [String: AnyObject] = [:]
        logMetadata[Logger.TAG_TIMESTAMP] = timeStamp
        logMetadata[Logger.TAG_LEVEL] = level.stringValue
        logMetadata[Logger.TAG_PACKAGE] = loggerName
        logMetadata[Logger.TAG_MESSAGE] = logMessage
        if additionalMetadata != nil {
            logMetadata[Logger.TAG_METADATA] = additionalMetadata! // Typically only available if the Logger.analytics method was called
        }
        
        let logData: NSData
        do {
            logData = try NSJSONSerialization.dataWithJSONObject(logMetadata, options: [])
        }
        catch {
            return nil
        }
        
        return String(data: logData, encoding: NSUTF8StringEncoding)
    }
    
    
    // Append log message to the end of the log file
    internal static func writeToFile(file: String, logMessage: String, loggerName: String) {
        
        if !Logger.fileManager.fileExistsAtPath(file) {
            Logger.fileManager.createFileAtPath(file, contents: nil, attributes: nil)
        }
        
        let fileHandle = NSFileHandle(forWritingAtPath: file)
        let data = logMessage.dataUsingEncoding(NSUTF8StringEncoding)
        if fileHandle != nil && data != nil {
            fileHandle!.seekToEndOfFile()
            fileHandle!.writeData(data!)
            fileHandle!.closeFile()
        }
        else {
            let errorMessage = "Cannot write to file: \(file)."
            Logger.printLogToConsole(errorMessage, loggerName: loggerName, level: LogLevel.Error, calledFunction: __FUNCTION__, calledFile: __FILE__, calledLineNumber: __LINE__)
        }
        
    }
    
    
    // When logging messages to the user, make sure to only mention the log file name, not the full path since it may contain sensitive data unique to the device.
    internal static func extractFileNameFromPath(filePath: String) -> String {
        
        var logFileName = "[Unknown]"
        
        let logFileNameRange = filePath.rangeOfString("/", options:NSStringCompareOptions.BackwardsSearch)
        if let fileNameStartIndex = logFileNameRange?.startIndex.successor() {
            if fileNameStartIndex < filePath.endIndex {
                logFileName = filePath[fileNameStartIndex..<filePath.endIndex]
            }
        }
        return logFileName
    }
    
}
