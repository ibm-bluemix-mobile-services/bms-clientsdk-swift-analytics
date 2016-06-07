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


class BMSLoggerTests: XCTestCase {
    
    
    override func tearDown() {
        BMSClient.sharedInstance.initializeWithBluemixAppRoute(nil, bluemixAppGUID: nil, bluemixRegion: "")
        BMSAnalytics.uninitialize()
    }
    
    
    func testIsUncaughtExceptionUpdatesProperly(){

        let loggerInstance = BMSLogger()
        
        loggerInstance.isUncaughtExceptionDetected = false
        XCTAssertFalse(Logger.isUncaughtExceptionDetected)
        loggerInstance.isUncaughtExceptionDetected = true
        XCTAssertTrue(Logger.isUncaughtExceptionDetected)
    }

    
    func testSetGetMaxLogStoreSize(){
    
        Logger.maxLogStoreSize = 12345678 as UInt64
        let size = Logger.maxLogStoreSize
        XCTAssertTrue(size == 12345678)
    }

    
    func testlogStoreEnabled(){
        
        let capture1 = Logger.logStoreEnabled
        XCTAssertTrue(capture1, "should default to true");

        Logger.logStoreEnabled = false
    
        let capture2 = Logger.logStoreEnabled
        XCTAssertFalse(capture2)
    }
    
    
    func testNoInternalLogging(){
        let fakePKG = Constants.Package.logger
        let pathToFile = BMSLogger.logsDocumentPath + Constants.File.Logger.logs
        
        do {
            try NSFileManager().removeItemAtPath(pathToFile)
        } catch {
            print("Could not delete " + pathToFile)
        }
        
        let loggerInstance = Logger.logger(forName: fakePKG)
        Logger.logStoreEnabled = true
        Logger.logLevelFilter = LogLevel.Debug
        Logger.sdkDebugLoggingEnabled = false
        
        loggerInstance.debug("Hello world")
        loggerInstance.info("1242342342343243242342")
        loggerInstance.warn("Str: heyoooooo")
        loggerInstance.error("1 2 3 4")
        loggerInstance.fatal("StephenColbert")

        guard let formattedContents = BMSLoggerTests.getFileContents(pathToFile) else {
            XCTFail()
            return
        }
        let fileContents = "[\(formattedContents)]"
        let logDict : NSData = fileContents.dataUsingEncoding(NSUTF8StringEncoding)!
        guard let jsonDict = BMSLoggerTests.convertLogsToJson(logDict) else {
            XCTFail()
            return
        }
        
        let debugMessage = jsonDict[0]
        XCTAssertTrue(debugMessage[Constants.Metadata.Logger.message] == "Hello world")
        XCTAssertTrue(debugMessage[Constants.Metadata.Logger.package] == fakePKG)
        XCTAssertTrue(debugMessage[Constants.Metadata.Logger.timestamp] != nil)
        XCTAssertTrue(debugMessage[Constants.Metadata.Logger.level] == "DEBUG")
        
        let infoMessage = jsonDict[1]
        XCTAssertTrue(infoMessage[Constants.Metadata.Logger.message] == "1242342342343243242342")
        XCTAssertTrue(infoMessage[Constants.Metadata.Logger.package] == fakePKG)
        XCTAssertTrue(infoMessage[Constants.Metadata.Logger.timestamp] != nil)
        XCTAssertTrue(infoMessage[Constants.Metadata.Logger.level] == "INFO")
        
        let warnMessage = jsonDict[2]
        XCTAssertTrue(warnMessage[Constants.Metadata.Logger.message] == "Str: heyoooooo")
        XCTAssertTrue(warnMessage[Constants.Metadata.Logger.package] == fakePKG)
        XCTAssertTrue(warnMessage[Constants.Metadata.Logger.timestamp] != nil)
        XCTAssertTrue(warnMessage[Constants.Metadata.Logger.level] == "WARN")
        
        let errorMessage = jsonDict[3]
        XCTAssertTrue(errorMessage[Constants.Metadata.Logger.message] == "1 2 3 4")
        XCTAssertTrue(errorMessage[Constants.Metadata.Logger.package] == fakePKG)
        XCTAssertTrue(errorMessage[Constants.Metadata.Logger.timestamp] != nil)
        XCTAssertTrue(errorMessage[Constants.Metadata.Logger.level] == "ERROR")
        
        let fatalMessage = jsonDict[4]
        XCTAssertTrue(fatalMessage[Constants.Metadata.Logger.message] == "StephenColbert")
        XCTAssertTrue(fatalMessage[Constants.Metadata.Logger.package] == fakePKG)
        XCTAssertTrue(fatalMessage[Constants.Metadata.Logger.timestamp] != nil)
    }

    
    func testLogMethods(){
        let fakePKG = "MYPKG"
        let pathToFile = BMSLogger.logsDocumentPath + Constants.File.Logger.logs
        
        do {
            try NSFileManager().removeItemAtPath(pathToFile)
        } catch {
            
        }
        
        let loggerInstance = Logger.logger(forName: fakePKG)
        Logger.logStoreEnabled = true
        Logger.logLevelFilter = LogLevel.Debug

        loggerInstance.debug("Hello world")
        loggerInstance.info("1242342342343243242342")
        loggerInstance.warn("Str: heyoooooo")
        loggerInstance.error("1 2 3 4")
        loggerInstance.fatal("StephenColbert")
    
        
        guard let formattedContents = BMSLoggerTests.getFileContents(pathToFile) else {
            XCTFail()
            return
        }
        let fileContents = "[\(formattedContents)]"
        let logDict : NSData = fileContents.dataUsingEncoding(NSUTF8StringEncoding)!
        guard let jsonDict = BMSLoggerTests.convertLogsToJson(logDict) else {
            XCTFail()
            return
        }

        let debugMessage = jsonDict[0]
        XCTAssertTrue(debugMessage[Constants.Metadata.Logger.message] == "Hello world")
        XCTAssertTrue(debugMessage[Constants.Metadata.Logger.package] == fakePKG)
        XCTAssertTrue(debugMessage[Constants.Metadata.Logger.timestamp] != nil)
        XCTAssertTrue(debugMessage[Constants.Metadata.Logger.level] == "DEBUG")

        let infoMessage = jsonDict[1]
        XCTAssertTrue(infoMessage[Constants.Metadata.Logger.message] == "1242342342343243242342")
        XCTAssertTrue(infoMessage[Constants.Metadata.Logger.package] == fakePKG)
        XCTAssertTrue(infoMessage[Constants.Metadata.Logger.timestamp] != nil)
        XCTAssertTrue(infoMessage[Constants.Metadata.Logger.level] == "INFO")

        let warnMessage = jsonDict[2]
        XCTAssertTrue(warnMessage[Constants.Metadata.Logger.message] == "Str: heyoooooo")
        XCTAssertTrue(warnMessage[Constants.Metadata.Logger.package] == fakePKG)
        XCTAssertTrue(warnMessage[Constants.Metadata.Logger.timestamp] != nil)
        XCTAssertTrue(warnMessage[Constants.Metadata.Logger.level] == "WARN")

        let errorMessage = jsonDict[3]
        XCTAssertTrue(errorMessage[Constants.Metadata.Logger.message] == "1 2 3 4")
        XCTAssertTrue(errorMessage[Constants.Metadata.Logger.package] == fakePKG)
        XCTAssertTrue(errorMessage[Constants.Metadata.Logger.timestamp] != nil)
        XCTAssertTrue(errorMessage[Constants.Metadata.Logger.level] == "ERROR")

        let fatalMessage = jsonDict[4]
        XCTAssertTrue(fatalMessage[Constants.Metadata.Logger.message] == "StephenColbert")
        XCTAssertTrue(fatalMessage[Constants.Metadata.Logger.package] == fakePKG)
        XCTAssertTrue(fatalMessage[Constants.Metadata.Logger.timestamp] != nil)
    }
    
    
    func testLogWithNone(){
        let fakePKG = "MYPKG"
        let pathToFile = BMSLogger.logsDocumentPath + Constants.File.Logger.logs
        
        do {
            try NSFileManager().removeItemAtPath(pathToFile)
        } catch {
            
        }
        
        let loggerInstance = Logger.logger(forName: fakePKG)
        Logger.logStoreEnabled = true
        Logger.logLevelFilter = LogLevel.None
        
        loggerInstance.debug("Hello world")
        loggerInstance.info("1242342342343243242342")
        loggerInstance.warn("Str: heyoooooo")
        loggerInstance.error("1 2 3 4")
        loggerInstance.fatal("StephenColbert")
        
        XCTAssertFalse(NSFileManager().fileExistsAtPath(pathToFile))
    }
    
    
    func testIncorrectLogLevel(){
        let fakePKG = "MYPKG"
        let pathToFile = BMSLogger.logsDocumentPath + Constants.File.Logger.logs
        
        do {
            try NSFileManager().removeItemAtPath(pathToFile)
        } catch {
            
        }
        
        let loggerInstance = Logger.logger(forName: fakePKG)
        Logger.logStoreEnabled = true
        Logger.logLevelFilter = LogLevel.Fatal
        
        loggerInstance.debug("Hello world")
        loggerInstance.info("1242342342343243242342")
        loggerInstance.warn("Str: heyoooooo")
        loggerInstance.error("1 2 3 4")
        
        let fileExists = NSFileManager().fileExistsAtPath(pathToFile)
        
        XCTAssertFalse(fileExists)
    }
    
    
    func testDisableLogging(){
        let fakePKG = "MYPKG"
        let pathToFile = BMSLogger.logsDocumentPath + Constants.File.Logger.logs
        
        do {
            try NSFileManager().removeItemAtPath(pathToFile)
        } catch {
            
        }
        
        let loggerInstance = Logger.logger(forName: fakePKG)
        Logger.logStoreEnabled = false
        Logger.logLevelFilter = LogLevel.Debug
        
        loggerInstance.debug("Hello world")
        loggerInstance.info("1242342342343243242342")
        loggerInstance.warn("Str: heyoooooo")
        loggerInstance.error("1 2 3 4")
        loggerInstance.fatal("StephenColbert")
        
        let fileExists = NSFileManager().fileExistsAtPath(pathToFile)
        
        XCTAssertFalse(fileExists)
    }
    
    
    func testLogException(){
        let pathToFile = BMSLogger.logsDocumentPath + Constants.File.Logger.logs
        
        do {
            try NSFileManager().removeItemAtPath(pathToFile)
        } catch {
            
        }
        
        let e = NSException(name:"crashApp", reason:"No reason at all just doing it for fun", userInfo:["user":"nana"])
        
        BMSLogger.logException(e)
        
        guard let formattedContents = BMSLoggerTests.getFileContents(pathToFile) else {
            XCTFail()
            return
        }
        let fileContents = "[\(formattedContents)]"
        let reason = e.reason!
        let errorMessage = "Uncaught Exception: \(e.name)." + " Reason: \(reason)."
        let logDict : NSData = fileContents.dataUsingEncoding(NSUTF8StringEncoding)!
        guard let jsonDict = BMSLoggerTests.convertLogsToJson(logDict) else {
            XCTFail()
            return
        }
        
        let exception = jsonDict[0]
        XCTAssertTrue(exception[Constants.Metadata.Logger.message] == errorMessage)
        XCTAssertTrue(exception[Constants.Metadata.Logger.package] == Constants.Package.logger)
        XCTAssertTrue(exception[Constants.Metadata.Logger.timestamp] != nil)
        XCTAssertTrue(exception[Constants.Metadata.Logger.level] == "FATAL")
    }
    
    
    
    // MARK: - Writing logs to file
    
    func testGetFilesForLogLevel(){
        let pathToLoggerFile = BMSLogger.logsDocumentPath + Constants.File.Logger.logs
        let pathToAnalyticsFile = BMSLogger.logsDocumentPath + Constants.File.Analytics.logs
        let pathToLoggerFileOverflow = BMSLogger.logsDocumentPath + Constants.File.Logger.overflowLogs
        let pathToAnalyticsFileOverflow = BMSLogger.logsDocumentPath + Constants.File.Analytics.overflowLogs
        
        var (logFile, logOverflowFile, fileDispatchQueue) = BMSLogger.getFilesForLogLevel(LogLevel.Debug)
        
        XCTAssertTrue(logFile == pathToLoggerFile)
        XCTAssertTrue(logOverflowFile == pathToLoggerFileOverflow)
        XCTAssertNotNil(fileDispatchQueue)
        
        (logFile, logOverflowFile, fileDispatchQueue) = BMSLogger.getFilesForLogLevel(LogLevel.Error)
        
        XCTAssertTrue(logFile == pathToLoggerFile)
        XCTAssertTrue(logOverflowFile == pathToLoggerFileOverflow)
        XCTAssertNotNil(fileDispatchQueue)
        
        (logFile, logOverflowFile, fileDispatchQueue) = BMSLogger.getFilesForLogLevel(LogLevel.Fatal)
        
        XCTAssertTrue(logFile == pathToLoggerFile)
        XCTAssertTrue(logOverflowFile == pathToLoggerFileOverflow)
        XCTAssertNotNil(fileDispatchQueue)
        
        (logFile, logOverflowFile, fileDispatchQueue) = BMSLogger.getFilesForLogLevel(LogLevel.Info)
        
        XCTAssertTrue(logFile == pathToLoggerFile)
        XCTAssertTrue(logOverflowFile == pathToLoggerFileOverflow)
        XCTAssertNotNil(fileDispatchQueue)
        
        (logFile, logOverflowFile, fileDispatchQueue) = BMSLogger.getFilesForLogLevel(LogLevel.Error)
        
        XCTAssertTrue(logFile == pathToLoggerFile)
        XCTAssertTrue(logOverflowFile == pathToLoggerFileOverflow)
        XCTAssertNotNil(fileDispatchQueue)
        
        (logFile, logOverflowFile, fileDispatchQueue) = BMSLogger.getFilesForLogLevel(LogLevel.Analytics)
        
        XCTAssertTrue(logFile == pathToAnalyticsFile)
        XCTAssertTrue(logOverflowFile == pathToAnalyticsFileOverflow)
        XCTAssertNotNil(fileDispatchQueue)
    }
    
    
    func testGetLogs(){
        let fakePKG = "MYPKG"
        let pathToFile = BMSLogger.logsDocumentPath + Constants.File.Logger.logs
        let pathToBuffer = BMSLogger.logsDocumentPath + Constants.File.Logger.outboundLogs
        
        do {
            try NSFileManager().removeItemAtPath(pathToFile)
            
        } catch {
            
        }
        
        do {
            try NSFileManager().removeItemAtPath(pathToBuffer)
            
        } catch {
            
        }
        
        let loggerInstance = Logger.logger(forName: fakePKG)
        Logger.logStoreEnabled = true
        Logger.logLevelFilter = LogLevel.Debug
        
        loggerInstance.debug("Hello world")
        loggerInstance.info("1242342342343243242342")
        loggerInstance.warn("Str: heyoooooo")
        loggerInstance.error("1 2 3 4")
        loggerInstance.fatal("StephenColbert")
        
        guard let logs: String = BMSLoggerTests.getLogs(LogFileType.LOGGER) else {
            XCTFail()
            return
        }
        
        XCTAssertTrue(NSFileManager().fileExistsAtPath(pathToBuffer))
        
        let fileContents = "[\(logs)]"
        
        let logDict : NSData = fileContents.dataUsingEncoding(NSUTF8StringEncoding)!
        guard let jsonDict = BMSLoggerTests.convertLogsToJson(logDict) else {
            XCTFail()
            return
        }
        
        let debugMessage = jsonDict[0]
        XCTAssertTrue(debugMessage[Constants.Metadata.Logger.message] == "Hello world")
        XCTAssertTrue(debugMessage[Constants.Metadata.Logger.package] == fakePKG)
        XCTAssertTrue(debugMessage[Constants.Metadata.Logger.timestamp] != nil)
        XCTAssertTrue(debugMessage[Constants.Metadata.Logger.level] == "DEBUG")
        
        let infoMessage = jsonDict[1]
        XCTAssertTrue(infoMessage[Constants.Metadata.Logger.message] == "1242342342343243242342")
        XCTAssertTrue(infoMessage[Constants.Metadata.Logger.package] == fakePKG)
        XCTAssertTrue(infoMessage[Constants.Metadata.Logger.timestamp] != nil)
        XCTAssertTrue(infoMessage[Constants.Metadata.Logger.level] == "INFO")
        
        let warnMessage = jsonDict[2]
        XCTAssertTrue(warnMessage[Constants.Metadata.Logger.message] == "Str: heyoooooo")
        XCTAssertTrue(warnMessage[Constants.Metadata.Logger.package] == fakePKG)
        XCTAssertTrue(warnMessage[Constants.Metadata.Logger.timestamp] != nil)
        XCTAssertTrue(warnMessage[Constants.Metadata.Logger.level] == "WARN")
        
        let errorMessage = jsonDict[3]
        XCTAssertTrue(errorMessage[Constants.Metadata.Logger.message] == "1 2 3 4")
        XCTAssertTrue(errorMessage[Constants.Metadata.Logger.package] == fakePKG)
        XCTAssertTrue(errorMessage[Constants.Metadata.Logger.timestamp] != nil)
        XCTAssertTrue(errorMessage[Constants.Metadata.Logger.level] == "ERROR")
        
        let fatalMessage = jsonDict[4]
        XCTAssertTrue(fatalMessage[Constants.Metadata.Logger.message] == "StephenColbert")
        XCTAssertTrue(fatalMessage[Constants.Metadata.Logger.package] == fakePKG)
        XCTAssertTrue(fatalMessage[Constants.Metadata.Logger.timestamp] != nil)
        XCTAssertTrue(fatalMessage[Constants.Metadata.Logger.level] == "FATAL")
    }
    
    
    func testGetLogWithAnalytics(){
        let pathToFile = BMSLogger.logsDocumentPath + Constants.File.Analytics.logs
        let pathToBuffer = BMSLogger.logsDocumentPath + Constants.File.Analytics.outboundLogs
        
        do {
            try NSFileManager().removeItemAtPath(pathToFile)
            
        } catch {
            
        }
        
        do {
            try NSFileManager().removeItemAtPath(pathToBuffer)
            
        } catch {
            
        }
        
        Analytics.enabled = true
        Logger.logStoreEnabled = true
        Logger.logLevelFilter = LogLevel.Analytics
        let meta = ["hello": 1]
        
        Analytics.log(meta)
        
        guard let logs: String = BMSLoggerTests.getLogs(LogFileType.ANALYTICS) else {
            XCTFail()
            return
        }
        
        let bufferFile = NSFileManager().fileExistsAtPath(pathToBuffer)
        
        XCTAssertTrue(bufferFile)
        
        let fileContents = "[\(logs)]"
        
        let logDict : NSData = fileContents.dataUsingEncoding(NSUTF8StringEncoding)!
        guard let jsonDict = BMSLoggerTests.convertLogsToJson(logDict) else {
            XCTFail()
            return
        }
        
        let analyticsMessage = jsonDict[0]
        XCTAssertTrue(analyticsMessage[Constants.Metadata.Logger.message] == "")
        XCTAssertTrue(analyticsMessage[Constants.Metadata.Logger.package] == Logger.bmsLoggerPrefix + "analytics")
        XCTAssertTrue(analyticsMessage[Constants.Metadata.Logger.timestamp] != nil)
        XCTAssertTrue(analyticsMessage[Constants.Metadata.Logger.level] == "ANALYTICS")
        XCTAssertTrue(analyticsMessage[Constants.Metadata.Logger.metadata] == meta)
    }
    
    
    func testOverFlowLogging(){
        let fakePKG = "MYPKG"
        let pathToFile = BMSLogger.logsDocumentPath + Constants.File.Logger.logs
        let pathToOverflow = BMSLogger.logsDocumentPath + Constants.File.Logger.overflowLogs
        
        do {
            try NSFileManager().removeItemAtPath(pathToFile)
            
        } catch {
            
        }
        
        do {
            try NSFileManager().removeItemAtPath(pathToOverflow)
        } catch {
            
        }
        
        let bundle = NSBundle(forClass: self.dynamicType)
        let path = bundle.pathForResource("LargeData", ofType: "txt")
        
        let loggerInstance = Logger.logger(forName: fakePKG)
        guard let largeData = BMSLoggerTests.getFileContents(path!) else {
            XCTFail()
            return
        }
        
        Logger.logStoreEnabled = true
        Logger.sdkDebugLoggingEnabled = false
        Logger.logLevelFilter = LogLevel.Debug
        
        loggerInstance.debug(largeData)
        loggerInstance.info("1242342342343243242342")
        loggerInstance.warn("Str: heyoooooo")
        loggerInstance.error("1 2 3 4")
        loggerInstance.fatal("StephenColbert")
        
        XCTAssertTrue(NSFileManager().fileExistsAtPath(pathToOverflow))
        
        guard let formattedContents = BMSLoggerTests.getFileContents(pathToFile) else {
            XCTFail()
            return
        }
        var fileContents = "[\(formattedContents)]"
        var logDict : NSData = fileContents.dataUsingEncoding(NSUTF8StringEncoding)!
        guard let jsonDict = BMSLoggerTests.convertLogsToJson(logDict) else {
            XCTFail()
            return
        }
        
        let infoMessage = jsonDict[0]
        XCTAssertTrue(infoMessage[Constants.Metadata.Logger.message] == "1242342342343243242342")
        XCTAssertTrue(infoMessage[Constants.Metadata.Logger.package] == fakePKG)
        XCTAssertTrue(infoMessage[Constants.Metadata.Logger.timestamp] != nil)
        XCTAssertTrue(infoMessage[Constants.Metadata.Logger.level] == "INFO")
        
        let warnMessage = jsonDict[1]
        XCTAssertTrue(warnMessage[Constants.Metadata.Logger.message] == "Str: heyoooooo")
        XCTAssertTrue(warnMessage[Constants.Metadata.Logger.package] == fakePKG)
        XCTAssertTrue(warnMessage[Constants.Metadata.Logger.timestamp] != nil)
        XCTAssertTrue(warnMessage[Constants.Metadata.Logger.level] == "WARN")
        
        let errorMessage = jsonDict[2]
        XCTAssertTrue(errorMessage[Constants.Metadata.Logger.message] == "1 2 3 4")
        XCTAssertTrue(errorMessage[Constants.Metadata.Logger.package] == fakePKG)
        XCTAssertTrue(errorMessage[Constants.Metadata.Logger.timestamp] != nil)
        XCTAssertTrue(errorMessage[Constants.Metadata.Logger.level] == "ERROR")
        
        let fatalMessage = jsonDict[3]
        XCTAssertTrue(fatalMessage[Constants.Metadata.Logger.message] == "StephenColbert")
        XCTAssertTrue(fatalMessage[Constants.Metadata.Logger.package] == fakePKG)
        XCTAssertTrue(fatalMessage[Constants.Metadata.Logger.timestamp] != nil)
        XCTAssertTrue(fatalMessage[Constants.Metadata.Logger.level] == "FATAL")
        
        guard let newFormattedContents = BMSLoggerTests.getFileContents(pathToOverflow) else {
            XCTFail()
            return
        }
        fileContents = "[\(newFormattedContents)]"
        logDict  = fileContents.dataUsingEncoding(NSUTF8StringEncoding)!
        guard let newJsonDict = BMSLoggerTests.convertLogsToJson(logDict) else {
            XCTFail()
            return
        }
        
        
        let overflowMessage = newJsonDict[0]
        XCTAssertTrue(overflowMessage[Constants.Metadata.Logger.message] == largeData)
        XCTAssertTrue(overflowMessage[Constants.Metadata.Logger.package] == fakePKG)
        XCTAssertTrue(overflowMessage[Constants.Metadata.Logger.timestamp] != nil)
        XCTAssertTrue(overflowMessage[Constants.Metadata.Logger.level] == "DEBUG")
    }
    
    
    func testExistingOverflowFile(){
        let fakePKG = "MYPKG"
        let pathToFile = BMSLogger.logsDocumentPath + Constants.File.Logger.logs
        let pathToOverflow = BMSLogger.logsDocumentPath + Constants.File.Logger.overflowLogs
        
        do {
            try NSFileManager().removeItemAtPath(pathToFile)
            
        } catch {
            
        }
        
        do {
            try NSFileManager().removeItemAtPath(pathToOverflow)
        } catch {
            
        }
        
        let bundle = NSBundle(forClass: self.dynamicType)
        let path = bundle.pathForResource("LargeData", ofType: "txt")
        
        guard let largeData = BMSLoggerTests.getFileContents(path!) else {
            XCTFail()
            return
        }
        
        
        let loggerInstance = Logger.logger(forName: fakePKG)
        Logger.logStoreEnabled = true
        Logger.sdkDebugLoggingEnabled = false
        Logger.logLevelFilter = LogLevel.Debug
        
        loggerInstance.debug(largeData)
        loggerInstance.info(largeData)
        loggerInstance.warn(largeData)
        loggerInstance.error(largeData)
        loggerInstance.fatal(largeData)
        
        
        XCTAssertTrue(NSFileManager().fileExistsAtPath(pathToOverflow))
        
        guard let formattedContents = BMSLoggerTests.getFileContents(pathToOverflow) else {
            XCTFail()
            return
        }
        
        
        var fileContents = "[\(formattedContents)]"
        var logDict : NSData = fileContents.dataUsingEncoding(NSUTF8StringEncoding)!
        guard let jsonDict = BMSLoggerTests.convertLogsToJson(logDict) else {
            XCTFail()
            return
        }
        
        XCTAssertTrue(jsonDict.count == 1)
        
        loggerInstance.debug(largeData)
        
        
        guard let newFormattedContents = BMSLoggerTests.getFileContents(pathToOverflow) else {
            XCTFail()
            return
        }
        fileContents = "[\(newFormattedContents)]"
        logDict  = fileContents.dataUsingEncoding(NSUTF8StringEncoding)!
        guard let newJsonDict = BMSLoggerTests.convertLogsToJson(logDict) else {
            XCTFail()
            return
        }
        
        XCTAssertTrue(newJsonDict.count == 1)
    }
    
    
    
    // MARK: - Sending logs
    
    func testLogSendRequest(){
        let fakePKG = "MYPKG"
        let API_KEY = "apikey"
        let APP_NAME = "myApp"
        let pathToFile = BMSLogger.logsDocumentPath + Constants.File.Logger.logs
        let pathToBuffer = BMSLogger.logsDocumentPath + Constants.File.Logger.outboundLogs
        let bmsClient = BMSClient.sharedInstance
        bmsClient.initializeWithBluemixAppRoute("bluemix", bluemixAppGUID: "appID1", bluemixRegion: BMSClient.REGION_US_SOUTH)
        Analytics.initializeWithAppName("testAppName", apiKey: "testApiKey")
        let url = "https://" + Constants.AnalyticsServer.hostName + BMSClient.REGION_US_SOUTH + Constants.AnalyticsServer.uploadPath
        
        Analytics.initializeWithAppName(APP_NAME, apiKey: API_KEY)
        
        let headers = ["Content-Type": "text/plain", Constants.analyticsApiKey: API_KEY, Constants.analyticsP30ApiKey: "appID1"]
        
        do {
            try NSFileManager().removeItemAtPath(pathToFile)
            
        } catch {
            
        }
        
        do {
            try NSFileManager().removeItemAtPath(pathToBuffer)
            
        } catch {
            
        }
        
        let loggerInstance = Logger.logger(forName: fakePKG)
        Logger.logStoreEnabled = true
        Logger.logLevelFilter = LogLevel.Debug
        
        loggerInstance.debug("Hello world")
        loggerInstance.info("1242342342343243242342")
        loggerInstance.warn("Str: heyoooooo")
        loggerInstance.error("1 2 3 4")
        loggerInstance.fatal("StephenColbert")
        
        let request = BMSLogger.buildLogSendRequest() { (response, error) -> Void in
            }!
        
        XCTAssertTrue(request.resourceUrl == url)
        XCTAssertTrue(request.headers == headers)
        XCTAssertNil(request.queryParameters)
        XCTAssertTrue(request.httpMethod == HttpMethod.POST)
    }
    
    
    func testLogSendFailWithEmptyAPIKey(){
        let fakePKG = Constants.Package.logger
        let pathToFile = BMSLogger.logsDocumentPath + Constants.File.Logger.logs
        let pathToBuffer = BMSLogger.logsDocumentPath + Constants.File.Logger.outboundLogs
        let bmsClient = BMSClient.sharedInstance
        bmsClient.initializeWithBluemixAppRoute("bluemix", bluemixAppGUID: "appID1", bluemixRegion: BMSClient.REGION_US_SOUTH)
        Analytics.initializeWithAppName("testAppName", apiKey: "")
        
        do {
            try NSFileManager().removeItemAtPath(pathToFile)
            
        } catch {
            
        }
        
        do {
            try NSFileManager().removeItemAtPath(pathToBuffer)
            
        } catch {
            
        }
        
        let loggerInstance = Logger.logger(forName: fakePKG)
        Logger.logStoreEnabled = true
        Logger.logLevelFilter = LogLevel.Debug
        
        loggerInstance.debug("Hello world")
        loggerInstance.info("1242342342343243242342")
        loggerInstance.warn("Str: heyoooooo")
        loggerInstance.error("1 2 3 4")
        loggerInstance.fatal("StephenColbert")
        
        guard let _ = BMSLoggerTests.getLogs(LogFileType.LOGGER) else {
            XCTFail()
            return
        }
        
        XCTAssertTrue(NSFileManager().fileExistsAtPath(pathToBuffer))
        
        let request = BMSLogger.buildLogSendRequest() { (response, error) -> Void in
        }
        
        XCTAssertNil(request)
        
        guard let formattedContents = BMSLoggerTests.getFileContents(pathToFile) else {
            XCTFail()
            return
        }
        let fileContents = "[\(formattedContents)]"
        let logDict  = fileContents.dataUsingEncoding(NSUTF8StringEncoding)!
        
        guard let newJsonDict = BMSLoggerTests.convertLogsToJson(logDict) else {
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
        Analytics.initializeWithAppName("testAppName", apiKey: "1234")
        
        let bmsRequest = BMSLogger.buildLogSendRequest() { (response, error) -> Void in
        }
        
        XCTAssertNotNil(bmsRequest)
        XCTAssertTrue(bmsRequest is Request)
        
        let bmsLogUploadUrl = "https://" + Constants.AnalyticsServer.hostName + ".ng.bluemix.net" + Constants.AnalyticsServer.uploadPath
        XCTAssertEqual(bmsRequest!.resourceUrl, bmsLogUploadUrl)
    }
    
    
    func testPreventSimultaneousSendRequests() {
        
        let bmsClient = BMSClient.sharedInstance
        bmsClient.initializeWithBluemixAppRoute("bluemix", bluemixAppGUID: "appID1", bluemixRegion: BMSClient.REGION_US_SOUTH)
        Analytics.initializeWithAppName("testAppName", apiKey: "1234")
        
        XCTAssertFalse(Logger.currentlySendingLoggerLogs)
        XCTAssertFalse(Logger.currentlySendingAnalyticsLogs)
        
        let loggerSendFinished = expectationWithDescription("Logger send complete")
        let analyticsSendFinished = expectationWithDescription("Analytics send complete")
        
        Logger.send { (_: Response?, _: NSError?) in
            XCTAssertFalse(Logger.currentlySendingLoggerLogs)
            loggerSendFinished.fulfill()
        }
        Analytics.send { (_: Response?, _: NSError?) in
            XCTAssertFalse(Logger.currentlySendingAnalyticsLogs)
            analyticsSendFinished.fulfill()
        }
        
        XCTAssertTrue(Logger.currentlySendingLoggerLogs)
        XCTAssertTrue(Logger.currentlySendingAnalyticsLogs)
        
        waitForExpectationsWithTimeout(10.0) { (error: NSError?) -> Void in
            if error != nil {
                XCTFail("Expectation failed with error: \(error)")
            }
        }
    }
    
    
    func testReturnInitializationError(){
        // BMSClient initialization
        BMSLogger.returnInitializationError("BMSClient", missingValue:"test") { (response, error) -> Void in
            XCTAssertNil(response)
            XCTAssertNotNil(error)
            XCTAssertEqual(error!.code, BMSCoreError.ClientNotInitialized.rawValue)
            XCTAssertEqual(error!.domain, BMSAnalyticsError.domain)
        }
        
        // Analytics initialization
        BMSLogger.returnInitializationError("Analytics", missingValue:"test") { (response, error) -> Void in
            XCTAssertNil(response)
            XCTAssertNotNil(error)
            XCTAssertEqual(error!.code, BMSAnalyticsError.AnalyticsNotInitialized.rawValue)
            XCTAssertEqual(error!.domain, BMSAnalyticsError.domain)
        }
        
        // Unknown initialization
        BMSLogger.returnInitializationError("Unknown class", missingValue:"test") { (response, error) -> Void in
            XCTAssertNil(response)
            XCTAssertNotNil(error)
            XCTAssertEqual(error!.code, -1)
            XCTAssertEqual(error!.domain, BMSAnalyticsError.domain)
        }
    }
    
    
    func testDeleteFileFail(){
        let fakePKG = "bmssdk.logger"
        let pathToFile = BMSLogger.logsDocumentPath + Constants.File.Logger.logs
        let pathToBuffer = BMSLogger.logsDocumentPath + Constants.File.Logger.outboundLogs
        do {
            try NSFileManager().removeItemAtPath(pathToFile)
            
        } catch {
            
        }
        
        do {
            try NSFileManager().removeItemAtPath(pathToBuffer)
            
        } catch {
            
        }
        
        let loggerInstance = Logger.logger(forName: fakePKG)
        Logger.logStoreEnabled = true
        Logger.logLevelFilter = LogLevel.Debug
        
        loggerInstance.debug("Hello world")
        
        guard let logs: String = BMSLoggerTests.getLogs(LogFileType.LOGGER) else {
            XCTFail()
            return
        }
        
        XCTAssertTrue(NSFileManager().fileExistsAtPath(pathToBuffer))
        
        XCTAssertNotNil(logs)
        
        do {
            try NSFileManager().removeItemAtPath(pathToBuffer)
        } catch {
            
        }
        
        BMSLogger.deleteFile(Constants.File.Logger.outboundLogs)
        
        XCTAssertFalse(NSFileManager().fileExistsAtPath(pathToBuffer))
    }
    
    
    func testDeleteFile(){
        let fakePKG = "MYPKG"
        let pathToFile = BMSLogger.logsDocumentPath + Constants.File.Logger.logs
        let pathToBuffer = BMSLogger.logsDocumentPath + Constants.File.Logger.outboundLogs
        
        do {
            try NSFileManager().removeItemAtPath(pathToFile)
            
        } catch {
            
        }
        
        do {
            try NSFileManager().removeItemAtPath(pathToBuffer)
            
        } catch {
            
        }
        
        let loggerInstance = Logger.logger(forName: fakePKG)
        Logger.logStoreEnabled = true
        Logger.logLevelFilter = LogLevel.Debug
        
        loggerInstance.debug("Hello world")
        loggerInstance.info("1242342342343243242342")
        loggerInstance.warn("Str: heyoooooo")
        loggerInstance.error("1 2 3 4")
        loggerInstance.fatal("StephenColbert")
        
        guard let _ = BMSLoggerTests.getLogs(LogFileType.LOGGER) else {
            XCTFail()
            return
        }
        
        XCTAssertTrue(NSFileManager().fileExistsAtPath(pathToBuffer))
        
        BMSLogger.deleteFile(Constants.File.Logger.outboundLogs)
        
        XCTAssertFalse(NSFileManager().fileExistsAtPath(pathToBuffer))
    }
    
    
    func testExtractFileNameFromPath() {
        
        let logFile1 = "some/path/to/file.txt"
        let logFile2 = "path//with///extra///slashes.log.txt"
        let logFile3 = "/////"
        let logFile4 = ""
        let logFile5 = "sdajfasldkfjalksfdj"
        
        
        XCTAssertEqual(BMSLogger.extractFileNameFromPath(logFile1), "file.txt")
        XCTAssertEqual(BMSLogger.extractFileNameFromPath(logFile2), "slashes.log.txt")
        XCTAssertEqual(BMSLogger.extractFileNameFromPath(logFile3), Constants.File.unknown)
        XCTAssertEqual(BMSLogger.extractFileNameFromPath(logFile4), Constants.File.unknown)
        XCTAssertEqual(BMSLogger.extractFileNameFromPath(logFile5), Constants.File.unknown)
    }
    
    
    
    // MARK: - Helpers
    
    static func getFileContents(pathToFile: String) -> String? {
        do {
            return try String(contentsOfFile: pathToFile, encoding: NSUTF8StringEncoding)
        }
        catch {
            return nil
        }
    }
    
    static func convertLogsToJson(logDict: NSData) -> AnyObject? {
        do {
            return try NSJSONSerialization.JSONObjectWithData(logDict, options:NSJSONReadingOptions.MutableContainers)
        }
        catch {
            return nil
        }
    }
    
    static func getLogs(logFile: LogFileType) -> String? {
        do {
            switch logFile {
            case .LOGGER:
                return try BMSLogger.getLogs(fileName: Constants.File.Logger.logs, overflowFileName: Constants.File.Logger.overflowLogs, bufferFileName: Constants.File.Logger.outboundLogs)
            case .ANALYTICS:
                return try BMSLogger.getLogs(fileName: Constants.File.Analytics.logs, overflowFileName: Constants.File.Analytics.overflowLogs, bufferFileName: Constants.File.Analytics.outboundLogs)
            }
        }
        catch {
            return nil
        }
    }

}


enum LogFileType: String {
    case LOGGER
    case ANALYTICS
}
