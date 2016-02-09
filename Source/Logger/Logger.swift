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


extension Logger {

    
    // MARK: Properties (API)
    
    /// Determines whether logs get written to file on the client device.
    /// Must be set to `true` to be able to send logs to the Bluemix server.
    public static var logStoreEnabled: Bool = false
    
    /// The maximum file size (in bytes) for log storage.
    /// Both the Analytics and Logger log files are limited by `maxLogStoreSize`.
    public static var maxLogStoreSize: UInt64 = Constants.File.defaultMaxSize
    
    /// True if the app crashed recently due to an uncaught exception.
    /// This property will be set back to `false` if the logs are sent to the server.
    public static var isUncaughtExceptionDetected: Bool {
        get {
            return NSUserDefaults.standardUserDefaults().boolForKey(Constants.uncaughtException)
        }
        set {
            NSUserDefaults.standardUserDefaults().setBool(newValue, forKey: Constants.uncaughtException)
        }
    }
    
    
    
    // MARK: Properties (internal/private)
    
    // Internal instrumentation for troubleshooting issues in BMSCore
    internal static let internalLogger = Logger.getLoggerForName(Constants.Package.logger)
    
    
    
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
        
        let logger = Logger.getLoggerForName(Constants.Package.logger)
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
