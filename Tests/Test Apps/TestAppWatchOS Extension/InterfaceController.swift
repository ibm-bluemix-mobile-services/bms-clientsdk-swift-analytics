//
//  InterfaceController.swift
//  TestAppWatchOS Extension
//
//  Created by Anthony Oliveri on 1/19/16.
//  Copyright © 2016 IBM. All rights reserved.
//

import WatchKit
import BMSAnalyticsWatchOS
import BMSCore


class InterfaceController: WKInterfaceController {

    
    @IBAction func sendAnalyticsButtonPressed() {
        
        Analytics.log(["buttonPressed": "recordLog"])
        
        Analytics.send { (response: Response?, error: NSError?) -> Void in
            if let response = response {
                print("\nSENDING ANALYTICS")
                print("Logs send successfully: " + String(response.isSuccessful))
                print("Status code: " + String(response.statusCode))
                if let responseText = response.responseText {
                    print("Response text: " + responseText)
                }
                print("\n")
            }
        }
    }
}
