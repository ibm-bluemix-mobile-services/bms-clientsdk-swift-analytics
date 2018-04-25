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
import BMSAnalyticsAPI
import CoreLocation



// MARK: - Swift 3

#if swift(>=3.0)
    


/**
    Adds the `initialize` and `send` methods.
*/
public extension Analytics {
    
    
    internal static var automaticallyRecordUsers: Bool = true
    
    
    
    /**
        The required initializer for the `Analytics` class when communicating with a Mobile Analytics service.
     
        Here you can choose what data you want to have monitored by `Analytics`, including user identities, user location, app lifecycle events, and network requests.

        - Note: This method must be called after initializing `BMSClient` with `BMSClient.sharedInstance.initialize(bluemixRegion:)` from the `BMSCore` framework, and before calling `send(completionHandler:)` or `Logger.send(completionHandler:)`.

        - parameter appName:            The application name.  Should be consistent across platforms (i.e. Android and iOS).
        - parameter apiKey:             A unique ID used to authenticate with the Mobile Analytics service.
        - parameter hasUserContext:     If `false`, user identities will be automatically recorded using
                                            the device on which the app is installed. If you want to define user identities yourself using `Analytics.userIdentity`, set this parameter to `true`.
        - parameter collectLocation:    Determines whether Analytics should automatically monitor the user's
                                            current location. Before location can be retrieved, you must first request permission from the user with `CLLocationManager` `requestWhenInUseAuthorization()`.
        - parameter deviceEvents:       Device events that will be recorded automatically by the `Analytics` class.
    */
    public static func initialize(appName: String?, apiKey: String?, hasUserContext: Bool = false, collectLocation: Bool = false, deviceEvents: DeviceEvent...) {
        
        BMSAnalytics.appName = appName
        
        if apiKey != nil {
            BMSAnalytics.apiKey = apiKey
        }
        
        // Link the BMSAnalytics implementation to the APIs in BMSAnalyticsAPI
        Logger.delegate = BMSLogger()
        Analytics.delegate = BMSAnalytics()
        
        Analytics.automaticallyRecordUsers = !hasUserContext
        // If the developer does not want to specify the user identities themselves, we do it for them.
        if automaticallyRecordUsers {
            // We associate each unique device with one unique user. As such, all users will be anonymous.
            Analytics.userIdentity = BMSAnalytics.uniqueDeviceId
        }
        
        BMSAnalytics.locationEnabled = collectLocation
        
        // Registering device events
        for event in deviceEvents {
            switch event {
            case .lifecycle:
                #if os(iOS)
                    BMSAnalytics.startRecordingApplicationLifecycle()
                #else
                    Analytics.logger.warn(message: "The Analytics class cannot automatically record lifecycle events for non-iOS apps.")
                #endif
            case .network:
                BMSURLSession.shouldRecordNetworkMetadata = true
            }
        }
        
        BMSLogger.startCapturingUncaughtExceptions()
        
        // Package analytics metadata in a header for each request
        // Outbound request metadata is identical for all requests made on the same device from the same app
        if BMSClient.sharedInstance.bluemixRegion != nil {
            Request.requestAnalyticsData = BMSAnalytics.generateOutboundRequestMetadata()
        }
        else {
            Analytics.logger.warn(message: "Make sure that the BMSClient class has been initialized before calling the Analytics initializer.")
        }

        // Send Feedback data
        #if os(iOS)
            Feedback.send(fromSentButton: false)
        #endif
    }
    
    
    /**
        Log the user's current location once. 
     
        - important: Before calling this method, make sure that you have requested permission to use location services from the user (using `CLLocationManager` `requestWhenInUseAuthorization()`), and set the `collectLocation` parameter to `true` in the `Analytics.initialize(appName:apiKey:hasUserContext:collectLocation:deviceEvents:)` method.
    */
    public static func logLocation() {
        
        BMSAnalytics.logEvent(Constants.Metadata.Analytics.location)
    }
    
    
    /**
        Send the accumulated analytics logs to the Mobile Analytics service.

        Analytics logs can only be sent if the BMSClient was initialized with `BMSClient.sharedInstance.initialize(bluemixRegion:)` from the `BMSCore` framework.

        - parameter completionHandler:  Optional callback containing the results of the send request.
    */
    public static func send(completionHandler userCallback: BMSCompletionHandler? = nil) {
        
        Logger.sendAnalytics(completionHandler: userCallback)
    }

    /**
        Trigger feedback Mode

        Note: Feedback Mode can only be triggered if the BMSClient was initialized with `BMSClient.sharedInstance.initialize(bluemixRegion:)` from the `BMSCore` framework.
    */
    public static func triggerFeedbackMode() {
        #if os(iOS)
            Feedback.invokeFeedback()
        #else
            Analytics.logger.warn(message: "Feedback Mode cannot be invoked for non-iOS apps.")
        #endif
    }
}



// MARK: -

/*
    Provides the internal implementation of the `Logger` class in the BMSAnalyticsAPI framework.
*/
public class BMSAnalytics: AnalyticsDelegate {
    
    
    // MARK: Properties (public)
    
    // The name of the iOS/WatchOS app.
    public fileprivate(set) static var appName: String?
    
    // The unique ID used to send logs to the Mobile Analytics service.
    public fileprivate(set) static var apiKey: String?
    
    // Identifies the current application user.
    // To reset the userId, set the value to nil.
    public var userIdentity: String? {
        
        // Note: The developer sets this value via Analytics.userIdentity
        didSet {
            
            // userIdentity is being set by the SDK
            if userIdentity == BMSAnalytics.uniqueDeviceId {
                BMSAnalytics.logEvent(Constants.Metadata.Analytics.user)
            }
            // userIdentity is being set by the developer
            else {
                guard !Analytics.automaticallyRecordUsers else {
                    
                    Analytics.logger.error(message: "Before setting the userIdentity property, you must first set the hasUserContext parameter to true in the Analytics initializer.")
                    
                    userIdentity = BMSAnalytics.uniqueDeviceId
                    return
                }
                
                if BMSAnalytics.lifecycleEvents[Constants.Metadata.Analytics.sessionId] != nil {
                    
                    BMSAnalytics.logEvent(Constants.Metadata.Analytics.user)
                }
                else {
                    Analytics.logger.error(message: "To see active users in the analytics console, you must either opt in for DeviceEvents.LIFECYCLE in the Analytics initializer (for iOS apps) or first call Analytics.recordApplicationDidBecomeActive() before setting Analytics.userIdentity (for watchOS apps).")
                    
                    userIdentity = nil
                }
            }
        }
    }
    

    // MARK: Properties (internal)
    
    // Stores metadata (including a duration timer) for each app session
    // An app session is roughly defined as the time during which an app is being used (from becoming active to going inactive)
    internal static var lifecycleEvents: [String: Any] = [:]
    
    // The timestamp for when the current session started
    internal static var startTime: Int64 = 0
    
    internal static var sdkVersion: String {

        if let bundle = Bundle(identifier: "com.ibm.mobilefirstplatform.clientsdk.swift.BMSAnalytics") {
            return bundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? ""
        }
        return ""
    }
    
    // Allows the developer to choose whether we should record location information for their users
    internal static var locationEnabled = false
    
    // The manager and delegate that get the user's current location to log as metadata
    internal static var locationManager = CLLocationManager()
    internal static var locationDelegate = LocationDelegate()
    
    
    
    // MARK: - App sessions
    
    // Log that the app is starting a new session, and start a timer to record the session duration
    // This method should be called when the app starts up.
    //      In iOS, this occurs when the app is about to enter the foreground.
    //      In watchOS, the user decides when this method is executed, but we recommend calling it when the app becomes active.
    @objc dynamic static internal func logSessionStart() {
        
        // If this method is called before logSessionEnd() gets called, exit early so that the original startTime and metadata from the previous session start do not get discarded.
            
        guard lifecycleEvents.isEmpty else {
            Analytics.logger.info(message: "A new session is starting before previous session ended. Data for this new session will be discarded.")
            return
        }
        
        if CLLocationManager.locationServicesEnabled() && CLLocationManager.authorizationStatus() == CLAuthorizationStatus.notDetermined {
            self.locationManager.requestWhenInUseAuthorization()
        }
      
        BMSAnalytics.startTime = Int64(Date.timeIntervalSinceReferenceDate * 1000) // milliseconds
        
        lifecycleEvents[Constants.Metadata.Analytics.sessionId] = UUID().uuidString
        lifecycleEvents[Constants.Metadata.Analytics.category] = Constants.Metadata.Analytics.appSession
        
        Analytics.log(metadata: lifecycleEvents)
        
        BMSAnalytics.logEvent(Constants.Metadata.Analytics.initialContext)
    }
    
    
    // Log that the app session is ending, and use the timer from logSessionStart() to record the duration of this session
    // This method should be called when the app closes.
    //      In iOS, this occurs when the app enters the background.
    //      In watchOS, the user decides when this method is executed, but we recommend calling it when the app becomes active.
    @objc dynamic static internal func logSessionEnd() {
        
        // If logSessionStart() has not been called yet, the app session is ending before it starts.
        //      This may occur if the app crashes while launching. In this case, set the session duration to 0.
        var sessionDuration: Int64 = 0
        if !lifecycleEvents.isEmpty && BMSAnalytics.startTime > 0 {
            sessionDuration = Int64(NSDate.timeIntervalSinceReferenceDate * 1000) - BMSAnalytics.startTime
        }
        
        lifecycleEvents[Constants.Metadata.Analytics.category] = Constants.Metadata.Analytics.appSession
        
        lifecycleEvents[Constants.Metadata.Analytics.duration] = Int(sessionDuration)
        
        // Let the Analytics service know how the app was last closed
        if BMSLogger.exceptionHasBeenCalled {
            lifecycleEvents[Constants.Metadata.Analytics.closedBy] = AppClosedBy.crash.rawValue
            Logger.isUncaughtExceptionDetected = true
        }
        else {
            lifecycleEvents[Constants.Metadata.Analytics.closedBy] = AppClosedBy.user.rawValue
            Logger.isUncaughtExceptionDetected = false
        }
        
        Analytics.log(metadata: lifecycleEvents)
        lifecycleEvents = [:]
        BMSAnalytics.startTime = 0
    }
    
    
    // Remove the observers registered in the Analytics+iOS "startRecordingApplicationLifecycleEvents" method
    deinit {
        NotificationCenter.default.removeObserver(self)
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

        requestMetadata["brand"] = "Apple"
        requestMetadata["osVersion"] = osVersion
        requestMetadata["model"] = model
        requestMetadata["deviceID"] = deviceId
        requestMetadata["mfpAppName"] = BMSAnalytics.appName
        requestMetadata["appStoreLabel"] = Bundle.main.infoDictionary?["CFBundleName"] as? String ?? ""
        requestMetadata["appStoreId"] = Bundle.main.bundleIdentifier ?? ""
        requestMetadata["appVersionCode"] = Bundle.main.object(forInfoDictionaryKey: kCFBundleVersionKey as String) as? String ?? ""
        requestMetadata["appVersionDisplay"] = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? ""
        requestMetadata["sdkVersion"] = sdkVersion
        
        var requestMetadataString: String?

        do {
            let requestMetadataJson = try JSONSerialization.data(withJSONObject: requestMetadata, options: [])
            requestMetadataString = String(data: requestMetadataJson, encoding: .utf8)
        }
        catch let error {
            Analytics.logger.error(message: "Failed to append analytics metadata to request. Error: \(error)")
        }
        
        return requestMetadataString
    }
    
    

    // MARK: - Helpers
    
    // Used to log certain events like initial context (when the app enters foreground), switching users, and getting user location
    internal static func logEvent(_ category: String) {
        
        let currentTime = Int64(Date().timeIntervalSince1970 * 1000.0)
        
        var metadata: [String: Any] = [:]
        metadata[Constants.Metadata.Analytics.category] = category
        if category == Constants.Metadata.Analytics.user {
            metadata[Constants.Metadata.Analytics.userId] = Analytics.userIdentity
        }
        else {
            metadata[Constants.Metadata.Analytics.userId]=BMSAnalytics.uniqueDeviceId
        }
        
        metadata[Constants.Metadata.Analytics.sessionId] = BMSAnalytics.lifecycleEvents[Constants.Metadata.Analytics.sessionId]
        metadata[Constants.Metadata.Analytics.timestamp] = NSNumber(value: currentTime)
        
        // Get current location, add it to the metadata, and log
        if BMSAnalytics.locationEnabled {
            if CLLocationManager.locationServicesEnabled() &&
                (CLLocationManager.authorizationStatus() == CLAuthorizationStatus.authorizedWhenInUse ||
                    CLLocationManager.authorizationStatus() == CLAuthorizationStatus.authorizedAlways) {
                
                locationDelegate.analyticsMetadata = metadata
                locationManager.delegate = locationDelegate
                locationManager.desiredAccuracy = kCLLocationAccuracyKilometer
                
                
                if #available(iOS 9.0, *) {
                    locationManager.requestLocation()
                }
                else {
                    locationManager.startUpdatingLocation()
                }
            }
            else {
                Analytics.logger.warn(message: "The CLLocationManager authorization status must be authorizedWhenInUse before location data can be gathered.")
            }
        }
        else {
            Analytics.log(metadata: metadata)
        }
    }
    
    
    // Retrieve the unique device ID, or return "unknown" if it is unattainable.
    internal static func getDeviceId(from uniqueDeviceId: String?) -> String {
        
        if let id = uniqueDeviceId {
            return id
        }
        else {
            Analytics.logger.warn(message: "Cannot determine the unique ID for this device, so the recorded analytics data will not include it.")
            
            return "unknown"
        }
    }
}


// How the last app session ended
private enum AppClosedBy: String {
    
    case user = "USER"
    case crash = "CRASH"
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

    

    
    
/**************************************************************************************************/

    
    

    
// MARK: - Swift 2
    
#else



/**
    Adds the `initialize` and `send` methods.
*/
public extension Analytics {
    
    
    internal static var automaticallyRecordUsers: Bool = true
    
    
    
    /**
        The required initializer for the `Analytics` class when communicating with a Mobile Analytics service.
     
         Here you can choose what data you want to have monitored by `Analytics`, including user identities, user location, app lifecycle events, and network requests.

        - Note: This method must be called after the `BMSClient.sharedInstance.initialize(bluemixRegion:)` method and before calling `Analytics.send()` or `Logger.send()`.

        - parameter appName:            The application name.  Should be consistent across platforms (i.e. Android and iOS).
        - parameter apiKey:             A unique ID used to authenticate with the Mobile Analytics service.
        - parameter hasUserContext:     If `false`, user identities will be automatically recorded using
                                            the device on which the app is installed. If you want to define user identities yourself using `Analytics.userIdentity`, set this parameter to `true`.
        - parameter collectLocation:    Determines whether Analytics should automatically monitor the user's
                                             current location. Before location can be retrieved, you must first request permission from the user with `CLLocationManager` `requestWhenInUseAuthorization()`.
        - parameter deviceEvents:       Device events that will be recorded automatically by the `Analytics` class.
    */
    public static func initialize(appName appName: String?, apiKey: String?, hasUserContext: Bool = false, collectLocation: Bool = false, deviceEvents: DeviceEvent...) {
        
        BMSAnalytics.appName = appName
        
        if apiKey != nil {
            BMSAnalytics.apiKey = apiKey
        }
        
        // Link the BMSAnalytics implementation to the APIs in BMSAnalyticsAPI
        Logger.delegate = BMSLogger()
        Analytics.delegate = BMSAnalytics()
        
        Analytics.automaticallyRecordUsers = !hasUserContext
        // If the developer does not want to specify the user identities themselves, we do it for them.
        if automaticallyRecordUsers {
            // We associate each unique device with one unique user. As such, all users will be anonymous.
            Analytics.userIdentity = BMSAnalytics.uniqueDeviceId
        }
        
        BMSAnalytics.locationEnabled = collectLocation
        
        // Registering device events
        for event in deviceEvents {
            switch event {
            case .lifecycle:
                #if os(iOS)
                    BMSAnalytics.startRecordingApplicationLifecycle()
                #else
                    Analytics.logger.warn(message: "The Analytics class cannot automatically record lifecycle events for non-iOS apps.")
                #endif
            case .network:
                BMSURLSession.shouldRecordNetworkMetadata = true
            }
        }
        
        BMSLogger.startCapturingUncaughtExceptions()
        
        // Package analytics metadata in a header for each request
        // Outbound request metadata is identical for all requests made on the same device from the same app
        if BMSClient.sharedInstance.bluemixRegion != nil {
            Request.requestAnalyticsData = BMSAnalytics.generateOutboundRequestMetadata()
        }
        else {
            Analytics.logger.warn(message: "Make sure that the BMSClient class has been initialized before calling the Analytics initializer.")
        }
    }
    
    
    /**
        Log the user's current location once.
     
        - important: Before calling this method, make sure that you have requested permission to use location services from the user (using `CLLocationManager` `requestWhenInUseAuthorization()`), and set the `collectLocation` parameter to `true` in the `Analytics.initialize(appName:apiKey:hasUserContext:collectLocation:deviceEvents:)` method.
     */
    public static func logLocation() {
        
        BMSAnalytics.logEvent(Constants.Metadata.Analytics.location)
    }
    
    
    /**
         Send the accumulated analytics logs to the Mobile Analytics service.
     
         Analytics logs can only be sent if the BMSClient was initialized with `BMSClient.sharedInstance.initialize(bluemixRegion:)`.

        - parameter completionHandler:  Optional callback containing the results of the send request.
    */
    public static func send(completionHandler userCallback: BMSCompletionHandler? = nil) {
        
        Logger.sendAnalytics(completionHandler: userCallback)
    }
    
}



// MARK: -

/*
    Provides the internal implementation of the `Analytics` class in the BMSAnalyticsAPI framework.
*/
public class BMSAnalytics: AnalyticsDelegate {
    
    
    // MARK: Properties (public)
    
    // The name of the iOS/WatchOS app.
    public private(set) static var appName: String?
    
    // The unique ID used to send logs to the Mobile Analytics service.
    public private(set) static var apiKey: String?
    
    // Identifies the current application user.
    // To reset the userId, set the value to nil.
    public var userIdentity: String? {
        
        // Note: The developer sets this value via Analytics.userIdentity
        didSet {
            
            // userIdentity is being set by the SDK
            if userIdentity == BMSAnalytics.uniqueDeviceId {
                BMSAnalytics.logEvent(Constants.Metadata.Analytics.user)
            }
            // userIdentity is being set by the developer
            else {
                guard !Analytics.automaticallyRecordUsers else {
                    
                    Analytics.logger.error(message: "Before setting the userIdentity property, you must first set the hasUserContext parameter to true in the Analytics initializer.")
                    
                    userIdentity = BMSAnalytics.uniqueDeviceId
                    return
                }
                
                if BMSAnalytics.lifecycleEvents[Constants.Metadata.Analytics.sessionId] != nil {
                    
                    BMSAnalytics.logEvent(Constants.Metadata.Analytics.user)
                }
                else {
                    Analytics.logger.error(message: "To see active users in the analytics console, you must either opt in for DeviceEvents.LIFECYCLE in the Analytics initializer (for iOS apps) or first call Analytics.recordApplicationDidBecomeActive() before setting Analytics.userIdentity (for watchOS apps).")
                    
                    userIdentity = nil
                }
            }
        }
    }
    
    
    // MARK: Properties (internal)
    
    // Stores metadata (including a duration timer) for each app session
    // An app session is roughly defined as the time during which an app is being used (from becoming active to going inactive)
    internal static var lifecycleEvents: [String: AnyObject] = [:]
    
    // The timestamp for when the current session started
    internal static var startTime: Int64 = 0
    
    internal static var sdkVersion: String {
        if let bundle = NSBundle(identifier: "com.ibm.mobilefirstplatform.clientsdk.swift.BMSAnalytics") {
            return bundle.objectForInfoDictionaryKey("CFBundleShortVersionString") as? String ?? ""
        }
        
        return ""
    }
    
    // Allows the developer to choose whether we should record location information for their users
    internal static var locationEnabled = false
    
    // The manager and delegate that get the user's current location to log as metadata
    internal static var locationManager = CLLocationManager()
    internal static var locationDelegate = LocationDelegate()
    
    
    
    // MARK: - App sessions
    
    // Log that the app is starting a new session, and start a timer to record the session duration
    // This method should be called when the app starts up.
    //      In iOS, this occurs when the app is about to enter the foreground.
    //      In watchOS, the user decides when this method is executed, but we recommend calling it when the app becomes active.
    dynamic static internal func logSessionStart() {
        
        // If this method is called before logSessionEnd() gets called, exit early so that the original startTime and metadata from the previous session start do not get discarded.
        guard lifecycleEvents.isEmpty else {
            Analytics.logger.info(message: "A new session is starting before previous session ended. Data for this new session will be discarded.")
            return
        }
            
        BMSAnalytics.startTime = Int64(NSDate.timeIntervalSinceReferenceDate() * 1000) // milliseconds
        
        lifecycleEvents[Constants.Metadata.Analytics.sessionId] = NSUUID().UUIDString
        lifecycleEvents[Constants.Metadata.Analytics.category] = Constants.Metadata.Analytics.appSession
        
        Analytics.log(metadata: lifecycleEvents)
        
        BMSAnalytics.logEvent(Constants.Metadata.Analytics.initialContext)
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
            lifecycleEvents[Constants.Metadata.Analytics.closedBy] = AppClosedBy.crash.rawValue
            Logger.isUncaughtExceptionDetected = true
        }
        else {
            lifecycleEvents[Constants.Metadata.Analytics.closedBy] = AppClosedBy.user.rawValue
            Logger.isUncaughtExceptionDetected = false
        }
        
        Analytics.log(metadata: lifecycleEvents)
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
        
        requestMetadata["brand"] = "Apple"
        requestMetadata["osVersion"] = osVersion
        requestMetadata["model"] = model
        requestMetadata["deviceID"] = deviceId
        requestMetadata["mfpAppName"] = BMSAnalytics.appName
        requestMetadata["appStoreLabel"] = NSBundle.mainBundle().infoDictionary?["CFBundleName"] as? String ?? ""
        requestMetadata["appStoreId"] = NSBundle.mainBundle().bundleIdentifier ?? ""
        requestMetadata["appVersionCode"] = NSBundle.mainBundle().objectForInfoDictionaryKey(kCFBundleVersionKey as String) as? String ?? ""
        requestMetadata["appVersionDisplay"] = NSBundle.mainBundle().objectForInfoDictionaryKey("CFBundleShortVersionString") as? String ?? ""
        requestMetadata["sdkVersion"] = sdkVersion
        
        var requestMetadataString: String?
        
        do {
            let requestMetadataJson = try NSJSONSerialization.dataWithJSONObject(requestMetadata, options: [])
            requestMetadataString = String(data: requestMetadataJson, encoding: NSUTF8StringEncoding)
        }
        catch let error {
            Analytics.logger.error(message: "Failed to append analytics metadata to request. Error: \(error)")
        }
        
        return requestMetadataString
    }
    
    
    
    // MARK: - Helpers
    
    // Used to log certain events like initial context (when the app enters foreground), switching users, and getting user location
    internal static func logEvent(category: String) {
        
        let currentTime = Int64(NSDate().timeIntervalSince1970 * 1000.0)
        
        var metadata: [String: AnyObject] = [:]
        metadata[Constants.Metadata.Analytics.category] = category
        metadata[Constants.Metadata.Analytics.userId] = Analytics.userIdentity
        metadata[Constants.Metadata.Analytics.sessionId] = BMSAnalytics.lifecycleEvents[Constants.Metadata.Analytics.sessionId]
        metadata[Constants.Metadata.Analytics.timestamp] = NSNumber(longLong: currentTime)
        
        // Get current location, add it to the metadata, and log
        if BMSAnalytics.locationEnabled {
            if CLLocationManager.locationServicesEnabled() &&
                (CLLocationManager.authorizationStatus() == CLAuthorizationStatus.AuthorizedWhenInUse ||
                    CLLocationManager.authorizationStatus() == CLAuthorizationStatus.AuthorizedAlways) {
                
                locationDelegate.analyticsMetadata = metadata
                locationManager.delegate = locationDelegate
                locationManager.desiredAccuracy = kCLLocationAccuracyKilometer
                
                
                if #available(iOS 9.0, *) {
                    locationManager.requestLocation()
                }
                else {
                    // startUpdatingLocation() does not exist until watchOS 3.0, so it will not compile in Xcode 7, which only has the watchOS 2 SDK.
                    #if os(iOS)
                        locationManager.startUpdatingLocation()
                    #endif
                }
            }
            else {
                Analytics.logger.warn(message: "The CLLocationManager authorization status must be authorizedWhenInUse before location data can be gathered.")
            }
        }
        else {
            Analytics.log(metadata: metadata)
        }
    }

    
    // Retrieve the unique device ID, or return "unknown" if it is unattainable.
    internal static func getDeviceId(from uniqueDeviceId: String?) -> String {
        
        if let id = uniqueDeviceId {
            return id
        }
        else {
            Analytics.logger.warn(message: "Cannot determine the unique ID for this device, so the recorded analytics data will not include it.")
            
            return "unknown"
        }
    }
}



// How the last app session ended
private enum AppClosedBy: String {
    
    case user = "USER"
    case crash = "CRASH"
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

   
    
#endif
