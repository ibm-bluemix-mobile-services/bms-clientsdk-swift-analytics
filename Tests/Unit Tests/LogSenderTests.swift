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
import BMSCore
@testable import BMSAnalytics


class LogSenderTests: XCTestCase {
    
    
    override func tearDown() {
        BMSClient.sharedInstance.initializeWithBluemixAppRoute(nil, bluemixAppGUID: nil, bluemixRegion: "")
        Analytics.uninitialize()
    }

    
    func testLogSendRequest(){
        let fakePKG = "MYPKG"
        let API_KEY = "apikey"
        let APP_NAME = "myApp"
        let pathToFile = Logger.logsDocumentPath + Constants.File.Logger.logs
        let pathToBuffer = Logger.logsDocumentPath + Constants.File.Logger.outboundLogs
        let bmsClient = BMSClient.sharedInstance
        bmsClient.initializeWithBluemixAppRoute("bluemix", bluemixAppGUID: "appID1", bluemixRegion: BMSClient.REGION_US_SOUTH)
        Analytics.initializeForBluemix(appName: "testAppName", apiKey: "testApiKey")
        let url = "https://" + Constants.AnalyticsServer.Bluemix.hostName + "." + BMSClient.REGION_US_SOUTH + Constants.AnalyticsServer.Bluemix.uploadPath
        
        Analytics.initializeForBluemix(appName: APP_NAME, apiKey: API_KEY)
        
        let headers = ["Content-Type": "text/plain", Constants.analyticsApiKey: API_KEY]
        
        do {
            try NSFileManager().removeItemAtPath(pathToFile)
            
        } catch {
            
        }
        
        do {
            try NSFileManager().removeItemAtPath(pathToBuffer)
            
        } catch {
            
        }
        
        let loggerInstance = Logger.getLoggerForName(fakePKG)
        Logger.logStoreEnabled = true
        Logger.logLevelFilter = LogLevel.Debug
        Logger.maxLogStoreSize = Constants.File.defaultMaxSize
        
        loggerInstance.debug("Hello world")
        loggerInstance.info("1242342342343243242342")
        loggerInstance.warn("Str: heyoooooo")
        loggerInstance.error("1 2 3 4")
        loggerInstance.fatal("StephenColbert")
        
        let request = LogSender.buildLogSendRequest() { (response, error) -> Void in
            }!
        
        XCTAssertTrue(request.resourceUrl == url)
        XCTAssertTrue(request.headers == headers)
        XCTAssertNil(request.queryParameters)
        XCTAssertTrue(request.httpMethod == HttpMethod.POST)
    }
    
    
    func testLogSendFailWithEmptyAPIKey(){
        let fakePKG = Constants.Package.logger
        let pathToFile = Logger.logsDocumentPath + Constants.File.Logger.logs
        let pathToBuffer = Logger.logsDocumentPath + Constants.File.Logger.outboundLogs
        let bmsClient = BMSClient.sharedInstance
        bmsClient.initializeWithBluemixAppRoute("bluemix", bluemixAppGUID: "appID1", bluemixRegion: BMSClient.REGION_US_SOUTH)
        Analytics.initializeForBluemix(appName: "testAppName", apiKey: "")
        
        do {
            try NSFileManager().removeItemAtPath(pathToFile)
            
        } catch {
            
        }
        
        do {
            try NSFileManager().removeItemAtPath(pathToBuffer)
            
        } catch {
            
        }
        
        let loggerInstance = Logger.getLoggerForName(fakePKG)
        Logger.logStoreEnabled = true
        Logger.logLevelFilter = LogLevel.Debug
        Logger.maxLogStoreSize = Constants.File.defaultMaxSize
        
        loggerInstance.debug("Hello world")
        loggerInstance.info("1242342342343243242342")
        loggerInstance.warn("Str: heyoooooo")
        loggerInstance.error("1 2 3 4")
        loggerInstance.fatal("StephenColbert")
        
        guard let _ = LoggerTests.getLogs(LogFileType.LOGGER) else {
            XCTFail()
            return
        }
        
        XCTAssertTrue(NSFileManager().fileExistsAtPath(pathToBuffer))
        
        let request = LogSender.buildLogSendRequest() { (response, error) -> Void in
        }
        
        XCTAssertNil(request)
        
        guard let formattedContents = LoggerTests.getFileContents(pathToFile) else {
            XCTFail()
            return
        }
        let fileContents = "[\(formattedContents)]"
        let logDict  = fileContents.dataUsingEncoding(NSUTF8StringEncoding)!
        
        guard let newJsonDict = LoggerTests.convertLogsToJson(logDict) else {
            XCTFail()
            return
        }
        
        let error = newJsonDict[0]
        XCTAssertTrue(error[Constants.Metadata.Logger.message] != nil)
        XCTAssertTrue(error[Constants.Metadata.Logger.package] == fakePKG)
        XCTAssertTrue(error[Constants.Metadata.Logger.timestamp] != nil)
        XCTAssertTrue(error[Constants.Metadata.Logger.level] == "ERROR")
    }
    
    
    func testBuildLogSendRequestForBluemix() {
        
        let bmsClient = BMSClient.sharedInstance
        bmsClient.initializeWithBluemixAppRoute("bluemix", bluemixAppGUID: "appID1", bluemixRegion: BMSClient.REGION_US_SOUTH)
        Analytics.initializeForBluemix(appName: "testAppName", apiKey: "1234")
        
        let bmsRequest = LogSender.buildLogSendRequest() { (response, error) -> Void in
            }
        
        XCTAssertNotNil(bmsRequest)
        XCTAssertTrue(bmsRequest is Request)
        
        let bmsLogUploadUrl = "https://" + Constants.AnalyticsServer.Bluemix.hostName + "." + "ng.bluemix.net" + Constants.AnalyticsServer.Bluemix.uploadPath
        XCTAssertEqual(bmsRequest!.resourceUrl, bmsLogUploadUrl)
    }
    
    
    func testBuildLogSendRequestForFoundation() {
        
        let mfpClient = MFPClient.sharedInstance
        mfpClient.initializeWithUrlComponents(mfpProtocol: "http", mfpHost: "localhost", mfpPort: "9080")
        Analytics.initializeForBluemix(appName: "testAppName", apiKey: "1234")
        
        let mfpRequest = LogSender.buildLogSendRequest() { (response, error) -> Void in
        }
        
        XCTAssertNotNil(mfpRequest)
        
        let mfpLogUploadUrl = "http://localhost:9080" + Constants.AnalyticsServer.Foundation.uploadPath
        XCTAssertEqual(mfpRequest!.resourceUrl, mfpLogUploadUrl)
    }
    
    
    func testReturnInitializationError(){
        // BMSClient initialization
        LogSender.returnInitializationError("BMSClient", missingValue:"test") { (response, error) -> Void in
            XCTAssertNil(response)
            XCTAssertNotNil(error)
            XCTAssertEqual(error!.code, BMSCoreError.ClientNotInitialized.rawValue)
            XCTAssertEqual(error!.domain, BMSAnalyticsError.domain)
        }
        
        // Analytics initialization
        LogSender.returnInitializationError("Analytics", missingValue:"test") { (response, error) -> Void in
            XCTAssertNil(response)
            XCTAssertNotNil(error)
            XCTAssertEqual(error!.code, BMSAnalyticsError.AnalyticsNotInitialized.rawValue)
            XCTAssertEqual(error!.domain, BMSAnalyticsError.domain)
        }
        
        // Unknown initialization
        LogSender.returnInitializationError("Unknown class", missingValue:"test") { (response, error) -> Void in
            XCTAssertNil(response)
            XCTAssertNotNil(error)
            XCTAssertEqual(error!.code, -1)
            XCTAssertEqual(error!.domain, BMSAnalyticsError.domain)
        }
    }
    
    
    func testDeleteFileFail(){
        let fakePKG = "mfpsdk.logger"
        let pathToFile = Logger.logsDocumentPath + Constants.File.Logger.logs
        let pathToBuffer = Logger.logsDocumentPath + Constants.File.Logger.outboundLogs
        do {
            try NSFileManager().removeItemAtPath(pathToFile)
            
        } catch {
            
        }
        
        do {
            try NSFileManager().removeItemAtPath(pathToBuffer)
            
        } catch {
            
        }
        
        let loggerInstance = Logger.getLoggerForName(fakePKG)
        Logger.logStoreEnabled = true
        Logger.logLevelFilter = LogLevel.Debug
        Logger.maxLogStoreSize = Constants.File.defaultMaxSize
        
        loggerInstance.debug("Hello world")
        
        guard let logs: String = LoggerTests.getLogs(LogFileType.LOGGER) else {
            XCTFail()
            return
        }
        
        XCTAssertTrue(NSFileManager().fileExistsAtPath(pathToBuffer))
        
        XCTAssertNotNil(logs)
        
        do {
            try NSFileManager().removeItemAtPath(pathToBuffer)
        } catch {
            
        }
        
        LogSender.deleteFile(Constants.File.Logger.outboundLogs)
        
        XCTAssertFalse(NSFileManager().fileExistsAtPath(pathToBuffer))
    }
    
    
    func testDeleteFile(){
        let fakePKG = "MYPKG"
        let pathToFile = Logger.logsDocumentPath + Constants.File.Logger.logs
        let pathToBuffer = Logger.logsDocumentPath + Constants.File.Logger.outboundLogs
        
        do {
            try NSFileManager().removeItemAtPath(pathToFile)
            
        } catch {
            
        }
        
        do {
            try NSFileManager().removeItemAtPath(pathToBuffer)
            
        } catch {
            
        }
        
        let loggerInstance = Logger.getLoggerForName(fakePKG)
        Logger.logStoreEnabled = true
        Logger.logLevelFilter = LogLevel.Debug
        Logger.maxLogStoreSize = Constants.File.defaultMaxSize
        
        loggerInstance.debug("Hello world")
        loggerInstance.info("1242342342343243242342")
        loggerInstance.warn("Str: heyoooooo")
        loggerInstance.error("1 2 3 4")
        loggerInstance.fatal("StephenColbert")
        
        guard let _ = LoggerTests.getLogs(LogFileType.LOGGER) else {
            XCTFail()
            return
        }
        
        XCTAssertTrue(NSFileManager().fileExistsAtPath(pathToBuffer))
        
        LogSender.deleteFile(Constants.File.Logger.outboundLogs)
        
        XCTAssertFalse(NSFileManager().fileExistsAtPath(pathToBuffer))
    }
    
    
    func testExtractFileNameFromPath() {
        
        let logFile1 = "some/path/to/file.txt"
        let logFile2 = "path//with///extra///slashes.log.txt"
        let logFile3 = "/////"
        let logFile4 = ""
        let logFile5 = "sdajfasldkfjalksfdj"
        
        
        XCTAssertEqual(LogRecorder.extractFileNameFromPath(logFile1), "file.txt")
        XCTAssertEqual(LogRecorder.extractFileNameFromPath(logFile2), "slashes.log.txt")
        XCTAssertEqual(LogRecorder.extractFileNameFromPath(logFile3), Constants.File.unknown)
        XCTAssertEqual(LogRecorder.extractFileNameFromPath(logFile4), Constants.File.unknown)
        XCTAssertEqual(LogRecorder.extractFileNameFromPath(logFile5), Constants.File.unknown)
    }

}
