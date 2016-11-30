BMSAnalytics
===================================================

[![Build Status](https://travis-ci.org/ibm-bluemix-mobile-services/bms-clientsdk-swift-analytics.svg?branch=master)](https://travis-ci.org/ibm-bluemix-mobile-services/bms-clientsdk-swift-analytics)
[![Platform](https://img.shields.io/cocoapods/p/BMSAnalytics.svg?style=flat)](http://cocoadocs.org/docsets/BMSAnalytics)
[![CocoaPods Compatible](https://img.shields.io/cocoapods/v/BMSAnalytics.svg)](https://img.shields.io/cocoapods/v/BMSAnalytics.svg)
[![](https://img.shields.io/badge/bluemix-powered-blue.svg)](https://bluemix.net)

BMSAnalytics is the analytics and logger component of the Swift SDKs for [IBM Bluemix Mobile Services](https://console.ng.bluemix.net/docs/mobile/services.html).



## Table of Contents

* [Summary](#summary)
* [Requirements](#requirements)
* [Installation](#installation)
* [Example Usage](#example-usage)
* [Release Notes](https://github.com/ibm-bluemix-mobile-services/bms-clientsdk-swift-analytics/releases)
* [License](#license)



## Summary

BMSAnalytics is the client SDK for the Mobile Analytics service on Bluemix. This service provides insight into how your apps are performing and how they are being used. With BMSAnalytics, you can gather information about your app's usage such as unique users, app lifecycle duration, roundtrip time of network requests, crashes, and any additional information or events that you choose to log.

This SDK is also available for [Android](https://github.com/ibm-bluemix-mobile-services/bms-clientsdk-android-analytics) and [Cordova](https://github.com/ibm-bluemix-mobile-services/bms-clientsdk-cordova-plugin-core).

Read the [official documentation](https://console.ng.bluemix.net/docs/services/mobileanalytics/index.html) for more information about getting started with Mobile Analytics.



## Requirements

* iOS 8.0+ / watchOS 2.0+
* Xcode 7.3, 8.0
* Swift 2.2 - 3.0
* Cocoapods or Carthage



## Installation

The Bluemix Mobile Services Swift SDKs can be installed with either [Cocoapods](http://cocoapods.org/) or [Carthage](https://github.com/Carthage/Carthage).


### Cocoapods

To install BMSAnalytics using Cocoapods, add it to your Podfile. If your project does not have a Podfile yet, use the `pod init` command.

```ruby
use_frameworks!

target 'MyApp' do
    pod 'BMSAnalytics'
end
```

Then run the `pod install` command, and open the generated `.xcworkspace` file. To update to a newer release of BMSAnalytics, use `pod update BMSAnalytics`.

For more information on using Cocoapods, refer to the [Cocoapods Guides](https://guides.cocoapods.org/using/index.html).

#### Xcode 8

When installing with Cocoapods in Xcode 8, make sure you have installed Cocoapods [1.1.0](https://github.com/CocoaPods/CocoaPods/releases) or later. You can get the latest version of Cocoapods using the command `sudo gem install cocoapods`.

If you receive a prompt saying "Convert to Current Swift Syntax?" when opening your project in Xcode 8 (following the installation of BMSAnalytics), **do not** convert BMSAnalytics, BMSCore, or BMSAnalyticsAPI.


### Carthage

To install BMSAnalytics with Carthage, follow the instructions [here](https://github.com/Carthage/Carthage#getting-started).

Add this line to your Cartfile: 

```ogdl
github "ibm-bluemix-mobile-services/bms-clientsdk-swift-analytics"
```

Then run the `carthage update` command. Once the build is finished, add `BMSAnalytics.framework`, `BMSCore.framework` and `BMSAnalyticsAPI.framework` to your project (step 3 in the link above). 

#### Xcode 8

For apps built with Swift 2.3, use the command `carthage update --toolchain com.apple.dt.toolchain.Swift_2_3`. Otherwise, use `carthage update`.



## Example Usage

* [Import the modules](#import-the-modules)
* [Initialize](#initialize)
* [Configure Logger and Analytics](#configure-logger-and-analytics)
* [Set the app user's identity](#set-the-app-users-identity)
* [Log some information](#log-some-information)
* [Send the data to the server](#send-the-data-to-the-server)
* [Disable logging output](#disable-logging-output-for-production-applications)

> View the complete API reference [here](https://ibm-bluemix-mobile-services.github.io/API-docs/client-SDK/BMSAnalytics/Swift/index.html).

--

### Import the modules

```Swift
import BMSCore
import BMSAnalytics
```

--

### Initialize

Initialize `BMSClient` and `Analytics`. This is typically done at the beginning of the app's lifecycle, such as the `application(_:didFinishLaunchingWithOptions:)` method in the `AppDelegate.swift`.

```Swift
BMSClient.sharedInstance.initialize(bluemixRegion: BMSClient.Region.usSouth)

Analytics.initialize(appName: "My App", apiKey: "1234", hasUserContext: true, deviceEvents: .lifecycle, .network)
```

--

### Configure Logger and Analytics

Enable logger and analytics, and set the `Logger.logLevelFilter` to the level of severity you want to record. This is typically done at the beginning of the app's lifecycle, such as the `application(_:didFinishLaunchingWithOptions:)` method in the `AppDelegate.swift`.

```Swift
Analytics.isEnabled = true
Logger.isLogStorageEnabled = true
Logger.isInternalDebugLoggingEnabled = true
Logger.logLevelFilter = LogLevel.debug
```

--

### Set the app user's identity

If your app's users log in with a username, you can track each user with `Analytics.userIdentity`. To use this feature, you must have set the `hasUserContext` parameter to `true` in the `Analytics.initialize()` method first. If you set `hasUserContext` to `false`, BMSAnalytics will automatically record user identities, treating each device as one unique user.

```Swift
Analytics.userIdentity = "John Doe"
```

--

### Log some information

Create a Logger instance and log messages anywhere in your application, using an appropriate severity level.

```Swift
let logger = Logger.logger(name: "My Logger")

logger.debug(message: "Fine level information, typically for debugging purposes.")
logger.info(message: "Some useful information regarding the application's state.")
logger.warn(message: "Something may have gone wrong.")
logger.error(message: "Something has definitely gone wrong!")
logger.fatal(message: "CATASTROPHE!")

// The metadata can be any JSON object
Analytics.log(metadata: ["event": "something significant that occurred"])
```

> By default the Bluemix Mobile Service SDK internal debug logging will not be printed to Xcode console. If you want to see BMS debug logs, set the `Logger.isInternalDebugLoggingEnabled` property to `true`. 

--

### Send the data to the server

Send all recorded logs and analytics data to the Mobile Analytics service. This is typically done at the beginning of the app's lifecycle, such as the `application(_:didFinishLaunchingWithOptions:)` method in the `AppDelegate.swift`.

```Swift
Logger.send(completionHandler: { (response: Response?, error: Error?) in
    if let response = response {
        print("Status code: \(response.statusCode)")
        print("Response: \(response.responseText)")
    }
    if let error = error {
        logger.error(message: "Failed to send logs. Error: \(error)")
    }
})

Analytics.send(completionHandler: { (response: Response?, error: Error?) in
    if let response = response {
        print("Status code: \(response.statusCode)")
        print("Response: \(response.responseText)")
    }
    if let error = error {
        logger.error(message: "Failed to send analytics. Error: \(error)")
    }
})
```

--

### Disable logging output for production applications

By default, the Logger class will print its logs to Xcode console. If is advised to disable Logger output for applications built in release mode. In order to do so add a debug flag named `RELEASE_BUILD` to your release build configuration. One way of doing so is adding `-D RELEASE_BUILD` to the `Other Swift Flags` section of the project build configuration.



## License

Copyright 2016 IBM Corp.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
