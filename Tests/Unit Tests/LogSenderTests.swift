/*
*     Copyright 2015 IBM Corp.
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

    
    func testLogSendRequest(){
        let fakePKG = "MYPKG"
        let API_KEY = "apikey"
        let APP_NAME = "myApp"
        let pathToFile = Logger.logsDocumentPath + Logger.FILE_LOGGER_LOGS
        let pathToBuffer = Logger.logsDocumentPath + Logger.FILE_LOGGER_SEND
        let bmsClient = BMSClient.sharedInstance
        bmsClient.initializeWithBluemixAppRoute("bluemix", bluemixAppGUID: "appID1", bluemixRegionSuffix: BMSClient.REGION_US_SOUTH)
        Analytics.initializeWithAppName("testAppName", apiKey: "testApiKey")
        let url = "https://" + Logger.HOST_NAME + "." + BMSClient.REGION_US_SOUTH + Logger.UPLOAD_PATH
        
        Analytics.initializeWithAppName(APP_NAME, apiKey: API_KEY)
        
        let headers = ["Content-Type": "application/json", Logger.API_ID_HEADER: API_KEY]
        
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
        Logger.maxLogStoreSize = Logger.DEFAULT_MAX_STORE_SIZE
        
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
        let fakePKG = Logger.MFP_LOGGER_PACKAGE
        let pathToFile = Logger.logsDocumentPath + Logger.FILE_LOGGER_LOGS
        let pathToBuffer = Logger.logsDocumentPath + Logger.FILE_LOGGER_SEND
        let bmsClient = BMSClient.sharedInstance
        bmsClient.initializeWithBluemixAppRoute("bluemix", bluemixAppGUID: "appID1", bluemixRegionSuffix: BMSClient.REGION_US_SOUTH)
        Analytics.initializeWithAppName("testAppName", apiKey: "")
        
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
        Logger.maxLogStoreSize = Logger.DEFAULT_MAX_STORE_SIZE
        
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
        XCTAssertTrue(error[Logger.TAG_MESSAGE] != nil)
        XCTAssertTrue(error[Logger.TAG_PACKAGE] == fakePKG)
        XCTAssertTrue(error[Logger.TAG_TIMESTAMP] != nil)
        XCTAssertTrue(error[Logger.TAG_LEVEL] == "ERROR")
    }
    
    
    func testLogSendFailWithUninitializedBMSClient(){
        let fakePKG = Logger.MFP_LOGGER_PACKAGE
        let missingValue = "bluemixRegionSuffix"
        let bmsClient = BMSClient.sharedInstance
        bmsClient.initializeWithBluemixAppRoute("bluemix", bluemixAppGUID: "appID1", bluemixRegionSuffix: "")
        
        Analytics.initializeWithAppName("testAppName", apiKey: "testApiKey")
        let msg = "No value found for the BMSClient \(missingValue) property."
        let pathToFile = Logger.logsDocumentPath + Logger.FILE_LOGGER_LOGS
        let pathToBuffer = Logger.logsDocumentPath + Logger.FILE_LOGGER_SEND
        let pathToOverflow = Logger.logsDocumentPath + Logger.FILE_LOGGER_OVERFLOW
        
        do {
            try NSFileManager().removeItemAtPath(pathToFile)
            
        } catch {
            
        }
        
        do {
            try NSFileManager().removeItemAtPath(pathToBuffer)
            
        } catch {
            
        }
        
        do {
            try NSFileManager().removeItemAtPath(pathToOverflow)
        } catch {
            
        }
        
        let loggerInstance = Logger.getLoggerForName(fakePKG)
        Logger.logStoreEnabled = true
        Logger.logLevelFilter = LogLevel.Debug
        Logger.maxLogStoreSize = Logger.DEFAULT_MAX_STORE_SIZE
        
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
        
        let request = LogSender.buildLogSendRequest { (response, error) -> Void in
            XCTAssertNil(response)
            XCTAssertNotNil(error)
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
        XCTAssertTrue(error[Logger.TAG_MESSAGE] == msg)
        XCTAssertTrue(error[Logger.TAG_PACKAGE] == fakePKG)
        XCTAssertTrue(error[Logger.TAG_TIMESTAMP] != nil)
        XCTAssertTrue(error[Logger.TAG_LEVEL] == "ERROR")
    }
    
    
    func testReturnInitializationError(){
        // BMSClient initialization
        LogSender.returnInitializationError("BMSClient", missingValue:"test") { (response, error) -> Void in
            XCTAssertNil(response)
            XCTAssertNotNil(error)
            XCTAssertEqual(error!.code, MFPErrorCode.ClientNotInitialized.rawValue)
            XCTAssertEqual(error!.domain, Logger.ANALYTICS_ERROR_CODE)
        }
        
        // Analytics initialization
        LogSender.returnInitializationError("Analytics", missingValue:"test") { (response, error) -> Void in
            XCTAssertNil(response)
            XCTAssertNotNil(error)
            XCTAssertEqual(error!.code, BMSAnalyticsErrorCode.AnalyticsNotInitialized.rawValue)
            XCTAssertEqual(error!.domain, Logger.ANALYTICS_ERROR_CODE)
        }
        
        // Unknown initialization
        LogSender.returnInitializationError("Unknown class", missingValue:"test") { (response, error) -> Void in
            XCTAssertNil(response)
            XCTAssertNotNil(error)
            XCTAssertEqual(error!.code, -1)
            XCTAssertEqual(error!.domain, Logger.ANALYTICS_ERROR_CODE)
        }
    }
    
    
    func testDeleteFileFail(){
        let fakePKG = "mfpsdk.logger"
        let pathToFile = Logger.logsDocumentPath + Logger.FILE_LOGGER_LOGS
        let pathToBuffer = Logger.logsDocumentPath + Logger.FILE_LOGGER_SEND
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
        Logger.maxLogStoreSize = Logger.DEFAULT_MAX_STORE_SIZE
        
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
        
        LogSender.deleteFile(Logger.FILE_LOGGER_SEND)
        
        XCTAssertFalse(NSFileManager().fileExistsAtPath(pathToBuffer))
    }
    
    
    func testDeleteFile(){
        let fakePKG = "MYPKG"
        let pathToFile = Logger.logsDocumentPath + Logger.FILE_LOGGER_LOGS
        let pathToBuffer = Logger.logsDocumentPath + Logger.FILE_LOGGER_SEND
        
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
        Logger.maxLogStoreSize = Logger.DEFAULT_MAX_STORE_SIZE
        
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
        
        LogSender.deleteFile(Logger.FILE_LOGGER_SEND)
        
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
        XCTAssertEqual(LogRecorder.extractFileNameFromPath(logFile3), "[Unknown]")
        XCTAssertEqual(LogRecorder.extractFileNameFromPath(logFile4), "[Unknown]")
        XCTAssertEqual(LogRecorder.extractFileNameFromPath(logFile5), "[Unknown]")
    }

}
