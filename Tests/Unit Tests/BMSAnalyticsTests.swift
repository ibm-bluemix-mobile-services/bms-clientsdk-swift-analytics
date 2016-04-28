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


class BMSAnalyticsTests: XCTestCase {
    
    override func tearDown() {
        BMSAnalytics.lifecycleEvents = [:]
        BMSAnalytics.startTime = 0
        BMSAnalytics.uninitialize()
        
        Request.requestAnalyticsData = nil
    }
    

    func testinitializeWithAppName() {
     
        XCTAssertNil(BMSAnalytics.apiKey)
        XCTAssertNil(BMSAnalytics.appName)
        
        Analytics.initializeWithAppName("Unit Test App", apiKey: "1234")
        XCTAssertEqual(BMSAnalytics.apiKey, "1234")
        XCTAssertEqual(BMSAnalytics.appName, "Unit Test App")
    }
    
    
    func testInitializeWithAppNameWithBmsClientInitialized() {
        
        XCTAssertNil(BMSAnalytics.apiKey)
        XCTAssertNil(BMSAnalytics.appName)
        XCTAssertNil(Request.requestAnalyticsData)
        
        BMSClient.sharedInstance.initializeWithBluemixAppRoute("http://example.com", bluemixAppGUID: "1234", bluemixRegion: BMSClient.REGION_US_SOUTH)
        Analytics.initializeWithAppName("Unit Test App", apiKey: "1234")
        
        XCTAssertEqual(BMSAnalytics.apiKey, "1234")
        XCTAssertEqual(BMSAnalytics.appName, "Unit Test App")
        XCTAssertNotNil(Request.requestAnalyticsData)
    }
    
    
    func testInitializeWithAppNameRegistersUncaughtExceptionHandler() {
        
        Analytics.initializeWithAppName("Unit Test App", apiKey: "1234")
        XCTAssertNotNil(NSGetUncaughtExceptionHandler())
    }
    
    
    func testInitializeWithAppNameAndDeviceEvents() {
        
        let referenceTime = Int64(NSDate.timeIntervalSinceReferenceDate() * 1000)
        
        Analytics.initializeWithAppName("Unit Test App", apiKey: "1234", deviceEvents: DeviceEvent.LIFECYCLE)
        
        // When registering LIFECYCLE events, the BMSAnalytics.logSessionStart() method should get called immediately, assigning a new value to BMSAnalytics.startTime and BMSAnalytics.lifecycleEvents
        XCTAssertTrue(BMSAnalytics.startTime >= referenceTime)
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
    func testlogSessionEndBeforeLogSessionStart() {
        
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
        
        Analytics.initializeWithAppName("Unit Test App", apiKey: "1234")
        
        guard let outboundMetadata: String = BMSAnalytics.generateOutboundRequestMetadata() else {
            XCTFail()
            return
        }
        XCTAssert(outboundMetadata.containsString("\"os\":\"iOS\""))
        XCTAssert(outboundMetadata.containsString("\"brand\":\"Apple\""))
        XCTAssert(outboundMetadata.containsString("\"model\":\"Simulator\""))
        XCTAssert(outboundMetadata.containsString("\"mfpAppName\":\"Unit Test App\""))
        XCTAssert(!outboundMetadata.containsString("\"deviceID\":\"\"")) // Make sure deviceID is not empty
        
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
        
        Analytics.initializeWithAppName("Test app", apiKey: "1234")
        
        let requestMetadata = BMSAnalytics.generateOutboundRequestMetadata()
        
        XCTAssertNotNil(requestMetadata)
        // Since BMSAnalytics has not been initialized, there will be no app name.
        // In a real app, this should default to the bundle ID. Unit tests have no bundle ID.
        XCTAssert(requestMetadata!.containsString("\"mfpAppName\":\"Test app\""))
    }

    
    func testGenerateInboundResponseMetadata() {
        
        class MockRequest: Request {
            
            override var startTime: NSTimeInterval {
                get {
                    return 0
                }
                set { }
            }
            
            override var trackingId: String {
                get {
                    return ""
                }
                set { }
            }
            
            init() {
                super.init(url: "", headers: nil, queryParameters: nil)
            }
        }
        
        let requestUrl = "http://example.com"
        let request = MockRequest()
        request.sendWithCompletionHandler(nil)
        
        let responseInfo = "{\"key1\": \"value1\", \"key2\": \"value2\"}".dataUsingEncoding(NSUTF8StringEncoding)
        let urlResponse = NSHTTPURLResponse(URL: NSURL(string: "http://example.com")!, statusCode: 200, HTTPVersion: "HTTP/1.1", headerFields: ["key": "value"])
        let response = Response(responseData: responseInfo, httpResponse: urlResponse, isRedirect: false)
        
        let responseMetadata = BMSAnalytics.generateInboundResponseMetadata(request, response: response, url: requestUrl)
        
        let outboundTime = responseMetadata["$outboundTimestamp"] as? NSTimeInterval
        let inboundTime = responseMetadata["$inboundTimestamp"] as? NSTimeInterval
        let roundTripTime = responseMetadata["$roundTripTime"] as? NSTimeInterval
        
        XCTAssertNotNil(outboundTime)
        XCTAssertNotNil(inboundTime)
        XCTAssertNotNil(roundTripTime)
        
        XCTAssert(inboundTime > outboundTime)
        XCTAssert(roundTripTime > 0)
        
        let responseBytes = responseMetadata["$bytesReceived"] as? Int
        XCTAssertNotNil(responseBytes)
        XCTAssert(responseBytes == 36)
    }


    func testUniqueDeviceId() {
        
        let bmsUserDefaults = NSUserDefaults(suiteName: "com.ibm.mobilefirstplatform.clientsdk.swift.BMSCore")
        bmsUserDefaults?.removeObjectForKey("deviceId")
        
        // Generate new ID
        let generatedId = BMSAnalytics.uniqueDeviceId
        
        // Since an ID was already created, this method should keep returning the same one
        let retrievedId = BMSAnalytics.uniqueDeviceId
        XCTAssertEqual(retrievedId, generatedId)
        let retrievedId2 = BMSAnalytics.uniqueDeviceId
        XCTAssertEqual(retrievedId2, generatedId)
    }
    
    
    func testUserIdentityApiWithLifecycleEvents() {
        
        XCTAssertNil(Analytics.userIdentity)
        XCTAssertNil(Analytics.delegate)
        
        Analytics.initializeWithAppName("Unit Test App", apiKey: "1234", deviceEvents: DeviceEvent.LIFECYCLE)
        
        Analytics.userIdentity = "test user"
        XCTAssertEqual(Analytics.userIdentity, "test user")
        XCTAssertEqual(Analytics.delegate?.userIdentity, "test user")
        
        Analytics.userIdentity = nil
        XCTAssertNil(Analytics.userIdentity)
        XCTAssertEqual(Analytics.delegate?.userIdentity, BMSAnalytics.uniqueDeviceId)
    }
    
    
    func testUserIdentityApiWithoutLifecycleEvents() {
        
        XCTAssertNil(Analytics.userIdentity)
        XCTAssertNil(Analytics.delegate)
        
        Analytics.initializeWithAppName("Unit Test App", apiKey: "1234")
        
        Analytics.userIdentity = "test user"
        XCTAssertEqual(Analytics.userIdentity, "test user")
        XCTAssertEqual(Analytics.delegate?.userIdentity, BMSAnalytics.uniqueDeviceId)
        
        Analytics.userIdentity = nil
        XCTAssertNil(Analytics.userIdentity)
        XCTAssertEqual(Analytics.delegate?.userIdentity, BMSAnalytics.uniqueDeviceId)
    }
    
    
    func testUserIdentityInternalUpdatesCorrectly() {
        
        let analyticsInstance = BMSAnalytics()
        
        XCTAssertNil(analyticsInstance.userIdentity)
        
        BMSAnalytics.logSessionStart()
        
        analyticsInstance.userIdentity = "test user"
        XCTAssertEqual(analyticsInstance.userIdentity, "test user")
        XCTAssertNotEqual(analyticsInstance.userIdentity, BMSAnalytics.deviceId)
        
        analyticsInstance.userIdentity = nil
        XCTAssertEqual(analyticsInstance.userIdentity, BMSAnalytics.uniqueDeviceId)
    }
    
    
    func testUserIdentityFailsWithoutSessionId() {
        
        let analyticsInstance = BMSAnalytics()
        
        analyticsInstance.userIdentity = nil
        BMSAnalytics.lifecycleEvents[Constants.Metadata.Analytics.sessionId] = nil
        
        analyticsInstance.userIdentity = "fail"
        XCTAssertNotEqual(analyticsInstance.userIdentity, "fail")
        XCTAssertEqual(analyticsInstance.userIdentity, BMSAnalytics.uniqueDeviceId)
    }
    
    
    func testAnalyticsLog(){
        let pathToFile = BMSLogger.logsDocumentPath + Constants.File.Analytics.logs
        
        do {
            try NSFileManager().removeItemAtPath(pathToFile)
        } catch {
            print("Could not delete " + pathToFile)
        }
        
        Logger.logStoreEnabled = true
        Logger.logLevelFilter = LogLevel.Analytics
        let meta = ["hello": 1]
        
        Analytics.log(meta)
        
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
        
        Analytics.enabled = false
        Logger.logStoreEnabled = true
        Logger.logLevelFilter = LogLevel.Analytics
        let meta = ["hello": 1]
        
        Analytics.log(meta)
        
        let fileExists = NSFileManager().fileExistsAtPath(pathToFile)
        
        XCTAssertFalse(fileExists)
    }

    
}