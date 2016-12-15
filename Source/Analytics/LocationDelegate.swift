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


import Foundation
import CoreLocation
import BMSAnalyticsAPI



// MARK: - Swift 3

#if swift(>=3.0)
    
    
    
// Adds the current location to analytics metadata before logging the event.
// Note: We do not use location updates as separate events; the information only tags along with other events (like switching users or ending an app session).
internal class LocationDelegate: NSObject, CLLocationManagerDelegate {
    
    
    // The metadata that will be logged along with the user's current location
    internal var analyticsMetadata: [String: Any]? = nil
    
    // Contains the timestamp of the last recorded event, so that we do not record any event more than once.
    internal var previousTimestamp: Int64 = 0
    
    
    internal func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        guard var metadata = self.analyticsMetadata else {
            // No metadata to record, so there is no point in retrieving the location
            return
        }
        
        guard let currentLocation: CLLocationCoordinate2D = manager.location?.coordinate else {
            Analytics.logger.warn(message: "Could not determine the user's current location.")
            recordMetadata(metadata, locationManager: manager)
            
            return
        }
        
        metadata[Constants.Metadata.Analytics.latitude] = currentLocation.latitude
        metadata[Constants.Metadata.Analytics.longitude] = currentLocation.longitude
        recordMetadata(metadata, locationManager: manager)
    }
    
    
    internal func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        
        Analytics.logger.error(message: "Failed to retrieve the user's current location. Error: \(error)")
        
        if let metadata = self.analyticsMetadata {
            recordMetadata(metadata, locationManager: manager)
        }
    }
    
    
    // Log the metadata and stop location services (if using iOS 8)
    internal func recordMetadata(_ metadata: [String: Any], locationManager: CLLocationManager) {
        
        // For some reason, CLLocationManager requestLocation() will sometimes call this delegate more than once. In these circumstances, we do not want to log because the same metadata has already been logged before.
        if let currentTimestamp = metadata[Constants.Metadata.Analytics.timestamp] as? Int64,
            currentTimestamp != previousTimestamp {
            
            Analytics.log(metadata: metadata)
            previousTimestamp = currentTimestamp
        }
        
        // If the device iOS version is less than 9.0, then we had to use startUpdatingLocation() in BMSAnalytics, meaning that we now need to stopUpdatingLocation() since we only want a one-time event
        if #available(iOS 9.0, *) {}
        else {
            locationManager.stopUpdatingLocation()
        }
    }
    
}





/**************************************************************************************************/





// MARK: - Swift 2
    
#else
    
    
    
// Adds the current location to analytics metadata before logging the event.
// Note: We do not use location updates as separate events; the information only tags along with other events (like switching users or ending an app session).
internal class LocationDelegate: NSObject, CLLocationManagerDelegate {
    
    
    // The metadata that will be logged along with the user's current location
    internal var analyticsMetadata: [String: AnyObject]? = nil
    
    // Contains the timestamp of the last recorded event, so that we do not record any event more than once.
    internal var previousTimestamp: Int64 = 0
    
    
    internal func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        guard var metadata = self.analyticsMetadata else {
            // No metadata to record, so there is no point in retrieving the location
            return
        }
        
        guard let currentLocation: CLLocationCoordinate2D = manager.location?.coordinate else {
            Analytics.logger.warn(message: "Could not determine the user's current location.")
            recordMetadata(metadata, locationManager: manager)
            
            return
        }
        
        metadata[Constants.Metadata.Analytics.latitude] = currentLocation.latitude
        metadata[Constants.Metadata.Analytics.longitude] = currentLocation.longitude
        recordMetadata(metadata, locationManager: manager)
    }
    
    
    internal func locationManager(manager: CLLocationManager, didFailWithError error: NSError) {
        
        Analytics.logger.error(message: "Failed to retrieve the user's current location. Error: \(error)")
        
        if let metadata = self.analyticsMetadata {
            recordMetadata(metadata, locationManager: manager)
        }
    }
    
    
    // Log the metadata and stop location services (if using iOS 8)
    internal func recordMetadata(metadata: [String: AnyObject], locationManager: CLLocationManager) {
        
        // For some reason, CLLocationManager requestLocation() will sometimes call this delegate more than once. In these circumstances, we do not want to log because the same metadata has already been logged before.
        if let currentTimestamp = (metadata[Constants.Metadata.Analytics.timestamp] as? NSNumber)?.longLongValue where
            currentTimestamp != previousTimestamp {
            
            Analytics.log(metadata: metadata)
            previousTimestamp = currentTimestamp
        }
        
        // If the device iOS version is less than 9.0, then we had to use startUpdatingLocation() in BMSAnalytics, meaning that we now need to stopUpdatingLocation() since we only want a one-time event
        if #available(iOS 9.0, *) {}
        else {
            locationManager.stopUpdatingLocation()
        }
    }
}



#endif
