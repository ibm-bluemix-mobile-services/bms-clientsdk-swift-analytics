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


class InterfaceController: WKInterfaceController {

    
    @IBAction func sendAnalyticsButtonPressed() {
        
        Logger.logLevelFilter = LogLevel.Debug
        let logger = Logger.logger(forName: "TestAppWatchOS")
        logger.debug("Send analytics button pressed")
        
        Analytics.log(["buttonPressed": "recordLog"])
        
        func completionHandler(sendType: String) -> BmsCompletionHandler {
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
        
        Logger.send(completionHandler: completionHandler("Logs"))
        
        Analytics.send(completionHandler: completionHandler("Analytics"))
    }
}
