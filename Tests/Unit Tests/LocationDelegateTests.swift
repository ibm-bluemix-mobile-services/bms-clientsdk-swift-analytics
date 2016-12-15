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


import XCTest
import CoreLocation
import BMSAnalyticsAPI
@testable import BMSAnalytics



class LocationDelegateTests: XCTestCase {
    
    
    // MARK: - Setup
    
    // Sample metadtata
    
    static let appSessionID = "5F9468D4-5AB2-4739-8F1E-B06318DB43B6"
    static let originalTimestamp = Int64(1000000000)
    static let futureTimestamp = Int64(2000000000)
    static let newLocation = CLLocation(latitude: 30.4, longitude: -97.715)
    
    static let sampleMetadata: [String: Any] = ["$category": "userSwitch", "$userID": "Anthony", "$latitude": newLocation.coordinate.latitude, "$longitude": newLocation.coordinate.longitude, "$timestamp": LocationDelegateTests.originalTimestamp, "$appSessionID": LocationDelegateTests.appSessionID]
    
    static let sampleMetadataWithoutLocation: [String: Any] = ["$category": "userSwitch", "$userID": "Anthony", "$timestamp": LocationDelegateTests.originalTimestamp, "$appSessionID": LocationDelegateTests.appSessionID]
    
    
    
    // Assume that CLLocationManager knows the user's location
    class CLLocationManagerMock: CLLocationManager {
        
        override var location: CLLocation? {
            return LocationDelegateTests.newLocation
        }
    }
    
    
    
    // Assume that CLLocationManager does not know the user's location
    class CLLocationManagerMockWithoutLocation: CLLocationManager {
        
        override var location: CLLocation? {
            return nil
        }
    }
    
    
    
    // Used to check results of LocationDelegate methods, since they mostly just call Analytics.log(metadata:), which delegates to BMSLogger
    class BMSLoggerMock: BMSLogger {
        
        // Expect the LocationDelegate to log the metadata
        let metadataLogExpectation: XCTestExpectation?
        
        // Expect the LocationDelegate to log the metadata, which may or may not include location
        let hasMetadata: Bool
        
        // Expect the LocationDelegate to log the metadata, including location (latitude and longitude)
        let hasLocation: Bool
        
        init(expectation: XCTestExpectation?, hasMetadata: Bool, hasLocation: Bool) {
            self.metadataLogExpectation = expectation
            self.hasMetadata = hasMetadata
            self.hasLocation = hasLocation
        }
        
        // The LocationDelegate's main function is to log the analytics metadata
        // Here, we intercept the log to check if LocationDelegate successfully logged the sampleMetadata
        override func logToFile(message logMessage: String, level: LogLevel, loggerName: String, calledFile: String, calledFunction: String, calledLineNumber: Int, additionalMetadata: [String : Any]?) {
            
            // Check if the logged metadata matches the expected sampleMetadata
            if additionalMetadata != nil, additionalMetadata?[Constants.Metadata.Analytics.sessionId] as? String == LocationDelegateTests.appSessionID {
            
                // Make sure location is being logged if we have it, and, conversely, that it is not being logged if we don't have location
                // The same applies to the metadata as a whole
                
                if additionalMetadata?[Constants.Metadata.Analytics.latitude] as? Double == LocationDelegateTests.newLocation.coordinate.latitude &&
                    additionalMetadata?[Constants.Metadata.Analytics.longitude] as? Double == LocationDelegateTests.newLocation.coordinate.longitude {
                    
                    if hasLocation {
                        metadataLogExpectation?.fulfill()
                    }
                    else {
                        XCTFail("Should not have logged the location because it (presumably) should not exist")
                    }
                }
                else if hasMetadata && !hasLocation {
                    metadataLogExpectation?.fulfill()
                }
                else {
                    XCTFail("Should not have logged the metadata because it (presumably) should not exist")
                }
            }
        }
    }
    
    
    
    // MARK: - Tests
    
    func testDidUpdateLocationsWithMetadata() {
        
        let expectation = self.expectation(description: "didUpdateLocations should successfully log the metadata with location information")
        
        Logger.delegate = BMSLoggerMock(expectation: expectation, hasMetadata: true, hasLocation: true)
        
        let locationDelegate = LocationDelegate()
        // Start without location to make sure that didUpdateLocations() can successfully add location to the metadata
        locationDelegate.analyticsMetadata = LocationDelegateTests.sampleMetadataWithoutLocation
        locationDelegate.locationManager(CLLocationManagerMock(), didUpdateLocations: [LocationDelegateTests.newLocation])
        
        self.waitForExpectations(timeout: 0.1, handler: nil)
    }
    
    
    func testDidUpdateLocationsWithoutMetadata() {
        
        Logger.delegate = BMSLoggerMock(expectation: nil, hasMetadata: false, hasLocation: false)
        
        let locationDelegate = LocationDelegate()
        locationDelegate.locationManager(CLLocationManagerMock(), didUpdateLocations: [LocationDelegateTests.newLocation])
        
        // If the BMSLoggerMock receives a log from this location update, then the test should fail
    }
    
    
    func testDidUpdateLocationsWithoutLocation() {
        
        let expectation = self.expectation(description: "didUpdateLocations should successfully log the metadata without location information")
        
        Logger.delegate = BMSLoggerMock(expectation: expectation, hasMetadata: true, hasLocation: false)
        
        let locationDelegate = LocationDelegate()
        locationDelegate.analyticsMetadata = LocationDelegateTests.sampleMetadataWithoutLocation
        locationDelegate.locationManager(CLLocationManagerMockWithoutLocation(), didUpdateLocations: [])
        
        self.waitForExpectations(timeout: 0.1, handler: nil)
    }
    
    
    func testDidFailWithErrorWithMetadata() {
        
        let expectation = self.expectation(description: "didFailWithError should successfully log the metadata without location information")
        
        Logger.delegate = BMSLoggerMock(expectation: expectation, hasMetadata: true, hasLocation: false)
        
        enum DummyError: Error {
            case zero
        }
        
        let locationDelegate = LocationDelegate()
        locationDelegate.analyticsMetadata = LocationDelegateTests.sampleMetadataWithoutLocation
        locationDelegate.locationManager(CLLocationManager(), didFailWithError: DummyError.zero)
        
        self.waitForExpectations(timeout: 0.1, handler: nil)
    }
    
    
    func testDidFailWithErrorWithoutMetadata() {
        
        Logger.delegate = BMSLoggerMock(expectation: nil, hasMetadata: false, hasLocation: false)
        
        enum DummyError: Error {
            case zero
        }
        
        let locationDelegate = LocationDelegate()
        locationDelegate.locationManager(CLLocationManager(), didFailWithError: DummyError.zero)
        
        // If the BMSLoggerMock receives a log from this method, then the test should fail
    }
    
    
    func testRecordMetadataForUniqueEvent() {
        
        let expectation = self.expectation(description: "recordMetadata should successfully log the metadata with location information if this is a new event (i.e. different timestamp from previous event)")
        
        Logger.delegate = BMSLoggerMock(expectation: expectation, hasMetadata: true, hasLocation: true)
        
        let locationDelegate = LocationDelegate()
        // Simulate a new analytics event with a future timestamp
        locationDelegate.previousTimestamp = LocationDelegateTests.futureTimestamp
        locationDelegate.recordMetadata(metadata: LocationDelegateTests.sampleMetadata, locationManager: CLLocationManager())
        self.waitForExpectations(timeout: 0.1, handler: nil)
    }
    
    
    func testRecordMetadataForRepeatEvent() {
        
        Logger.delegate = BMSLoggerMock(expectation: nil, hasMetadata: false, hasLocation: false)
        
        let locationDelegate = LocationDelegate()
        // Simulate a duplicate analytics event with the same timestamp as a previously recorded event
        locationDelegate.previousTimestamp = LocationDelegateTests.originalTimestamp
        locationDelegate.recordMetadata(metadata: LocationDelegateTests.sampleMetadata, locationManager: CLLocationManager())
        
        // If the BMSLoggerMock receives a log from this method, then the test should fail because duplicate events should only be recorded once
    }
}
