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


/**
    Set of device events that the `Analytics` class will listen for. Whenever an event of the specified type occurs, analytics data for that event get recorded.
 
    - Note: Register DeviceEvents in the `Analytics.initializeWithAppName()` method
*/
public enum DeviceEvent {
    
    /// Records the duration of the app's lifecycle from when it enters the foreground to when it goes to the background.
    /// - Note: Only available for iOS apps. For watchOS apps, manually call the `recordApplicationDidBecomeActive()` and `recordApplicationWillResignActive()` methods in the appropriate `ExtensionDelegate` methods.
    case LIFECYCLE
}


/**
    `Analytics` provides a means of capturing analytics data and sending the data to the mobile analytics service.
*/
public class Analytics {
    
    
    // MARK: Properties (public)
    
    /// Determines whether analytics logs will be persisted to file.
    public static var enabled: Bool = true
    
    /// The unique ID used to send logs to the Analytics server
    public private(set) static var apiKey: String?
    
    /// The name of the iOS/WatchOS app
    public private(set) static var appName: String?
    
    

    // MARK: Properties (internal/private)

    internal static let logger = Logger.getLoggerForName(Constants.Package.analytics)
    
    // Stores metadata (including a duration timer) for each app session
    // An app session is roughly defined as the time during which an app is being used (from becoming active to going inactive)
    internal static var lifecycleEvents: [String: AnyObject] = [:]
    
    // Create a UUID for the current device and save it to the keychain
    // Currently only used for Apple Watch devices
    internal static var uniqueDeviceId: String {
        // First, check if a UUID was already created
        let mfpUserDefaults = NSUserDefaults(suiteName: Constants.userDefaultsSuiteName)
        guard mfpUserDefaults != nil else {
            Analytics.logger.error("Failed to get an ID for this device.")
            return ""
        }
        
        var deviceId = mfpUserDefaults!.stringForKey(Constants.Metadata.Analytics.deviceId)
        if deviceId == nil {
            deviceId = NSUUID().UUIDString
            mfpUserDefaults!.setValue(deviceId, forKey: Constants.Metadata.Analytics.deviceId)
        }
        return deviceId!
    }
    
    internal static var startTime: Int64 = 0
    
    
    
    // MARK: Methods (public)
    
    /**
        The required initializer for the `Analytics` class.
        
        This method must be called before sending `Analytics` or `Logger` logs.
        
        - parameter appName:        The application name.  Should be consistent across platforms (e.g. Android and iOS).
        - parameter apiKey:         A unique ID used to authenticate with the MFP analytics server
        - parameter deviceEvents:   Device events that will be recorded automatically by the `Analytics` class
    */
    public static func initializeWithAppName(appName: String, apiKey: String, deviceEvents: DeviceEvent...) {

        // Any required properties here should be checked for initialization in the private initializer
        if !appName.isEmpty {
            Analytics.appName = appName
        }
        if !apiKey.isEmpty {
            Analytics.apiKey = apiKey
        }
        
        // Register the LogRecorder so that logs can start being stored on the device
        Logger.logRecorder = LogRecorder()
        
        Logger.startCapturingUncaughtExceptions()
        
        // Registering device events
        for event in deviceEvents {
            switch event {
            case .LIFECYCLE:
                #if os(iOS)
                    Analytics.startRecordingApplicationLifecycle()
                #else
                    Analytics.logger.info("The Analytics class cannot automatically record lifecycle events for non-iOS apps.")
                #endif
            }
        }
        
        // Package analytics metadata in a header for each request
        // Outbound request metadata is identical for all requests made on the same device from the same app
        MFPRequest.requestAnalyticsData = Analytics.generateOutboundRequestMetadata()
    }
    
    
    /**
        Write analytics data to file. 
    
        Similar to the `Logger` class logging methods, old logs will be removed if the file size exceeds the `Logger.maxLogStoreSize` property.
    
        When ready, use the `Analytics.send()` method to send the logs to the Bluemix server.
    
         - parameter metadata:  The analytics data
    */
    public static func log(metadata: [String: AnyObject]) {
        
        logger.analytics(metadata)
    }
    
    
    /**
        Send the accumulated analytics logs to the Bluemix server.
    
        Analytics logs can only be sent if the BMSClient was initialized via the `initializeWithBluemixAppRoute()` method.
        
        - parameter completionHandler:  Optional callback containing the results of the send request
    */
    public static func send(completionHandler userCallback: MfpCompletionHandler? = nil) {
        
        LogSender.sendAnalytics(completionHandler: userCallback)
    }
    
    
    
    // MARK: Sessions
    
    // Log that the app is starting a new session, and start a timer to record the session duration
    // This method should be called when the app starts up.
    //      In iOS, this occurs when the app is about to enter the foreground.
    //      In watchOS, the user decides when this method is executed, but we recommend calling it when the app becomes active.
    dynamic static internal func logSessionStart() {
        
        // If this method is called before logSessionEnd() gets called, exit early so that the original startTime and metadata from the previous session start do not get discarded.
        guard lifecycleEvents.isEmpty else {
            logger.info("A new session is starting before previous session ended. Data for this new session will be discarded.")
            return
        }
        
        Analytics.startTime = Int64(NSDate.timeIntervalSinceReferenceDate() * 1000) // milliseconds
    }
    
    
    // Log that the app session is ending, and use the timer from logSessionStart() to record the duration of this session
    // This method should be called when the app closes.
    //      In iOS, this occurs when the app enters the background.
    //      In watchOS, the user decides when this method is executed, but we recommend calling it when the app becomes active.
    dynamic static internal func logSessionEnd() {
        
        // If logSessionStart() has not been called yet, the app session is ending before it starts.
        //      This may occur if the app crashes while launching. In this case, set the session duration to 0.
        var sessionDuration: Int64 = 0
        if !lifecycleEvents.isEmpty && Analytics.startTime > 0 {
            sessionDuration = Int64(NSDate.timeIntervalSinceReferenceDate() * 1000) - Analytics.startTime
        }
        
        lifecycleEvents[Constants.Metadata.Analytics.category] = Constants.Metadata.Analytics.appSession
        lifecycleEvents[Constants.Metadata.Analytics.sessionId] = NSUUID().UUIDString
        
        lifecycleEvents[Constants.Metadata.Analytics.duration] = Int(sessionDuration)
        
        // Let the Analytics service know how the app was last closed
        if Logger.exceptionHasBeenCalled {
            lifecycleEvents[Constants.Metadata.Analytics.closedBy] = AppClosedBy.CRASH.rawValue
            Logger.isUncaughtExceptionDetected = true
        }
        else {
            lifecycleEvents[Constants.Metadata.Analytics.closedBy] = AppClosedBy.USER.rawValue
            Logger.isUncaughtExceptionDetected = false
        }
        
        logger.analytics(lifecycleEvents)
        
        lifecycleEvents = [:]
        Analytics.startTime = 0
    }
    
    
    // Remove the observers registered in the Analytics+iOS "startRecordingApplicationLifecycleEvents" method
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    
    
    // MARK: Request analytics
    
    // Create a JSON string containing device/app data for the Analytics server to use
    // This data gets added to a Request header
    internal static func generateOutboundRequestMetadata() -> String? {
        
        // All of this data will go in a header for the request
        var requestMetadata: [String: String] = [:]
        
        // Device info
        var osVersion = "", model = "", deviceId = ""
        
        #if os(iOS)
            (osVersion, model, deviceId) = Analytics.getiOSDeviceInfo()
            requestMetadata["os"] = "iOS"
        #elseif os(watchOS)
            (osVersion, model, deviceId) = Analytics.getWatchOSDeviceInfo()
            requestMetadata["os"] = "watchOS"
        #endif

        requestMetadata["brand"] = "Apple"
        requestMetadata["osVersion"] = osVersion
        requestMetadata["model"] = model
        requestMetadata["deviceID"] = deviceId
        requestMetadata["mfpAppName"] = Analytics.appName
        requestMetadata["appStoreLabel"] = NSBundle.mainBundle().infoDictionary?["CFBundleName"] as? String ?? ""
        requestMetadata["appStoreId"] = NSBundle.mainBundle().bundleIdentifier ?? ""
        requestMetadata["appVersionCode"] = NSBundle.mainBundle().objectForInfoDictionaryKey(kCFBundleVersionKey as String) as? String ?? ""
        requestMetadata["appVersionDisplay"] = NSBundle.mainBundle().objectForInfoDictionaryKey("CFBundleShortVersionString") as? String ?? ""
        
        var requestMetadataString: String?
        do {
            let requestMetadataJson = try NSJSONSerialization.dataWithJSONObject(requestMetadata, options: [])
            requestMetadataString = String(data: requestMetadataJson, encoding: NSUTF8StringEncoding)
        }
        catch let error {
            Analytics.logger.error("Failed to append analytics metadata to request. Error: \(error)")
        }
        
        return requestMetadataString
    }
    
    
    // Gather response data as JSON to be recorded in an analytics log
    internal static func generateInboundResponseMetadata(request: MFPRequest, response: Response, url: String) -> [String: AnyObject] {
        
        Analytics.logger.debug("Network response inbound")
        
        let endTime = NSDate.timeIntervalSinceReferenceDate()
        let roundTripTime = endTime - request.startTime
        let bytesSent = request.requestBody?.length ?? 0
        
        // Data for analytics logging
        var responseMetadata: [String: AnyObject] = [:]
        
        responseMetadata["$category"] = "network"
        responseMetadata["$path"] = url
        responseMetadata["$trackingId"] = request.trackingId
        responseMetadata["$outboundTimestamp"] = request.startTime
        responseMetadata["$inboundTimestamp"] = endTime
        responseMetadata["$roundTripTime"] = roundTripTime
        responseMetadata["$responseCode"] = response.statusCode
        responseMetadata["$bytesSent"] = bytesSent
        
        if (response.responseText != nil && !response.responseText!.isEmpty) {
            responseMetadata["$bytesReceived"] = response.responseText?.lengthOfBytesUsingEncoding(NSUTF8StringEncoding)
        }
        
        return responseMetadata
    }
    
}


// How the last app session ended
private enum AppClosedBy: String {
    
    case USER
    case CRASH
}


// For unit testing only
internal extension Analytics {
    
    internal static func uninitialize() {
        Analytics.apiKey = nil
        Analytics.appName = nil
        NSSetUncaughtExceptionHandler(nil)
    }
}
