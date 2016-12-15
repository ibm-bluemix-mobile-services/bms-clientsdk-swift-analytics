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


import UIKit
import BMSCore
import BMSAnalytics



#if swift(>=3.0)



@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey : Any]? = nil) -> Bool {
        
        BMSClient.sharedInstance.initialize(bluemixRegion: ".stage1.ng.bluemix.net")
        
        // IMPORTANT: Replace the apiKey parameter with a key from a real Analytics service instance
        Analytics.initialize(appName: "TestAppiOS", apiKey: "1234", hasUserContext: true, collectLocation: true, deviceEvents: DeviceEvent.lifecycle, DeviceEvent.network)
        
        Analytics.isEnabled = true
        Logger.isLogStorageEnabled = true
        Logger.isInternalDebugLoggingEnabled = true
        
        return true
    }
    
}
    
    
    
    
    
/**************************************************************************************************/
    
    
    
    
    
// MARK: - Swift 2
    
#else
    
    
    
@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    
    
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        
        BMSClient.sharedInstance.initialize(bluemixRegion: ".stage1.ng.bluemix.net")
        
        // IMPORTANT: Replace the apiKey parameter with a key from a real Analytics service instance
        Analytics.initialize(appName: "TestAppiOS", apiKey: "1234", hasUserContext: true, collectLocation: true, deviceEvents: DeviceEvent.lifecycle, DeviceEvent.network)
        
        Analytics.isEnabled = true
        Logger.isLogStorageEnabled = true
        Logger.isInternalDebugLoggingEnabled = true
        
        return true
    }
    
}



#endif
