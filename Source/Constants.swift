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


import BMSCore


internal struct Constants {
    
    
    static let uncaughtException = "loggerUncaughtExceptionDetected"
    static let outboundLogPayload = "__logdata"
    static let analyticsApiKey = "x-mfp-analytics-api-key"
    static let userDefaultsSuiteName = "com.ibm.mobilefirstplatform.clientsdk.swift.Analytics"

    
    struct Package {
        
        static let logger = Logger.bmsLoggerPrefix + "logger"
        static let analytics = Logger.bmsLoggerPrefix + "analytics"
    }
    
    
    struct AnalyticsServer {
        
        static let hostName = "mobile-analytics-dashboard"
        static let uploadPath =  "/analytics-service/rest/data/events/clientlogs/"
        static let uploadFeedbackPath =  "/analytics-service/rest/data/events/inappfeedback/"
    }
    
    
    struct File {
        
        static let unknown = "[Unknown]"
        
        struct Logger {
            
            static let logs = Constants.Package.logger + ".log"
            static let overflowLogs = Constants.Package.logger + ".log.overflow"
            static let outboundLogs = Constants.Package.logger + ".log.send"
        }

        struct Analytics {
            
            static let logs = Constants.Package.analytics + ".log"
            static let overflowLogs = Constants.Package.analytics + ".log.overflow"
            static let outboundLogs = Constants.Package.analytics + ".log.send"
        }
    }
    
    
    struct Metadata {
        
        struct Logger {
            
            static let metadata = "metadata"
            static let level = "level"
            static let timestamp = "timestamp"
            static let package = "pkg"
            static let message = "msg"
        }
        
        struct Analytics {
            
            static let sessionId = "$appSessionID"
            static let duration = "$duration"
            static let category = "$category"
            static let closedBy = "$closedBy"
            static let appSession = "appSession"
            static let deviceId = "deviceId"
            static let user = "userSwitch"
            static let userId = "$userID"
            static let initialContext = "initialCtx"
            static let timestamp = "$timestamp"
            static let location = "logLocation"
            static let latitude = "$latitude"
            static let longitude = "$longitude"
            static let stacktrace = "$stacktrace"
            static let exceptionMessage = "$exceptionMessage"
            static let exceptionClass = "$exceptionClass"
        }
    }
    
}
