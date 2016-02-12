//
//  ExtensionDelegate.swift
//  TestAppWatchOS Extension
//
//  Created by Anthony Oliveri on 1/19/16.
//  Copyright © 2016 IBM. All rights reserved.
//

import WatchKit
import BMSAnalyticsWatchOS
import BMSCore

class ExtensionDelegate: NSObject, WKExtensionDelegate {

    func applicationDidFinishLaunching() {
        
        BMSClient.sharedInstance.initializeWithBluemixAppRoute(nil, bluemixAppGUID: nil, bluemixRegionSuffix: BluemixRegion.US_SOUTH)
        
        Analytics.initializeWithAppName("TestAppiOS", apiKey: "1234") // Cannot use DeviceEvents.LIFECYCLE for watchOS apps
        Analytics.enabled = true
    }

    func applicationDidBecomeActive() {
        
        Analytics.recordApplicationDidBecomeActive()
    }

    func applicationWillResignActive() {
        
        Analytics.recordApplicationWillResignActive()
    }

}
