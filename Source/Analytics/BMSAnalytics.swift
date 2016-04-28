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


// Initializer and send methods
public extension Analytics {
    
    /**
         The required initializer for the `Analytics` class when communicating with a Bluemix analytics service.
         
         This method must be called after the `BMSClient.initializeWithBluemixAppRoute()` method and before calling `Analytics.send()` or `Logger.send()`.
         
         - parameter appName:        The application name.  Should be consistent across platforms (e.g. Android and iOS).
         - parameter apiKey:         A unique ID used to authenticate with the Bluemix analytics service
         - parameter deviceEvents:   Device events that will be recorded automatically by the `Analytics` class
     */
    public static func initializeWithAppName(appName: String?, apiKey: String?, deviceEvents: DeviceEvent...) {
        
        BMSAnalytics.appName = appName
        
        if apiKey != nil {
            BMSAnalytics.apiKey = apiKey
        }
        
        // Link all of the BMSAnalytics implementation to the BMSAnalyticsSpec APIs
        Logger.delegate = BMSLogger()
        Analytics.delegate = BMSAnalytics()
        
        BMSLogger.startCapturingUncaughtExceptions()
        
        // Registering device events
        for event in deviceEvents {
            switch event {
            case .LIFECYCLE:
                #if os(iOS)
                    BMSAnalytics.startRecordingApplicationLifecycle()
                #else
                    Analytics.logger.warn("The Analytics class cannot automatically record lifecycle events for non-iOS apps.")
                #endif
            }
        }
        
        // This is required for active user data to appear on the Analytics console even if the developer does not specify the user. userIdentity will be converted to the device ID.
        Analytics.userIdentity = nil
        
        // Package analytics metadata in a header for each request
        // Outbound request metadata is identical for all requests made on the same device from the same app
        if BMSClient.sharedInstance.bluemixRegion != nil {
            Request.requestAnalyticsData = BMSAnalytics.generateOutboundRequestMetadata()
        }
        else {
            Analytics.logger.warn("Make sure that the BMSClient class has been initialized before calling the Analytics initializer.")
        }
    }
    
    
    /**
         Send the accumulated analytics logs to the Bluemix server.
         
         Analytics logs can only be sent if the BMSClient was initialized via the `initializeWithBluemixAppRoute()` method.
         
         - parameter completionHandler:  Optional callback containing the results of the send request
     */
    public static func send(completionHandler userCallback: BmsCompletionHandler? = nil) {
        
        Logger.sendAnalytics(completionHandler: userCallback)
    }
    
}



// MARK: -

/**
    `BMSAnalytics` provides the internal implementation of the BMSAnalyticsSpec `Analytics` API.
*/
public class BMSAnalytics: AnalyticsDelegate {
    
    
    // MARK: Properties (API)
    
    /// The name of the iOS/WatchOS app
    public private(set) static var appName: String?
    
    /// The unique ID used to send logs to the Analytics server
    public private(set) static var apiKey: String?
    
    /// Identifies the current application user.
    /// To reset the userId, set the value to nil.
    public var userIdentity: String? {
        
        // Note: The developer sets this value via Analytics.userIdentity
        didSet {
            
            // If the user sets to nil, change the value back to the deviceId so that we can continue recording unique users by the device they are using
            if userIdentity == nil {
                userIdentity = BMSAnalytics.uniqueDeviceId
            }
            
            if let sessionId = BMSAnalytics.lifecycleEvents[Constants.Metadata.Analytics.sessionId] {
                
                let currentTime = Int64(NSDate().timeIntervalSince1970 * 1000.0)
                
                var userIdMetadata: [String: AnyObject] = [:]
                userIdMetadata[Constants.Metadata.Analytics.sessionId] = sessionId
                userIdMetadata[Constants.Metadata.Analytics.timestamp] = NSNumber(longLong: currentTime)
                userIdMetadata[Constants.Metadata.Analytics.userId] = userIdentity
                userIdMetadata[Constants.Metadata.Analytics.category] = Constants.Metadata.Analytics.user
                
                Analytics.log(userIdMetadata)
            }
            else if userIdentity != BMSAnalytics.uniqueDeviceId {
                Analytics.logger.warn("To see active users in the analytics console, you must either opt in for DeviceEvents.LIFECYCLE in the Analytics initializer (for iOS apps) or first call Analytics.recordApplicationDidBecomeActive() before setting Analytics.userIdentity (for watchOS apps).")
                userIdentity = BMSAnalytics.uniqueDeviceId
            }
        }
    }
    
    

    // MARK: Properties (internal)
    
    // Stores metadata (including a duration timer) for each app session
    // An app session is roughly defined as the time during which an app is being used (from becoming active to going inactive)
    internal static var lifecycleEvents: [String: AnyObject] = [:]
    
    // Create a UUID for the current device and save it to the keychain
    // Currently only used for Apple Watch devices
    internal static var uniqueDeviceId: String {
        // First, check if a UUID was already created
        let bmsUserDefaults = NSUserDefaults(suiteName: Constants.userDefaultsSuiteName)
        guard bmsUserDefaults != nil else {
            Analytics.logger.error("Failed to get an ID for this device.")
            return ""
        }
        
        var deviceId = bmsUserDefaults!.stringForKey(Constants.Metadata.Analytics.deviceId)
        if deviceId == nil {
            deviceId = NSUUID().UUIDString
            bmsUserDefaults!.setValue(deviceId, forKey: Constants.Metadata.Analytics.deviceId)
        }
        return deviceId!
    }
    
    // The timestamp for when the current session started
    internal static var startTime: Int64 = 0
    
    // This property only exists to provide a default value for Analytics.userId
    internal static var deviceId: String = ""
    
    
    
    // MARK: - App sessions
    
    // Log that the app is starting a new session, and start a timer to record the session duration
    // This method should be called when the app starts up.
    //      In iOS, this occurs when the app is about to enter the foreground.
    //      In watchOS, the user decides when this method is executed, but we recommend calling it when the app becomes active.
    dynamic static internal func logSessionStart() {
        
        // If this method is called before logSessionEnd() gets called, exit early so that the original startTime and metadata from the previous session start do not get discarded.
        guard lifecycleEvents.isEmpty else {
            Analytics.logger.info("A new session is starting before previous session ended. Data for this new session will be discarded.")
            return
        }
        
        BMSAnalytics.startTime = Int64(NSDate.timeIntervalSinceReferenceDate() * 1000) // milliseconds
        lifecycleEvents[Constants.Metadata.Analytics.sessionId] = NSUUID().UUIDString
    }
    
    
    // Log that the app session is ending, and use the timer from logSessionStart() to record the duration of this session
    // This method should be called when the app closes.
    //      In iOS, this occurs when the app enters the background.
    //      In watchOS, the user decides when this method is executed, but we recommend calling it when the app becomes active.
    dynamic static internal func logSessionEnd() {
        
        // If logSessionStart() has not been called yet, the app session is ending before it starts.
        //      This may occur if the app crashes while launching. In this case, set the session duration to 0.
        var sessionDuration: Int64 = 0
        if !lifecycleEvents.isEmpty && BMSAnalytics.startTime > 0 {
            sessionDuration = Int64(NSDate.timeIntervalSinceReferenceDate() * 1000) - BMSAnalytics.startTime
        }
        
        lifecycleEvents[Constants.Metadata.Analytics.category] = Constants.Metadata.Analytics.appSession
        
        lifecycleEvents[Constants.Metadata.Analytics.duration] = Int(sessionDuration)
        
        // Let the Analytics service know how the app was last closed
        if BMSLogger.exceptionHasBeenCalled {
            lifecycleEvents[Constants.Metadata.Analytics.closedBy] = AppClosedBy.CRASH.rawValue
            Logger.isUncaughtExceptionDetected = true
        }
        else {
            lifecycleEvents[Constants.Metadata.Analytics.closedBy] = AppClosedBy.USER.rawValue
            Logger.isUncaughtExceptionDetected = false
        }
        
        Analytics.log(lifecycleEvents)
        
        lifecycleEvents = [:]
        BMSAnalytics.startTime = 0
    }
    
    
    // Remove the observers registered in the Analytics+iOS "startRecordingApplicationLifecycleEvents" method
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    
    
    // MARK: - Request analytics
    
    // Create a JSON string containing device/app data for the Analytics server to use
    // This data gets added to a Request header
    internal static func generateOutboundRequestMetadata() -> String? {
        
        // All of this data will go in a header for the request
        var requestMetadata: [String: String] = [:]
        
        // Device info
        var osVersion = "", model = "", deviceId = ""
        
        #if os(iOS)
            (osVersion, model, deviceId) = BMSAnalytics.getiOSDeviceInfo()
            requestMetadata["os"] = "iOS"
        #elseif os(watchOS)
            (osVersion, model, deviceId) = BMSAnalytics.getWatchOSDeviceInfo()
            requestMetadata["os"] = "watchOS"
        #endif
        
        // deviceId is the default value for Analytics.userId
        BMSAnalytics.deviceId = deviceId

        requestMetadata["brand"] = "Apple"
        requestMetadata["osVersion"] = osVersion
        requestMetadata["model"] = model
        requestMetadata["deviceID"] = deviceId
        requestMetadata["mfpAppName"] = BMSAnalytics.appName
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
    internal static func generateInboundResponseMetadata(request: Request, response: Response, url: String) -> [String: AnyObject] {
        
        Analytics.logger.debug("Network response inbound")
        
        let endTime = NSDate.timeIntervalSinceReferenceDate()
        let roundTripTime = (endTime - request.startTime) * 1000 // Converting to milliseconds
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



// MARK: -

// For unit testing only
internal extension BMSAnalytics {
    
    internal static func uninitialize() {
        Analytics.delegate = nil
        BMSAnalytics.apiKey = nil
        BMSAnalytics.appName = nil
        NSSetUncaughtExceptionHandler(nil)
    }
}
