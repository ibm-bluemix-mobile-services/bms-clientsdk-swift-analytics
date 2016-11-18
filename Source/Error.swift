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



// MARK: - Swift 3

#if swift(>=3.0)

    
    
/**
    These error codes indicate a failure that occurred within the BMSAnalytics framework.
*/
public enum BMSAnalyticsError: Error {
    
    /// Analytics must be initialized with `Analytics.initialize(appName:apiKey:hasUserContext:deviceEvents:)` before calling `Analytics.send(completionHandler:)` or `Logger.send(completionHandler:)`.
    case analyticsNotInitialized
    
    /// If there are no logs or analytics data recorded, there is nothing to send to the Mobile Analytics service.
    case noLogsToSend
    
    static let domain = "com.ibm.mobilefirstplatform.clientsdk.swift.BMSAnalytics"
}


    
    
    
/**************************************************************************************************/
    
    
    

    
// MARK: - Swift 2
    
#else
    
    
    
/**
    These error codes indicate a failure that occurred within the BMSAnalytics framework.
*/
public enum BMSAnalyticsError: Int, ErrorType {
    
    // Start at 100 so that BMSAnalytics errors are distinguishable from BMSCore errors (which start at 0).
    /// Analytics must be initialized with the `Analytics.initialize(appName:apiKey:hasUserContext:deviceEvents:)` method before calling `Analytics.send()` or `Logger.send()`.
    case analyticsNotInitialized = 100
    
    /// If there are no logs or analytics data recorded, there is nothing to send to the Mobile Analytics service.
    case noLogsToSend = 101
    
    static let domain = "com.ibm.mobilefirstplatform.clientsdk.swift.BMSAnalytics"
}

    
    
#endif
