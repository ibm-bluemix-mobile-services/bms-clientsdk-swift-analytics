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


public extension BMSAnalytics {
    
    
    internal static func getWatchOSDeviceInfo() -> (String, String, String) {
        
        var osVersion = "", model = "", deviceId = ""
        
        let device = WKInterfaceDevice.currentDevice()
        osVersion = device.systemVersion
        // There is no "identifierForVendor" property for Apple Watch, so we generate a random ID
        deviceId = Analytics.uniqueDeviceId
        model = device.model
        
        return (osVersion, model, deviceId)
    }
    
}
