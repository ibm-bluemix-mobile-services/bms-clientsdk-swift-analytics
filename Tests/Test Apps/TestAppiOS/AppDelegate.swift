//
//  AppDelegate.swift
//  TestAppiOS
//
//  Created by Anthony Oliveri on 1/19/16.
//  Copyright © 2016 IBM. All rights reserved.
//

import UIKit
import BMSCore
import BMSAnalytics

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?


    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        
        BMSClient.sharedInstance.initializeWithBluemixAppRoute(nil, bluemixAppGUID: nil, bluemixRegionSuffix: BluemixRegion.US_SOUTH)
        
        // IMPORTANT: Replace the apiKey parameter with a key from a real Analytics service instance
        Analytics.initializeWithAppName("TestAppiOS", apiKey: "1234", deviceEvents: DeviceEvent.LIFECYCLE)
        Analytics.enabled = true
        
        return true
    }
}

