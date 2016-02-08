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


/// TODO: Refactor this entire file so that it is better organized and more readable. Consider using extensions or other classes. Idea: Logger.swift, LogRecorder.swift, and LogSender.swift


extension Logger {
    
    
    /// TODO: Improve use of constants
    
    // MARK: Constants 
    
    internal static let HOST_NAME = "mobile-analytics-dashboard"
    internal static let UPLOAD_PATH =  "/analytics-service/data/events/clientlogs/"
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
    public static var logStoreEnabled: Bool = false
    
    /// The maximum file size (in bytes) for log storage.
    /// Both the Analytics and Logger log files are limited by `maxLogStoreSize`.
    public static var maxLogStoreSize: UInt64 = DEFAULT_MAX_STORE_SIZE
    
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
    
    internal static let fileManager = NSFileManager.defaultManager()
    
    
    
    // MARK: Methods (API)
    
    /**
        Send the accumulated logs to the Bluemix server.
        
        Logger logs can only be sent if the BMSClient was initialized via the `initializeWithBluemixAppRoute()` method.
        
        - parameter completionHandler:  Optional callback containing the results of the send request
    */
    public static func send(completionHandler userCallback: MfpCompletionHandler? = nil) {
     
        LogSender.send(completionHandler: userCallback)
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
                // Persist a flag so that when the app starts back up, we can see if an exception occurred in the last session
                Logger.exceptionHasBeenCalled = true
                Logger.isUncaughtExceptionDetected = true
                
                Logger.logException(caughtException)
                Analytics.logSessionEnd()
                
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

}


// Custom dispatch_sync that can incorporate throwable statements
internal func dispatch_sync_throwable(queue: dispatch_queue_t, block: () throws -> ()) throws {
    
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
