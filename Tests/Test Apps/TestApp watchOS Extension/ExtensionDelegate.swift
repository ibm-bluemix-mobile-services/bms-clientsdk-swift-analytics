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


import WatchKit
import BMSCore
import BMSAnalytics


class ExtensionDelegate: NSObject, WKExtensionDelegate {

    func applicationDidFinishLaunching() {
        
        BMSClient.sharedInstance.initializeWithBluemixAppRoute(nil, bluemixAppGUID: nil, bluemixRegion: ".stage1-dev.ng.bluemix.net")

        // IMPORTANT: Replace the apiKey parameter with a key from a real Analytics service instance
        Analytics.initializeWithAppName("TestAppWatchOS", apiKey: "1234")
        
        Analytics.enabled = true
        Logger.logStoreEnabled = true
        Logger.sdkDebugLoggingEnabled = true
    }

    func applicationDidBecomeActive() {
        
        Analytics.recordApplicationDidBecomeActive()
        Analytics.userIdentity = "Some user name"
    }

    func applicationWillResignActive() {
        
        Analytics.recordApplicationWillResignActive()
    }

}
