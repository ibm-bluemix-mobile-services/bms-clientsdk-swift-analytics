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


// TODO: Refactor this entire file so that it is better organized and more readable. Consider using extensions or other classes.

/**
    Logger is used to capture log messages and send them to a mobile analytics server.

    When this class's `enabled` property is set to `true` (which is the default value), logs will be persisted to a file on the client device in the following JSON format:

        {
            "timestamp"    : "17-02-2013 13:54:27:123",   // "dd-MM-yyyy hh:mm:ss:S"
            "level"        : "ERROR",                     // FATAL || ERROR || WARN || INFO || DEBUG
            "name"         : "your_logger_name",          // The name of the Logger (typically a class name or app name)
            "msg"          : "the message",               // Some log message
            "metadata"     : {"some key": "some value"},  // Additional JSON metadata (only for Analytics logging)
        }

    Logs are accumulated persistently to the log file until the file size is greater than the `Logger.maxLogStoreSize` property. At this point, half of the old logs will be deleted to make room for new log data.

    Log file data is sent to the Bluemix server when the Logger `send()` method is called, provided that the file is not empty and the BMSClient was initialized via the `initializeWithBluemixAppRoute()` method. When the log data is successfully uploaded, the persisted local log data is deleted.

    - Note: The `Logger` class sets an uncaught exception handler to log application crashes. If you wish to set your own exception handler, do so **before** calling `Logger.getLoggerForName()` or the `Logger` exception handler will be overwritten.
*/
extension Logger {
    
    
    // MARK: Constants 
    
    internal static let HOST_NAME = "mfp-analytics-server"
    internal static let UPLOAD_PATH =  "/imfmobileanalytics/v1/receiver/apps/"
    internal static let API_ID_HEADER = "x-mfp-analytics-api-key"
    
    internal static let TAG_METADATA = "metadata"
    internal static let TAG_UNCAUGHT_EXCEPTION = "loggerUncaughtExceptionDetected"
    internal static let TAG_LEVEL = "level"
    internal static let TAG_TIMESTAMP = "timestamp"
    internal static let TAG_PACKAGE = "pkg"
    internal static let TAG_MESSAGE = "msg"
    
    internal static let MFP_LOGGER_PACKAGE = MFP_PACKAGE_PREFIX + "logger"
    internal static let FILE_LOGGER_LOGS = MFP_LOGGER_PACKAGE + ".log"
    internal static let FILE_LOGGER_SEND = MFP_LOGGER_PACKAGE + ".log.send"
    internal static let FILE_LOGGER_OVERFLOW = MFP_LOGGER_PACKAGE + ".log.overflow"
    
    internal static let MFP_ANALYTICS_PACKAGE = MFP_PACKAGE_PREFIX + "analytics"
    internal static let FILE_ANALYTICS_LOGS = MFP_ANALYTICS_PACKAGE + ".log"
    internal static let FILE_ANALYTICS_SEND = MFP_ANALYTICS_PACKAGE + ".log.send"
    internal static let FILE_ANALYTICS_OVERFLOW = MFP_ANALYTICS_PACKAGE + ".log.overflow"

    internal static let ANALYTICS_ERROR_CODE = "com.ibm.mobilefirstplatform.clientsdk.swift.BMSAnalytics"
    
    internal static let DEFAULT_MAX_STORE_SIZE: UInt64 = 100000
    
    
    
    // MARK: Properties (API)
    
    /// Determines whether logs get written to file on the client device.
    /// Must be set to `true` to be able to send logs to the Bluemix server.
    public static var logStoreEnabled: Bool = true
    
    /// The maximum file size (in bytes) for log storage.
    /// Both the Analytics and Logger log files are limited by `maxLogStoreSize`.
    public static var maxLogStoreSize: UInt64 = DEFAULT_MAX_STORE_SIZE
    
    /// Enables log recording of app crashes due to uncaught exceptions.
    public static var captureUncaughtExceptions: Bool = false {
        didSet {
            if captureUncaughtExceptions {
                Logger.startCapturingUncaughtExceptions()
            }
        }
    }
    
    /// True if the app crashed recently due to an uncaught exception.
    /// This property will be set back to `false` if the logs are sent to the server.
    public static var isUncaughtExceptionDetected: Bool {
        get {
            return NSUserDefaults.standardUserDefaults().boolForKey(TAG_UNCAUGHT_EXCEPTION)
        }
        set {
            NSUserDefaults.standardUserDefaults().setBool(newValue, forKey: TAG_UNCAUGHT_EXCEPTION)
        }
    }
    
    
    
    // MARK: Properties (internal/private)
    
    // Internal instrumentation for troubleshooting issues in BMSCore
    internal static let internalLogger = Logger.getLoggerForName(MFP_LOGGER_PACKAGE)
    
    
    
    // MARK: Class constants (internal/private)
    
    // By default, the dateFormater will convert to the local time zone, but we want to send the date based on UTC
    // so that logs from all clients in all timezones are normalized to the same GMT timezone.
    internal static let dateFormatter: NSDateFormatter = Logger.generateDateFormatter()
    
    private static func generateDateFormatter() -> NSDateFormatter {
        
        let formatter = NSDateFormatter()
        formatter.locale = NSLocale(localeIdentifier: "en_US_POSIX")
        formatter.timeZone = NSTimeZone(name: "GMT")
        formatter.dateFormat = "dd-MM-yyyy HH:mm:ss:SSS"
        
        return formatter
    }
    
    // Path to the log files on the client device
    internal static let logsDocumentPath: String = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0] + "/"
    
    private static let fileManager = NSFileManager.defaultManager()
    
    
    
    // MARK: Dispatch queues
    
    // We use serial queues to prevent race conditions when multiple threads try to read/modify the same file
    
    private static let loggerFileIOQueue: dispatch_queue_t = dispatch_queue_create("com.ibm.mobilefirstplatform.clientsdk.swift.BMSCore.Logger.loggerFileIOQueue", DISPATCH_QUEUE_SERIAL)
    
    
    private static let analyticsFileIOQueue: dispatch_queue_t = dispatch_queue_create("com.ibm.mobilefirstplatform.clientsdk.swift.BMSCore.Logger.analyticsFileIOQueue", DISPATCH_QUEUE_SERIAL)
    
    
    private static let sendLogsToServerQueue: dispatch_queue_t = dispatch_queue_create("com.ibm.mobilefirstplatform.clientsdk.swift.BMSCore.Logger.sendLogsToServerQueue", DISPATCH_QUEUE_SERIAL)
    
    
    private static let sendAnalyticsToServerQueue: dispatch_queue_t = dispatch_queue_create("com.ibm.mobilefirstplatform.clientsdk.swift.BMSCore.Logger.sendAnalyticsToServerQueue", DISPATCH_QUEUE_SERIAL)
    
    
    private static let updateLogProfileQueue: dispatch_queue_t = dispatch_queue_create("com.ibm.mobilefirstplatform.clientsdk.swift.BMSCore.Logger.updateLogProfileQueue", DISPATCH_QUEUE_SERIAL)

    
    // Custom dispatch_sync that can incorporate throwable statements
    internal static func dispatch_sync_throwable(queue: dispatch_queue_t, block: () throws -> ()) throws {
        
        var error: ErrorType?
        dispatch_sync(queue) {
            do {
                try block()
            }
            catch let caughtError {
                error = caughtError
            }
        }
        if error != nil {
            throw error!
        }
    }

    
    
    // MARK: Log methods (helpers)
    
    // Equivalent to the other log methods, but this method accepts data as JSON rather than a string
    internal func analytics(metadata: [String: AnyObject], file: String = __FILE__, function: String = __FUNCTION__, line: Int = __LINE__) {
        
        logMessage("", level: LogLevel.Analytics, calledFile: file, calledFunction: function, calledLineNumber: line, additionalMetadata: metadata)
    }
    
    
    
    // MARK: Uncaught Exceptions
    
    // If the user set their own uncaught exception handler earlier, it gets stored here
    internal static let existingUncaughtExceptionHandler = NSGetUncaughtExceptionHandler()
    
    // This flag prevents infinite loops of uncaught exceptions
    private static var exceptionHasBeenCalled = false
    
    internal static func startCapturingUncaughtExceptions() {
        
        NSSetUncaughtExceptionHandler { (caughtException: NSException) -> Void in
            
            if (!Logger.exceptionHasBeenCalled) {
                Logger.exceptionHasBeenCalled = true
                Logger.logException(caughtException)
                // Persist a flag so that when the app starts back up, we can see if an exception occurred in the last session
                Logger.isUncaughtExceptionDetected = true
                Logger.existingUncaughtExceptionHandler?(caughtException)
            }
        }
    }
    
    
    internal static func logException(exception: NSException) {
        
        let logger = Logger.getLoggerForName(MFP_LOGGER_PACKAGE)
        var exceptionString = "Uncaught Exception: \(exception.name)."
        if let reason = exception.reason {
            exceptionString += " Reason: \(reason)."
        }
        logger.fatal(exceptionString)
    }
    
    
    
    // MARK: Sending logs
    
    
    /**
        Send the accumulated logs to the Bluemix server.
        
        Logger logs can only be sent if the BMSClient was initialized via the `initializeWithBluemixAppRoute()` method.
        
        - parameter completionHandler:  Optional callback containing the results of the send request
    */
    public static func send(completionHandler userCallback: MfpCompletionHandler? = nil) {

        let logSendCallback: MfpCompletionHandler = { (response: Response?, error: NSError?) in
            
            if error == nil && response?.statusCode == 201 {
                Logger.internalLogger.debug("Client logs successfully sent to the server.")
                
                deleteBufferFile(FILE_LOGGER_SEND)
                // Remove the uncaught exception flag since the logs containing the exception(s) have just been sent to the server
                NSUserDefaults.standardUserDefaults().setBool(false, forKey: TAG_UNCAUGHT_EXCEPTION)
            }
            else {
                Logger.internalLogger.error("Request to send client logs has failed.")
            }
            
            userCallback?(response, error)
        }
        
        // Use a serial queue to ensure that the same logs do not get sent more than once
        dispatch_async(Logger.sendLogsToServerQueue) { () -> Void in
            do {
                let logsToSend: String? = try getLogs(fileName: FILE_LOGGER_LOGS, overflowFileName: FILE_LOGGER_OVERFLOW, bufferFileName: FILE_LOGGER_SEND)
                if logsToSend != nil {
                    if let (request, logPayload) = buildLogSendRequest(logsToSend!, withCallback: logSendCallback){
                        // Everything went as expected, so send the logs!
                        request.sendString(logPayload, withCompletionHandler: logSendCallback)
                    }
                    
                }
                else {
                    Logger.internalLogger.info("There are no logs to send.")
                }
            }
            catch let error as NSError {
                logSendCallback(nil, error)
            }
        }
    }
    
    
    // Same as the other send() method but for analytics
    internal static func sendAnalytics(completionHandler userCallback: MfpCompletionHandler? = nil) {
    
        // Internal completion handler - wraps around the user supplied completion handler (if supplied)
        let analyticsSendCallback: MfpCompletionHandler = { (response: Response?, error: NSError?) in
            
            if error == nil && response?.statusCode == 201 {
                Analytics.logger.debug("Analytics data successfully sent to the server.")
                
                deleteBufferFile(FILE_ANALYTICS_SEND)
            }
            else {
                Analytics.logger.error("Request to send analytics data to the server has failed.")
            }
            
            userCallback?(response, error)
        }
        
        // Use a serial queue to ensure that the same analytics data do not get sent more than once
        dispatch_async(Logger.sendAnalyticsToServerQueue) { () -> Void in
            do {
                let logsToSend: String? = try getLogs(fileName: FILE_ANALYTICS_LOGS, overflowFileName:FILE_ANALYTICS_OVERFLOW, bufferFileName: FILE_ANALYTICS_SEND)
                if logsToSend != nil {
                    if let (request, logPayload) = buildLogSendRequest(logsToSend!, withCallback: analyticsSendCallback){
                        request.sendString(logPayload, withCompletionHandler: analyticsSendCallback)
                    }

                }
                else {
                    Analytics.logger.info("There are no analytics data to send.")
                }
            }
            catch let error as NSError {
                analyticsSendCallback(nil, error)
            }
        }
    }
    
    
    // Build the Request object that will be used to send the logs to the server
    internal static func buildLogSendRequest(logs: String, withCallback callback: MfpCompletionHandler) -> (MFPRequest, String)? {
        
        let bmsClient = BMSClient.sharedInstance
        var headers = ["Content-Type": "application/json"]
    
        guard let appGuid = bmsClient.bluemixAppGUID else {
            returnInitializationError("BMSClient", missingValue: "bluemixAppGUID", callback: callback)
            return nil
        }
        
        guard Analytics.apiKey != nil && Analytics.apiKey != "" else {
            returnInitializationError("Analytics", missingValue: "apiKey", callback: callback)
            return nil
        }
        
        headers[API_ID_HEADER] = Analytics.apiKey!
    
        let logUploaderUrl = "https://" + HOST_NAME + bmsClient.bluemixRegionSuffix! + UPLOAD_PATH + appGuid
        
        let logPayload = "[" + logs + "]"
        
        let request = MFPRequest(url: logUploaderUrl, headers: headers, queryParameters: nil, method: HttpMethod.POST)
        return (request, logPayload)
    }
    
    
    // If this is reached, the user most likely failed to initialize BMSClient or Analytics
    internal static func returnInitializationError(uninitializedClass: String, missingValue: String, callback: MfpCompletionHandler) {
        
        Logger.internalLogger.error("No value found for the \(uninitializedClass) \(missingValue) property.")
        let errorMessage = "Must initialize \(uninitializedClass) before sending logs to the server."
        
        var errorCode: Int
        switch uninitializedClass {
        case "Analytics":
            errorCode = AnalyticsErrorCode.AnalyticsNotInitialized.rawValue
        case "BMSClient":
            errorCode = MFPErrorCode.ClientNotInitialized.rawValue
        default:
            errorCode = -1
        }
        
        let error = NSError(domain: ANALYTICS_ERROR_CODE, code: errorCode, userInfo: [NSLocalizedDescriptionKey: errorMessage])
        
        callback(nil, error)
    }
    
    
    // Read the logs from file, move them to the "send" buffer file, and return the logs
    internal static func getLogs(fileName fileName: String, overflowFileName: String, bufferFileName: String) throws -> String? {
        
        let logFile = Logger.logsDocumentPath + fileName // Original log file
        let overflowLogFile = Logger.logsDocumentPath + overflowFileName // Extra file in case original log file got full
        let bufferLogFile = Logger.logsDocumentPath + bufferFileName // Temporary file for sending logs
        
        // First check if the "*.log.send" buffer file already contains logs. This will be the case if the previous attempt to send logs failed.
        if Logger.fileManager.isReadableFileAtPath(bufferLogFile) {
            return try readLogsFromFile(bufferLogFile)
        }
        else if Logger.fileManager.isReadableFileAtPath(logFile) {
            // Merge the logs from the normal log file and the overflow log file (if necessary)
            if Logger.fileManager.isReadableFileAtPath(overflowLogFile) {
                let fileContents = try NSString(contentsOfFile: overflowLogFile, encoding: NSUTF8StringEncoding) as String
                LogSaver.writeToFile(logFile, logMessage: fileContents, loggerName: Logger.internalLogger.name)
            }
            
            // Since the buffer log is empty, we move the log file to the buffer file in preparation of sending the logs. When new logs are recorded, a new log file gets created to replace it.
            try Logger.fileManager.moveItemAtPath(logFile, toPath: bufferLogFile)
            return try readLogsFromFile(bufferLogFile)
        }
        else {
            Logger.internalLogger.error("Cannot send data to server. Unable to read file: \(fileName).")
            return nil
        }
    }
    
    
    // We should only be sending logs from a buffer file, which is a copy of the normal log file. This way, if the logs fail to get sent to the server, we can hold onto them until the send succeeds, while continuing to log to the normal log file.
    internal static func readLogsFromFile(bufferLogFile: String) throws -> String? {
        
        let ANALYTICS_SEND = Logger.logsDocumentPath + FILE_ANALYTICS_SEND
        let LOGGER_SEND = Logger.logsDocumentPath + FILE_LOGGER_SEND
        

        var fileContents: String?
        
        do {
            // Before sending the logs, we need to read them from the file. This is done in a serial dispatch queue to prevent conflicts if the log file is simulatenously being written to.
            switch bufferLogFile {
            case ANALYTICS_SEND:
                try dispatch_sync_throwable(Logger.analyticsFileIOQueue, block: { () -> () in
                    fileContents = try NSString(contentsOfFile: bufferLogFile, encoding: NSUTF8StringEncoding) as String
                })
            case LOGGER_SEND:
                try dispatch_sync_throwable(Logger.loggerFileIOQueue, block: { () -> () in
                    fileContents = try NSString(contentsOfFile: bufferLogFile, encoding: NSUTF8StringEncoding) as String
                })
            default:
                Logger.internalLogger.error("Cannot send data to server. Unrecognized file: \(bufferLogFile).")
            }
        }
        
        return fileContents
    }
    
    
    // The buffer file is typically the one used for storing logs that will be sent to the server
    internal static func deleteBufferFile(bufferFile: String) {
        
        if Logger.fileManager.isDeletableFileAtPath(bufferFile) {
            do {
                try Logger.fileManager.removeItemAtPath(bufferFile)
            }
            catch let error {
                Logger.internalLogger.error("Failed to delete log file \(bufferFile) after sending. Error: \(error)")
            }
        }
    }
    
    
    
    // MARK: Server configuration
    
    // TODO: Implement once the behavior of this method has been determined
    internal func updateLogProfile(withCompletionHandler callback: MfpCompletionHandler? = nil) { }

}



// Stores all logs (including analytics) to the device's file system
public class LogSaver: LogSaverProtocol {
    
    
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
        let (logFile, logOverflowFile, fileDispatchQueue) = LogSaver.getFilesForLogLevel(level)
        
        dispatch_group_async(group, fileDispatchQueue) { () -> Void in
            // Check if the log file is larger than the maxLogStoreSize. If so, move the log file to the "overflow" file, and start logging to a new log file. If an overflow file already exists, those logs get overwritten.
            if LogSaver.fileLogIsFull(logFile) {
                do {
                    try LogSaver.moveOldLogsToOverflowFile(logFile, overflowFile: logOverflowFile)
                }
                catch let error {
                    let logFileName = LogSaver.extractFileNameFromPath(logFile)
                    print("Log file \(logFileName) is full but the old logs could not be removed. Try sending the logs. Error: \(error)")
                    return
                }
            }
            
            let timeStampString = Logger.dateFormatter.stringFromDate(NSDate())
            var logAsJsonString = LogSaver.convertLogToJson(message, level: level, loggerName: loggerName, timeStamp: timeStampString, additionalMetadata: additionalMetadata)
            
            guard logAsJsonString != nil else {
                let errorMessage = "Failed to write logs to file. This is likely because the analytics metadata could not be parsed."
                Logger.printLogToConsole(errorMessage, loggerName:loggerName, level: .Error, calledFunction: __FUNCTION__, calledFile: __FILE__, calledLineNumber: __LINE__)
                return
            }
            
            logAsJsonString! += "," // Logs must be comma-separated
            
            LogSaver.writeToFile(logFile, logMessage: logAsJsonString!, loggerName: loggerName)
            
        }
        
        // The wait is necessary to prevent race conditions - Only one operation can occur on this queue at a time
        dispatch_group_wait(group, DISPATCH_TIME_FOREVER)
    }
    
    
    // Get the full path to the log file and overflow file, and get the dispatch queue that they need to be operated on.
    internal static func getFilesForLogLevel(level: LogLevel) -> (String, String, dispatch_queue_t) {
        
        var logFile: String = Logger.logsDocumentPath
        var logOverflowFile: String = Logger.logsDocumentPath
        var fileDispatchQueue: dispatch_queue_t
        
        if level == LogLevel.Analytics {
            logFile += Logger.FILE_ANALYTICS_LOGS
            logOverflowFile += Logger.FILE_ANALYTICS_OVERFLOW
            fileDispatchQueue = Logger.analyticsFileIOQueue
        }
        else {
            logFile += Logger.FILE_LOGGER_LOGS
            logOverflowFile += Logger.FILE_LOGGER_OVERFLOW
            fileDispatchQueue = Logger.loggerFileIOQueue
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
                let logFile = LogSaver.extractFileNameFromPath(logFileName)
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
