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
import CoreLocation



#if swift(>=3.0)



class InterfaceController: WKInterfaceController {

    
    let locationManager = CLLocationManager()
    
    
    @IBAction func logLocationButtonPressed() {
    
        Analytics.logLocation()
    }
    
    
    @IBAction func sendAnalyticsButtonPressed() {
        
        Logger.logLevelFilter = LogLevel.debug
        let logger = Logger.logger(name: "TestAppWatchOS")
        
        logger.debug(message: "Send analytics button pressed")
        Analytics.log(metadata: ["buttonPressed": "recordLog"])
        
        func completionHandler(sentUsing sendType: String) -> BMSCompletionHandler {
            
            return {
                (response: Response?, error: Error?) -> Void in
                if let response = response {
                    print("\(sendType) sent successfully: " + String(response.isSuccessful))
                    print("Status code: " + String(describing: response.statusCode))
                    if let responseText = response.responseText {
                        print("Response text: " + responseText)
                    }
                    print("\n")
                }
            }
        }
        
        Logger.send(completionHandler: completionHandler(sentUsing: "Logs"))
        Analytics.send(completionHandler: completionHandler(sentUsing: "Analytics"))
    }
    
    
    override func didAppear() {
        
        super.didAppear()
        
        // Get permission for location services
        if CLLocationManager.locationServicesEnabled() && CLLocationManager.authorizationStatus() == CLAuthorizationStatus.notDetermined {
            self.locationManager.requestWhenInUseAuthorization()
        }
    }
}
    
    
    
    
    
/**************************************************************************************************/
    
    
    
    
    
// MARK: - Swift 2
    
#else
    
    
    

class InterfaceController: WKInterfaceController {
    
    
    
    let locationManager = CLLocationManager()
    
    
    @IBAction func logLocationButtonPressed() {
        
        Analytics.logLocation()
    }
    
    
    @IBAction func sendAnalyticsButtonPressed() {
        
        Logger.logLevelFilter = LogLevel.debug
        let logger = Logger.logger(name: "TestAppWatchOS")
        
        logger.debug(message: "Send analytics button pressed")
        Analytics.log(metadata: ["buttonPressed": "recordLog"])
        
        func completionHandler(sentUsing sendType: String) -> BMSCompletionHandler {
            
            return {
                (response: Response?, error: NSError?) -> Void in
                    if let response = response {
                        print("\(sendType) sent successfully: " + String(response.isSuccessful))
                        print("Status code: " + String(response.statusCode))
                        if let responseText = response.responseText {
                            print("Response text: " + responseText)
                        }
                        print("\n")
                    }
            }
        }
        
        Logger.send(completionHandler: completionHandler(sentUsing: "Logs"))
        Analytics.send(completionHandler: completionHandler(sentUsing: "Analytics"))
    }
    
    
    override func didAppear() {
        
        super.didAppear()
        
        // Get permission for location services
        if CLLocationManager.locationServicesEnabled() && CLLocationManager.authorizationStatus() == CLAuthorizationStatus.NotDetermined {
            self.locationManager.requestWhenInUseAuthorization()
        }
    }
}



#endif
