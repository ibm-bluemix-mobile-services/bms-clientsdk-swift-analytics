IBM Bluemix Mobile Services - Client SDK Swift Analytics
===================================================

[![Build Status](https://travis-ci.org/ibm-bluemix-mobile-services/bms-clientsdk-swift-analytics.svg?branch=master)](https://travis-ci.org/ibm-bluemix-mobile-services/bms-clientsdk-swift-analytics)
[![Build Status](https://travis-ci.org/ibm-bluemix-mobile-services/bms-clientsdk-swift-analytics.svg?branch=development)](https://travis-ci.org/ibm-bluemix-mobile-services/bms-clientsdk-swift-analytics)

This is the analytics and logger component of the Swift SDK for [IBM Bluemix Mobile Services](https://console.ng.bluemix.net/docs/mobile/index.html).


## Requirements
* iOS 8.0+ / watchOS 2.0+
* Xcode 7.3, 8.0
* Swift 2.2 - 3.0


## Installation
The Bluemix Mobile Services Swift SDKs are available via [Cocoapods](http://cocoapods.org/) and [Carthage](https://github.com/Carthage/Carthage).

### Cocoapods
To install BMSAnalytics using Cocoapods, add it to your Podfile:

```ruby
use_frameworks!

target 'MyApp' do
    pod 'BMSAnalytics'
end
```

Then run the `pod install` command. To update to a newer release of BMSAnalytics, use `pod update BMSAnalytics`.

#### Xcode 8

Before running the `pod install` command, install Cocoapods [1.1.0.rc.2](https://github.com/CocoaPods/CocoaPods/releases) (or later), using the command `sudo gem install cocoapods --pre`.

If you receive a prompt saying "Convert to Current Swift Syntax?" when opening your project in Xcode 8 (following the installation of BMSAnalytics), **do not** convert BMSAnalytics, BMSCore, or BMSAnalyticsAPI.


### Carthage

To install BMSAnalytics with Carthage, follow the instructions [here](https://github.com/Carthage/Carthage#getting-started).

Add this line to your Cartfile: 

```ogdl
github "ibm-bluemix-mobile-services/bms-clientsdk-swift-analytics"
```

Then run the `carthage update` command. Once the build is finished, add `BMSAnalytics.framework`, `BMSCore.framework` and `BMSAnalyticsAPI.framework` to your project. 


#### Xcode 8

For apps built with Swift 2.3, use the command `carthage update --toolchain com.apple.dt.toolchain.Swift_2_3`. Otherwise, use `carthage update`.


=======================
Copyright 2015 IBM Corp.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
