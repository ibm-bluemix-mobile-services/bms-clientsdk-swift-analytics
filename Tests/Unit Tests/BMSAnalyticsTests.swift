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


import XCTest
import BMSCore
@testable import BMSAnalytics



// MARK: - Swift 3

#if swift(>=3.0)


    
class BMSAnalyticsTests: XCTestCase {
    
    
    override func tearDown() {
        BMSAnalytics.lifecycleEvents = [:]
        BMSAnalytics.startTime = 0
        BMSAnalytics.uninitialize()
        
        Request.requestAnalyticsData = nil
    }
    

    func testInitialize() {
     
        XCTAssertNil(BMSAnalytics.apiKey)
        XCTAssertNil(BMSAnalytics.appName)
        
        Analytics.initialize(appName: "Unit Test App", apiKey: "1234")
        XCTAssertEqual(BMSAnalytics.apiKey, "1234")
        XCTAssertEqual(BMSAnalytics.appName, "Unit Test App")
    }
    
    
    func testInitializeWithBmsClientInitialized() {
        
        XCTAssertNil(BMSAnalytics.apiKey)
        XCTAssertNil(BMSAnalytics.appName)
        XCTAssertNil(Request.requestAnalyticsData)
        
        BMSClient.sharedInstance.initialize(bluemixAppRoute: "http://example.com", bluemixAppGUID: "1234", bluemixRegion: BMSClient.Region.usSouth)
        Analytics.initialize(appName: "Unit Test App", apiKey: "1234")
        
        XCTAssertEqual(BMSAnalytics.apiKey, "1234")
        XCTAssertEqual(BMSAnalytics.appName, "Unit Test App")
        XCTAssertNotNil(Request.requestAnalyticsData)
    }
    
    
    func testInitializeRegistersUncaughtExceptionHandler() {
        
        Analytics.initialize(appName: "Unit Test App", apiKey: "1234")
        XCTAssertNotNil(NSGetUncaughtExceptionHandler())
    }
    
    
    func testInitializeWithDeviceEvents() {
        
        let referenceTime = Int64(NSDate.timeIntervalSinceReferenceDate * 1000)
        
        Analytics.initialize(appName: "Unit Test App", apiKey: "1234", deviceEvents: DeviceEvent.lifecycle, DeviceEvent.network)
        
        // When registering LIFECYCLE events, the BMSAnalytics.logSessionStart() method should get called immediately, assigning a new value to BMSAnalytics.startTime and BMSAnalytics.lifecycleEvents
        XCTAssertTrue(BMSAnalytics.startTime >= referenceTime)
        XCTAssertTrue(BMSURLSession.shouldRecordNetworkMetadata)
    }
    

    func testLogSessionStartTwiceDoesNothing() {
        
        XCTAssertTrue(BMSAnalytics.lifecycleEvents.isEmpty)
        XCTAssertEqual(BMSAnalytics.startTime, 0)
        
        BMSAnalytics.logSessionStart()
        
        let firstSessionStartTime = BMSAnalytics.startTime
        XCTAssert(firstSessionStartTime > 0)
        
        let newSessionExpectation = expectation(description: "New session start time")
        
        // Even after waiting 1 second, the session start time should not change; the original session data should be preserved
        let timeDelay = DispatchTime.now() + 1
        DispatchQueue.main.asyncAfter(deadline: timeDelay) {
            newSessionExpectation.fulfill()
        }

        waitForExpectations(timeout: 10.0) { (error: Error?) -> Void in
            BMSAnalytics.logSessionStart()
            let secondSessionStartTime = BMSAnalytics.startTime
            
            XCTAssertTrue(secondSessionStartTime == firstSessionStartTime)
        }
    }
    
    
    /**
        1) Call logSessionStart(), which should update BMSAnalytics.lifecycleEvents.
        2) Call logSessionEnd(). This should reset BMSAnalytics.lifecycleEvents by removing the session ID.
        3) Call logSessionStart() again. This should cause BMSAnalytics.lifecycleEvents to be updated:
            - The original start time should be replaced with the new start time.
            - The session (TAG_CATEGORY_APP_SESSION) is a unique ID that should contain a different value each time logSessionStart()
                is called.
     */
    func testLogSessionAfterCompleteSession() {
        
        XCTAssertTrue(BMSAnalytics.lifecycleEvents.isEmpty)
        XCTAssertEqual(BMSAnalytics.startTime, 0)
        
        BMSAnalytics.logSessionStart()
        
        let firstSessionStartTime = BMSAnalytics.startTime
        
        BMSAnalytics.logSessionEnd()
        
        XCTAssertTrue(BMSAnalytics.lifecycleEvents.isEmpty)
        XCTAssertEqual(BMSAnalytics.startTime, 0)
        
        let newSessionExpectation = expectation(description: "New session start time")
        
        // Need a little time delay so that the first and second sessions don't have the same start time
        let timeDelay = DispatchTime.now() + 1
        DispatchQueue.main.asyncAfter(deadline: timeDelay) {
            newSessionExpectation.fulfill()
        }
        
        waitForExpectations(timeout: 10.0) { (error: Error?) -> Void in
            BMSAnalytics.logSessionStart()
            let secondSessionStartTime = BMSAnalytics.startTime
            
            XCTAssertTrue(secondSessionStartTime > firstSessionStartTime)
        }
    }
    
    
    /**
        1) Call logSessionEnd(). This should have no effect since logSessionStart() was never called.
        2) Call logSessionStart().
     */
    func testLogSessionEndBeforeLogSessionStart() {
        
        XCTAssertTrue(BMSAnalytics.lifecycleEvents.isEmpty)
        XCTAssertEqual(BMSAnalytics.startTime, 0)
        
        BMSAnalytics.logSessionEnd()
        
        XCTAssertTrue(BMSAnalytics.lifecycleEvents.isEmpty)
        XCTAssertEqual(BMSAnalytics.startTime, 0)
        
        BMSAnalytics.logSessionStart()
        
        let sessionStartTime = BMSAnalytics.startTime
        
        XCTAssert(sessionStartTime > 0)
    }
    
    
    func testGenerateOutboundRequestMetadata() {
        
        Analytics.initialize(appName: "Unit Test App", apiKey: "1234")
        
        guard let outboundMetadata: String = BMSAnalytics.generateOutboundRequestMetadata() else {
            XCTFail()
            return
        }
        XCTAssert(outboundMetadata.contains("\"os\":\"iOS\""))
        XCTAssert(outboundMetadata.contains("\"brand\":\"Apple\""))
        XCTAssert(outboundMetadata.contains("\"model\":\"Simulator\""))
        XCTAssert(outboundMetadata.contains("\"mfpAppName\":\"Unit Test App\""))
        XCTAssert(!outboundMetadata.contains("\"deviceID\":\"\"")) // Make sure deviceID is not empty
        XCTAssert(!outboundMetadata.contains("\"sdkVersion\":\"\"")) // Make sure sdkVersion is not empty
        
        let osVersion = UIDevice.current.systemVersion
        XCTAssert(outboundMetadata.contains("\"osVersion\":\"" + "\(osVersion)" + "\""))
    }
    
    
    func testGenerateOutboundRequestMetadataWithoutAnalyticsAppName() {
        
        BMSAnalytics.uninitialize()
        
        let requestMetadata = BMSAnalytics.generateOutboundRequestMetadata()
        
        XCTAssertNotNil(requestMetadata)
        // Since BMSAnalytics has not been initialized, there will be no app name.
        // In a real app, this should default to the bundle ID. Unit tests have no bundle ID.
        XCTAssert(!requestMetadata!.contains("mfpAppName"))
    }
    
    
    func testAddAnalyticsMetadataToRequestWithAnalyticsAppName() {
        
        Analytics.initialize(appName: "Test app", apiKey: "1234")
        
        let requestMetadata = BMSAnalytics.generateOutboundRequestMetadata()
        
        XCTAssertNotNil(requestMetadata)
        // Since BMSAnalytics has not been initialized, there will be no app name.
        // In a real app, this should default to the bundle ID. Unit tests have no bundle ID.
        XCTAssert(requestMetadata!.contains("\"mfpAppName\":\"Test app\""))
    }


    func testUniqueDeviceId() {
        
        let bmsUserDefaults = UserDefaults(suiteName: Constants.userDefaultsSuiteName)
        bmsUserDefaults?.removeObject(forKey: "deviceId")
        
        // Generate new ID
        let generatedId = BMSAnalytics.uniqueDeviceId
        
        // Since an ID was already created, this method should keep returning the same one
        let retrievedId = BMSAnalytics.uniqueDeviceId
        XCTAssertEqual(retrievedId, generatedId)
        let retrievedId2 = BMSAnalytics.uniqueDeviceId
        XCTAssertEqual(retrievedId2, generatedId)
    }
    
    
    func testGetDeviceId() {
        
        let realDeviceId = "1234"
        XCTAssertEqual(BMSAnalytics.getDeviceId(from: realDeviceId), realDeviceId)
        
        let unknownDeviceId: String? = nil
        XCTAssertEqual(BMSAnalytics.getDeviceId(from: unknownDeviceId), "unknown")
    }
    
    
    func testUserIdentityApiWithLifecycleEvents() {
        
        XCTAssertNil(Analytics.delegate)
        
        Analytics.initialize(appName: "Unit Test App", apiKey: "1234", hasUserContext: true, deviceEvents: DeviceEvent.lifecycle)
        
        Analytics.userIdentity = "test user"
        XCTAssertEqual(Analytics.delegate?.userIdentity, "test user")
    }
    
    
    func testUserIdentityApiWithoutLifecycleEvents() {
        
        XCTAssertNil(Analytics.delegate)
        
        Analytics.initialize(appName: "Unit Test App", apiKey: "1234", hasUserContext: true)
        
        Analytics.userIdentity = "test user"
        XCTAssertNil(Analytics.delegate?.userIdentity)
    }
    
    
    func testUserIdentityWithAutomaticUsers() {
        
        // Without specifying the `automaticallyRecordUsers` parameter, we should get automatic users
        Analytics.initialize(appName: "Unit Test App", apiKey: "1234", deviceEvents: DeviceEvent.lifecycle)
        XCTAssertEqual(Analytics.delegate?.userIdentity, BMSAnalytics.uniqueDeviceId)
        
        Analytics.initialize(appName: "Unit Test App", apiKey: "1234", hasUserContext: false, deviceEvents: DeviceEvent.lifecycle)
        XCTAssertEqual(Analytics.delegate?.userIdentity, BMSAnalytics.uniqueDeviceId)
        
        // If hasUserContext is false, the developer should not be able to set Analytics.userIdentity themselves
        Analytics.userIdentity = "test user"
        XCTAssertEqual(Analytics.delegate?.userIdentity, BMSAnalytics.uniqueDeviceId)
    }
    
    
    func testUserIdentityInternalUpdatesCorrectly() {
        
        let analyticsInstance = BMSAnalytics()
        
        XCTAssertNil(analyticsInstance.userIdentity)
        
        Analytics.automaticallyRecordUsers = false
        BMSAnalytics.logSessionStart()
        
        analyticsInstance.userIdentity = "test user"
        XCTAssertNotEqual(analyticsInstance.userIdentity, BMSAnalytics.uniqueDeviceId)
        XCTAssertEqual(analyticsInstance.userIdentity, "test user")
    }
    
    
    func testUserIdentityFailsWithoutSessionId() {
        
        let analyticsInstance = BMSAnalytics()
        
        analyticsInstance.userIdentity = nil
        BMSAnalytics.lifecycleEvents[Constants.Metadata.Analytics.sessionId] = nil
        
        analyticsInstance.userIdentity = "fail"
        XCTAssertNotEqual(analyticsInstance.userIdentity, "fail")
    }
    
    
    func testAnalyticsLog(){
        let pathToFile = BMSLogger.logsDocumentPath + Constants.File.Analytics.logs
        
        do {
            try FileManager().removeItem(atPath: pathToFile)
        } catch {
            print("Could not delete " + pathToFile)
        }
        
        Logger.isLogStorageEnabled = true
        Logger.logLevelFilter = LogLevel.analytics
        let meta = ["hello": 1]
        
        Analytics.log(metadata: meta)
        
        guard let formattedContents = BMSLoggerTests.getContents(ofFile: pathToFile) else {
            XCTFail()
            return
        }
        let fileContents = "[\(formattedContents)]"
        let logDict = fileContents.data(using: .utf8)!
        guard let jsonDict = BMSLoggerTests.convertToJson(logs: logDict) else {
            XCTFail()
            return
        }
        
        let debugMessage: [String: Any]? = jsonDict[0]
        XCTAssertEqual(debugMessage?[Constants.Metadata.Logger.message] as? String, "")
        XCTAssertEqual(debugMessage?[Constants.Metadata.Logger.package] as? String, Logger.bmsLoggerPrefix + "analytics")
        XCTAssertTrue(debugMessage?[Constants.Metadata.Logger.timestamp] as? String != nil)
        XCTAssertEqual(debugMessage?[Constants.Metadata.Logger.level] as? String, "ANALYTICS")
        
        if let recordedMetadata = debugMessage?[Constants.Metadata.Logger.metadata] as? [String: Int] {
            XCTAssertEqual(recordedMetadata, meta)
        }
        else {
            XCTFail("Should have recorded metadata from Analytics.log().")
        }
    }
    
    
    func testDisableAnalyticsLogging(){
        let pathToFile = BMSLogger.logsDocumentPath + Constants.File.Analytics.logs
        
        do {
            try FileManager().removeItem(atPath: pathToFile)
        } catch {
            print("Could not delete " + pathToFile)
        }
        
        Analytics.isEnabled = false
        Logger.isLogStorageEnabled = true
        Logger.logLevelFilter = LogLevel.analytics
        let meta = ["hello": 1]
        
        Analytics.log(metadata: meta)
        
        let fileExists = FileManager().fileExists(atPath: pathToFile)
        
        XCTAssertFalse(fileExists)
    }
    
}

    
    
    
    
/**************************************************************************************************/
    
    
    
    

// MARK: - Swift 2
    
#else
    
    
    
class BMSAnalyticsTests: XCTestCase {
    
    
    override func tearDown() {
        BMSAnalytics.lifecycleEvents = [:]
        BMSAnalytics.startTime = 0
        BMSAnalytics.uninitialize()
        
        Request.requestAnalyticsData = nil
    }
    
    
    func testInitialize() {
        
        XCTAssertNil(BMSAnalytics.apiKey)
        XCTAssertNil(BMSAnalytics.appName)
        
        Analytics.initialize(appName: "Unit Test App", apiKey: "1234")
        XCTAssertEqual(BMSAnalytics.apiKey, "1234")
        XCTAssertEqual(BMSAnalytics.appName, "Unit Test App")
    }
    
    
    func testInitializeWithBmsClientInitialized() {
        
        XCTAssertNil(BMSAnalytics.apiKey)
        XCTAssertNil(BMSAnalytics.appName)
        XCTAssertNil(Request.requestAnalyticsData)
        
        BMSClient.sharedInstance.initialize(bluemixAppRoute: "http://example.com", bluemixAppGUID: "1234", bluemixRegion: BMSClient.Region.usSouth)
        Analytics.initialize(appName: "Unit Test App", apiKey: "1234")
        
        XCTAssertEqual(BMSAnalytics.apiKey, "1234")
        XCTAssertEqual(BMSAnalytics.appName, "Unit Test App")
        XCTAssertNotNil(Request.requestAnalyticsData)
    }
    
    
    func testInitializeRegistersUncaughtExceptionHandler() {
        
        Analytics.initialize(appName: "Unit Test App", apiKey: "1234")
        XCTAssertNotNil(NSGetUncaughtExceptionHandler())
    }
    
    
    func testInitializeAndDeviceEvents() {
        
        let referenceTime = Int64(NSDate.timeIntervalSinceReferenceDate() * 1000)
        
        Analytics.initialize(appName: "Unit Test App", apiKey: "1234", deviceEvents: DeviceEvent.lifecycle, DeviceEvent.network)
        
        // When registering LIFECYCLE events, the BMSAnalytics.logSessionStart() method should get called immediately, assigning a new value to BMSAnalytics.startTime and BMSAnalytics.lifecycleEvents
        XCTAssertTrue(BMSAnalytics.startTime >= referenceTime)
        XCTAssertTrue(BMSURLSession.shouldRecordNetworkMetadata)
    }
    
    
    func testLogSessionStartTwiceDoesNothing() {
        
        XCTAssertTrue(BMSAnalytics.lifecycleEvents.isEmpty)
        XCTAssertEqual(BMSAnalytics.startTime, 0)
        
        BMSAnalytics.logSessionStart()
        
        let firstSessionStartTime = BMSAnalytics.startTime
        XCTAssert(firstSessionStartTime > 0)
        
        let newSessionExpectation = expectationWithDescription("New session start time")
        
        // Even after waiting 1 second, the session start time should not change; the original session data should be preserved
        let timeDelay = dispatch_time(DISPATCH_TIME_NOW, 1000000) // 1 millisecond
        dispatch_after(timeDelay, dispatch_get_main_queue()) { () -> Void in
            newSessionExpectation.fulfill()
        }
        
        waitForExpectationsWithTimeout(0.01) { (error: NSError?) -> Void in
            BMSAnalytics.logSessionStart()
            let secondSessionStartTime = BMSAnalytics.startTime
            
            XCTAssertTrue(secondSessionStartTime == firstSessionStartTime)
        }
    }
    
    
    /**
     1) Call logSessionStart(), which should update BMSAnalytics.lifecycleEvents.
     2) Call logSessionEnd(). This should reset BMSAnalytics.lifecycleEvents by removing the session ID.
     3) Call logSessionStart() again. This should cause BMSAnalytics.lifecycleEvents to be updated:
     - The original start time should be replaced with the new start time.
     - The session (TAG_CATEGORY_APP_SESSION) is a unique ID that should contain a different value each time logSessionStart()
     is called.
     */
    func testLogSessionAfterCompleteSession() {
        
        XCTAssertTrue(BMSAnalytics.lifecycleEvents.isEmpty)
        XCTAssertEqual(BMSAnalytics.startTime, 0)
        
        BMSAnalytics.logSessionStart()
        
        let firstSessionStartTime = BMSAnalytics.startTime
        
        BMSAnalytics.logSessionEnd()
        
        XCTAssertTrue(BMSAnalytics.lifecycleEvents.isEmpty)
        XCTAssertEqual(BMSAnalytics.startTime, 0)
        
        let newSessionExpectation = expectationWithDescription("New session start time")
        
        // Need a little time delay so that the first and second sessions don't have the same start time
        let timeDelay = dispatch_time(DISPATCH_TIME_NOW, 1000000) // 1 millisecond
        dispatch_after(timeDelay, dispatch_get_main_queue()) { () -> Void in
            newSessionExpectation.fulfill()
        }
        
        waitForExpectationsWithTimeout(0.01) { (error: NSError?) -> Void in
            BMSAnalytics.logSessionStart()
            let secondSessionStartTime = BMSAnalytics.startTime
            
            XCTAssertTrue(secondSessionStartTime > firstSessionStartTime)
        }
    }
    
    
    /**
     1) Call logSessionEnd(). This should have no effect since logSessionStart() was never called.
     2) Call logSessionStart().
     */
    func testLogSessionEndBeforeLogSessionStart() {
        
        XCTAssertTrue(BMSAnalytics.lifecycleEvents.isEmpty)
        XCTAssertEqual(BMSAnalytics.startTime, 0)
        
        BMSAnalytics.logSessionEnd()
        
        XCTAssertTrue(BMSAnalytics.lifecycleEvents.isEmpty)
        XCTAssertEqual(BMSAnalytics.startTime, 0)
        
        BMSAnalytics.logSessionStart()
        
        let sessionStartTime = BMSAnalytics.startTime
        
        XCTAssert(sessionStartTime > 0)
    }
    
    
    func testGenerateOutboundRequestMetadata() {
        
        Analytics.initialize(appName: "Unit Test App", apiKey: "1234")
        
        guard let outboundMetadata: String = BMSAnalytics.generateOutboundRequestMetadata() else {
            XCTFail()
            return
        }
        XCTAssert(outboundMetadata.containsString("\"os\":\"iOS\""))
        XCTAssert(outboundMetadata.containsString("\"brand\":\"Apple\""))
        XCTAssert(outboundMetadata.containsString("\"model\":\"Simulator\""))
        XCTAssert(outboundMetadata.containsString("\"mfpAppName\":\"Unit Test App\""))
        XCTAssert(!outboundMetadata.containsString("\"deviceID\":\"\"")) // Make sure deviceID is not empty
        XCTAssert(!outboundMetadata.containsString("\"sdkVersion\":\"\"")) // Make sure sdkVersion is not empty
        
        let osVersion = UIDevice.currentDevice().systemVersion
        XCTAssert(outboundMetadata.containsString("\"osVersion\":\"" + "\(osVersion)" + "\""))
    }
    
    
    func testGenerateOutboundRequestMetadataWithoutAnalyticsAppName() {
        
        BMSAnalytics.uninitialize()
        
        let requestMetadata = BMSAnalytics.generateOutboundRequestMetadata()
        
        XCTAssertNotNil(requestMetadata)
        // Since BMSAnalytics has not been initialized, there will be no app name.
        // In a real app, this should default to the bundle ID. Unit tests have no bundle ID.
        XCTAssert(!requestMetadata!.containsString("mfpAppName"))
    }
    
    
    func testAddAnalyticsMetadataToRequestWithAnalyticsAppName() {
        
        Analytics.initialize(appName: "Test app", apiKey: "1234")
        
        let requestMetadata = BMSAnalytics.generateOutboundRequestMetadata()
        
        XCTAssertNotNil(requestMetadata)
        // Since BMSAnalytics has not been initialized, there will be no app name.
        // In a real app, this should default to the bundle ID. Unit tests have no bundle ID.
        XCTAssert(requestMetadata!.containsString("\"mfpAppName\":\"Test app\""))
    }
    
    
    func testUniqueDeviceId() {
        
        let bmsUserDefaults = NSUserDefaults(suiteName: Constants.userDefaultsSuiteName)
        bmsUserDefaults?.removeObjectForKey("deviceId")
        
        // Generate new ID
        let generatedId = BMSAnalytics.uniqueDeviceId
        
        // Since an ID was already created, this method should keep returning the same one
        let retrievedId = BMSAnalytics.uniqueDeviceId
        XCTAssertEqual(retrievedId, generatedId)
        let retrievedId2 = BMSAnalytics.uniqueDeviceId
        XCTAssertEqual(retrievedId2, generatedId)
    }
    
    
    func testGetDeviceId() {
        
        let realDeviceId = "1234"
        XCTAssertEqual(BMSAnalytics.getDeviceId(from: realDeviceId), realDeviceId)
        
        let unknownDeviceId: String? = nil
        XCTAssertEqual(BMSAnalytics.getDeviceId(from: unknownDeviceId), "unknown")
    }
    
    
    func testUserIdentityApiWithLifecycleEvents() {
        
        XCTAssertNil(Analytics.delegate)
        
        Analytics.initialize(appName: "Unit Test App", apiKey: "1234", hasUserContext: true, deviceEvents: DeviceEvent.lifecycle)
        
        Analytics.userIdentity = "test user"
        XCTAssertEqual(Analytics.delegate?.userIdentity, "test user")
    }
    
    
    func testUserIdentityApiWithoutLifecycleEvents() {
        
        XCTAssertNil(Analytics.delegate)
        
        Analytics.initialize(appName: "Unit Test App", apiKey: "1234", hasUserContext: true)
        
        Analytics.userIdentity = "test user"
        XCTAssertNil(Analytics.delegate?.userIdentity)
    }
    
    
    func testUserIdentityWithAutomaticUsers() {
        
        // Without specifying the `automaticallyRecordUsers` parameter, we should get automatic users
        Analytics.initialize(appName: "Unit Test App", apiKey: "1234", deviceEvents: DeviceEvent.lifecycle)
        XCTAssertEqual(Analytics.delegate?.userIdentity, BMSAnalytics.uniqueDeviceId)
        
        Analytics.initialize(appName: "Unit Test App", apiKey: "1234", hasUserContext: false, deviceEvents: DeviceEvent.lifecycle)
        XCTAssertEqual(Analytics.delegate?.userIdentity, BMSAnalytics.uniqueDeviceId)
    
        // If hasUserContext is false, the developer should not be able to set Analytics.userIdentity themselves
        Analytics.userIdentity = "test user"
        XCTAssertEqual(Analytics.delegate?.userIdentity, BMSAnalytics.uniqueDeviceId)
    }
    
    
    func testUserIdentityInternalUpdatesCorrectly() {
        
        let analyticsInstance = BMSAnalytics()
        
        XCTAssertNil(analyticsInstance.userIdentity)
        
        BMSAnalytics.logSessionStart()
        
        analyticsInstance.userIdentity = "test user"
        XCTAssertEqual(analyticsInstance.userIdentity, "test user")
        XCTAssertNotEqual(analyticsInstance.userIdentity, BMSAnalytics.uniqueDeviceId)
    }
    
    
    func testUserIdentityFailsWithoutSessionId() {
        
        let analyticsInstance = BMSAnalytics()
        
        analyticsInstance.userIdentity = nil
        BMSAnalytics.lifecycleEvents[Constants.Metadata.Analytics.sessionId] = nil
        
        analyticsInstance.userIdentity = "fail"
        XCTAssertNil(analyticsInstance.userIdentity)
    }
    
    
    func testAnalyticsLog(){
        let pathToFile = BMSLogger.logsDocumentPath + Constants.File.Analytics.logs
        
        do {
            try NSFileManager().removeItemAtPath(pathToFile)
        } catch {
            print("Could not delete " + pathToFile)
        }
        
        Logger.isLogStorageEnabled = true
        Logger.logLevelFilter = LogLevel.analytics
        let meta = ["hello": 1]
        
        Analytics.log(metadata: meta)
        
        guard let formattedContents = BMSLoggerTests.getFileContents(pathToFile) else {
            XCTFail()
            return
        }
        let fileContents = "[\(formattedContents)]"
        let logDict : NSData = fileContents.dataUsingEncoding(NSUTF8StringEncoding)!
        guard let jsonDict = BMSLoggerTests.convertLogsToJson(logDict) else {
            XCTFail()
            return
        }
        
        let debugMessage = jsonDict[0]
        XCTAssertTrue(debugMessage[Constants.Metadata.Logger.message] == "")
        XCTAssertTrue(debugMessage[Constants.Metadata.Logger.package] == Logger.bmsLoggerPrefix + "analytics")
        XCTAssertTrue(debugMessage[Constants.Metadata.Logger.timestamp] != nil)
        XCTAssertTrue(debugMessage[Constants.Metadata.Logger.level] == "ANALYTICS")
        print(debugMessage[Constants.Metadata.Logger.metadata])
        XCTAssertTrue(debugMessage[Constants.Metadata.Logger.metadata] == meta)
    }
    
    
    func testDisableAnalyticsLogging(){
        let pathToFile = BMSLogger.logsDocumentPath + Constants.File.Analytics.logs
        
        do {
            try NSFileManager().removeItemAtPath(pathToFile)
        } catch {
            print("Could not delete " + pathToFile)
        }
        
        Analytics.isEnabled = false
        Logger.isLogStorageEnabled = true
        Logger.logLevelFilter = LogLevel.analytics
        let meta = ["hello": 1]
        
        Analytics.log(metadata: meta)
        
        let fileExists = NSFileManager().fileExistsAtPath(pathToFile)
        
        XCTAssertFalse(fileExists)
    }

}



#endif
