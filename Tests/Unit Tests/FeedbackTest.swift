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

class FeedbackTest: XCTestCase {
    override func tearDown() {
        BMSAnalytics.lifecycleEvents = [:]
        BMSAnalytics.startTime = 0
        BMSAnalytics.uninitialize()

        Request.requestAnalyticsData = nil
    }

    func testCurrentlySendingFeedbackdata() {

        let bmsClient = BMSClient.sharedInstance
        bmsClient.initialize(bluemixAppRoute: "bluemix", bluemixAppGUID: "appID1", bluemixRegion: BMSClient.Region.usSouth)
        Analytics.initialize(appName: "testAppName", apiKey: "1234")

        XCTAssertFalse(Logger.currentlySendingFeedbackdata)
    }

}

#endif
