/*
*     Copyright 2016 IBM Corp.
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


// Sends stored logs to the Analytics server
internal class LogSender {
    
    
    // MARK: Dispatch queues
    
    // We use serial queues to prevent race conditions when multiple threads try to read/modify the same file
    
    internal static let sendLogsToServerQueue: dispatch_queue_t = dispatch_queue_create("com.ibm.mobilefirstplatform.clientsdk.swift.BMSCore.Logger.sendLogsToServerQueue", DISPATCH_QUEUE_SERIAL)
    
    
    internal static let sendAnalyticsToServerQueue: dispatch_queue_t = dispatch_queue_create("com.ibm.mobilefirstplatform.clientsdk.swift.BMSCore.Logger.sendAnalyticsToServerQueue", DISPATCH_QUEUE_SERIAL)
    
    
    
    // MARK: Methods

    // Build the request completion handler, extract logs from file, and send logs to the server
    internal static func send(completionHandler userCallback: MfpCompletionHandler? = nil) {
        
        let logSendCallback: MfpCompletionHandler = { (response: Response?, error: NSError?) in
            
            if error == nil && response?.statusCode == 201 {
                Logger.internalLogger.debug("Client logs successfully sent to the server.")
                
                deleteFile(Constants.File.Logger.outboundLogs)
                // Remove the uncaught exception flag since the logs containing the exception(s) have just been sent to the server
                NSUserDefaults.standardUserDefaults().setBool(false, forKey: Constants.uncaughtException)
            }
            else {
                Logger.internalLogger.error("Request to send client logs has failed.")
            }
            
            userCallback?(response, error)
        }
        
        // Use a serial queue to ensure that the same logs do not get sent more than once
        dispatch_async(LogSender.sendLogsToServerQueue) { () -> Void in
            do {
                // Gather the logs and put them in a JSON object
                let logsToSend: String? = try getLogs(fileName: Constants.File.Logger.logs, overflowFileName: Constants.File.Logger.overflowLogs, bufferFileName: Constants.File.Logger.outboundLogs)
                var logPayloadData = try NSJSONSerialization.dataWithJSONObject([], options: [])
                if let logPayload = logsToSend {
                    let logPayloadJson = [Constants.outboundLogPayload: logPayload]
                    logPayloadData = try NSJSONSerialization.dataWithJSONObject(logPayloadJson, options: [])
                }
                else {
                    Logger.internalLogger.info("There are no logs to send.")
                }
                
                // Send the request, even if there are no logs to send (to keep track of device info)
                if let request: BaseRequest = buildLogSendRequest(logSendCallback) {
                    request.sendData(logPayloadData, withCompletionHandler: logSendCallback)
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
                
                deleteFile(Constants.File.Analytics.outboundLogs)
            }
            else {
                Analytics.logger.error("Request to send analytics data to the server has failed.")
            }
            
            userCallback?(response, error)
        }
        
        // Use a serial queue to ensure that the same analytics data do not get sent more than once
        dispatch_async(LogSender.sendAnalyticsToServerQueue) { () -> Void in
            do {
                // Gather the logs and put them in a JSON object
                let logsToSend: String? = try getLogs(fileName: Constants.File.Analytics.logs, overflowFileName: Constants.File.Analytics.overflowLogs, bufferFileName: Constants.File.Analytics.outboundLogs)
                var logPayloadData = try NSJSONSerialization.dataWithJSONObject([], options: [])
                if let logPayload = logsToSend {
                    let logPayloadJson = [Constants.outboundLogPayload: logPayload]
                    logPayloadData = try NSJSONSerialization.dataWithJSONObject(logPayloadJson, options: [])
                }
                else {
                    Analytics.logger.info("There are no analytics data to send.")
                }
                
                // Send the request, even if there are no logs to send (to keep track of device info)
                if let request: BaseRequest = buildLogSendRequest(analyticsSendCallback) {
                    request.sendData(logPayloadData, withCompletionHandler: analyticsSendCallback)
                }
            }
            catch let error as NSError {
                analyticsSendCallback(nil, error)
            }
        }
    }
    
    
    // Build the Request object that will be used to send the logs to the server
    internal static func buildLogSendRequest(callback: MfpCompletionHandler) -> BaseRequest? {
        
        let bmsClient = BMSClient.sharedInstance
        let mfpClient = MFPClient.sharedInstance
        var headers: [String: String] = [:]
        var logUploadUrl = ""
        
        // TODO: Consider sending request to both if user wants to send data to both Bluemix and an MFP server
        
        // Check that the BMSClient or MFPClient classes have been initialized before building the upload URL
        
        // Bluemix request
        // Only the region is required to communicate with the Analytics service. App route and GUID are not required.
        if bmsClient.bluemixRegion != nil && bmsClient.bluemixRegion != "" {
            guard Analytics.apiKey != nil && Analytics.apiKey != "" else {
                returnInitializationError("Analytics", missingValue: "apiKey", callback: callback)
                return nil
            }
            headers["Content-Type"] = "application/json"
            headers[Constants.analyticsApiKey] = Analytics.apiKey!
            
            logUploadUrl = "https://" + Constants.AnalyticsServer.Bluemix.hostName + "." + bmsClient.bluemixRegion! + Constants.AnalyticsServer.Bluemix.uploadPath
            
            // Request class is specific to Bluemix (since it uses Bluemix authorization managers)
            return Request(url: logUploadUrl, headers: headers, queryParameters: nil, method: HttpMethod.POST)
        }
        // MFP request
        else if let mfpProtocol = mfpClient.mfpProtocol, mfpHost = mfpClient.mfpHost, mfpPort = mfpClient.mfpPort {
            headers["Content-Type"] = "text/plain"
            
            logUploadUrl = mfpProtocol + "://" + mfpHost + ":" + mfpPort + Constants.AnalyticsServer.Foundation.uploadPath

            return BaseRequest(url: logUploadUrl, headers: headers, queryParameters: nil, method: HttpMethod.POST)
        }
        else {
            Logger.internalLogger.error("Failed to send logs because the client was not yet initialized. Make sure that either the BMSClient or the MFPClient class has been initialized.")
            return nil
        }
    }
    
    
    // If this is reached, the user most likely failed to initialize BMSClient or Analytics
    internal static func returnInitializationError(uninitializedClass: String, missingValue: String, callback: MfpCompletionHandler) {
        
        Logger.internalLogger.error("No value found for the \(uninitializedClass) \(missingValue) property.")
        let errorMessage = "Must initialize \(uninitializedClass) before sending logs to the server."
        
        var errorCode: Int
        switch uninitializedClass {
        case "Analytics":
            errorCode = BMSAnalyticsError.AnalyticsNotInitialized.rawValue
        case "BMSClient":
            errorCode = BMSCoreError.ClientNotInitialized.rawValue
        default:
            errorCode = -1
        }
        
        let error = NSError(domain: BMSAnalyticsError.domain, code: errorCode, userInfo: [NSLocalizedDescriptionKey: errorMessage])
        
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
                LogRecorder.writeToFile(logFile, logMessage: fileContents, loggerName: Logger.internalLogger.name)
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
        
        let analyticsOutboundLogs: String = Logger.logsDocumentPath + Constants.File.Analytics.outboundLogs
        let loggerOutboundLogs: String = Logger.logsDocumentPath + Constants.File.Logger.outboundLogs
        
        
        var fileContents: String?
        
        do {
            // Before sending the logs, we need to read them from the file. This is done in a serial dispatch queue to prevent conflicts if the log file is simulatenously being written to.
            switch bufferLogFile {
            case analyticsOutboundLogs:
                try dispatch_sync_throwable(LogRecorder.analyticsFileIOQueue, block: { () -> () in
                    fileContents = try NSString(contentsOfFile: bufferLogFile, encoding: NSUTF8StringEncoding) as String
                })
            case loggerOutboundLogs:
                try dispatch_sync_throwable(LogRecorder.loggerFileIOQueue, block: { () -> () in
                    fileContents = try NSString(contentsOfFile: bufferLogFile, encoding: NSUTF8StringEncoding) as String
                })
            default:
                Logger.internalLogger.error("Cannot send data to server. Unrecognized file: \(bufferLogFile).")
            }
        }
        
        return fileContents
    }
    
    
    // For deleting files where only the file name is supplied, not the full path
    internal static func deleteFile(fileName: String) {
        
        let pathToFile = Logger.logsDocumentPath + fileName
        
        if Logger.fileManager.fileExistsAtPath(pathToFile) && Logger.fileManager.isDeletableFileAtPath(pathToFile) {
            do {
                try Logger.fileManager.removeItemAtPath(pathToFile)
            }
            catch let error {
                Logger.internalLogger.error("Failed to delete log file \(fileName) after sending. Error: \(error)")
            }
        }
    }
    
}
