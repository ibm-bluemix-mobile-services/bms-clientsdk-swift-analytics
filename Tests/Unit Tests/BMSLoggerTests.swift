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



// MARK: - Swift 3

#if swift(>=3.0)
    


class BMSLoggerTests: XCTestCase {

    
    override func tearDown() {
        BMSClient.sharedInstance.initialize(bluemixRegion: "")
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

    
    func testisLogStorageEnabled(){
        
        let capture1 = Logger.isLogStorageEnabled
        XCTAssertTrue(capture1, "should default to true");

        Logger.isLogStorageEnabled = false
    
        let capture2 = Logger.isLogStorageEnabled
        XCTAssertFalse(capture2)
    }
    
    
    func testNoInternalLogging(){
        let fakePKG = Constants.Package.logger
        let pathToFile = BMSLogger.logsDocumentPath + Constants.File.Logger.logs
        
        do {
            try FileManager().removeItem(atPath: pathToFile)
        } catch {
            print("Could not delete " + pathToFile)
        }
        
        let loggerInstance = Logger.logger(name: fakePKG)
        Logger.isLogStorageEnabled = true
        Logger.logLevelFilter = LogLevel.debug
        Logger.isInternalDebugLoggingEnabled = false
        
        loggerInstance.debug(message: "Hello world")
        loggerInstance.info(message: "1242342342343243242342")
        loggerInstance.warn(message: "Str: heyoooooo")
        loggerInstance.error(message: "1 2 3 4")
        loggerInstance.fatal(message: "StephenColbert")

        guard let formattedContents = BMSLoggerTests.getContents(ofFile: pathToFile) else {
            XCTFail()
            return
        }
        let fileContents = "[\(formattedContents)]"
        let logDict = fileContents.data(using: .utf8)!
        guard let jsonDict = BMSLoggerTests.convertToJson(logs: logDict) else {
            XCTFail()
            return
        }
        
        let debugMessage = jsonDict[0]
        XCTAssertEqual(debugMessage[Constants.Metadata.Logger.message] as? String, "Hello world")
        XCTAssertEqual(debugMessage[Constants.Metadata.Logger.package] as? String, fakePKG)
        XCTAssertNotNil(debugMessage[Constants.Metadata.Logger.timestamp])
        XCTAssertEqual(debugMessage[Constants.Metadata.Logger.level] as? String, "DEBUG")
        
        let infoMessage = jsonDict[1]
        XCTAssertEqual(infoMessage[Constants.Metadata.Logger.message] as? String, "1242342342343243242342")
        XCTAssertEqual(infoMessage[Constants.Metadata.Logger.package] as? String, fakePKG)
        XCTAssertNotNil(infoMessage[Constants.Metadata.Logger.timestamp])
        XCTAssertEqual(infoMessage[Constants.Metadata.Logger.level] as? String, "INFO")
        
        let warnMessage = jsonDict[2]
        XCTAssertEqual(warnMessage[Constants.Metadata.Logger.message] as? String, "Str: heyoooooo")
        XCTAssertEqual(warnMessage[Constants.Metadata.Logger.package] as? String, fakePKG)
        XCTAssertNotNil(warnMessage[Constants.Metadata.Logger.timestamp])
        XCTAssertEqual(warnMessage[Constants.Metadata.Logger.level] as? String, "WARN")
        
        let errorMessage = jsonDict[3]
        XCTAssertEqual(errorMessage[Constants.Metadata.Logger.message] as? String, "1 2 3 4")
        XCTAssertEqual(errorMessage[Constants.Metadata.Logger.package] as? String, fakePKG)
        XCTAssertNotNil(errorMessage[Constants.Metadata.Logger.timestamp])
        XCTAssertEqual(errorMessage[Constants.Metadata.Logger.level] as? String, "ERROR")
        
        let fatalMessage = jsonDict[4]
        XCTAssertEqual(fatalMessage[Constants.Metadata.Logger.message] as? String, "StephenColbert")
        XCTAssertEqual(fatalMessage[Constants.Metadata.Logger.package] as? String, fakePKG)
        XCTAssertNotNil(fatalMessage[Constants.Metadata.Logger.timestamp])
    }

    
    func testLogMethods(){
        let fakePKG = "MYPKG"
        let pathToFile = BMSLogger.logsDocumentPath + Constants.File.Logger.logs
        
        do {
            try FileManager().removeItem(atPath: pathToFile)
        } catch {
            
        }
        
        let loggerInstance = Logger.logger(name: fakePKG)
        Logger.isLogStorageEnabled = true
        Logger.logLevelFilter = LogLevel.debug

        loggerInstance.debug(message: "Hello world")
        loggerInstance.info(message: "1242342342343243242342")
        loggerInstance.warn(message: "Str: heyoooooo")
        loggerInstance.error(message: "1 2 3 4")
        loggerInstance.fatal(message: "StephenColbert")
    
        
        guard let formattedContents = BMSLoggerTests.getContents(ofFile: pathToFile) else {
            XCTFail()
            return
        }
        let fileContents = "[\(formattedContents)]"
        let logDict = fileContents.data(using: .utf8)!
        guard let jsonDict = BMSLoggerTests.convertToJson(logs: logDict) else {
            XCTFail()
            return
        }

        let debugMessage = jsonDict[0]
        XCTAssertEqual(debugMessage[Constants.Metadata.Logger.message] as? String, "Hello world")
        XCTAssertEqual(debugMessage[Constants.Metadata.Logger.package] as? String, fakePKG)
        XCTAssertNotNil(debugMessage[Constants.Metadata.Logger.timestamp])
        XCTAssertEqual(debugMessage[Constants.Metadata.Logger.level] as? String, "DEBUG")

        let infoMessage = jsonDict[1]
        XCTAssertEqual(infoMessage[Constants.Metadata.Logger.message] as? String, "1242342342343243242342")
        XCTAssertEqual(infoMessage[Constants.Metadata.Logger.package] as? String, fakePKG)
        XCTAssertNotNil(infoMessage[Constants.Metadata.Logger.timestamp])
        XCTAssertEqual(infoMessage[Constants.Metadata.Logger.level] as? String, "INFO")

        let warnMessage = jsonDict[2]
        XCTAssertEqual(warnMessage[Constants.Metadata.Logger.message] as? String, "Str: heyoooooo")
        XCTAssertEqual(warnMessage[Constants.Metadata.Logger.package] as? String, fakePKG)
        XCTAssertNotNil(warnMessage[Constants.Metadata.Logger.timestamp])
        XCTAssertEqual(warnMessage[Constants.Metadata.Logger.level] as? String, "WARN")

        let errorMessage = jsonDict[3]
        XCTAssertEqual(errorMessage[Constants.Metadata.Logger.message] as? String, "1 2 3 4")
        XCTAssertEqual(errorMessage[Constants.Metadata.Logger.package] as? String, fakePKG)
        XCTAssertNotNil(errorMessage[Constants.Metadata.Logger.timestamp])
        XCTAssertEqual(errorMessage[Constants.Metadata.Logger.level] as? String, "ERROR")

        let fatalMessage = jsonDict[4]
        XCTAssertEqual(fatalMessage[Constants.Metadata.Logger.message] as? String, "StephenColbert")
        XCTAssertEqual(fatalMessage[Constants.Metadata.Logger.package] as? String, fakePKG)
        XCTAssertNotNil(fatalMessage[Constants.Metadata.Logger.timestamp])
    }
    
    
    func testLogWithNone(){
        let fakePKG = "MYPKG"
        let pathToFile = BMSLogger.logsDocumentPath + Constants.File.Logger.logs
        
        do {
            try FileManager().removeItem(atPath: pathToFile)
        } catch {
            
        }
        
        let loggerInstance = Logger.logger(name: fakePKG)
        Logger.isLogStorageEnabled = true
        Logger.logLevelFilter = LogLevel.none
        
        loggerInstance.debug(message: "Hello world")
        loggerInstance.info(message: "1242342342343243242342")
        loggerInstance.warn(message: "Str: heyoooooo")
        loggerInstance.error(message: "1 2 3 4")
        loggerInstance.fatal(message: "StephenColbert")
        
        XCTAssertFalse(FileManager().fileExists(atPath: pathToFile))
    }
    
    
    func testIncorrectLogLevel(){
        let fakePKG = "MYPKG"
        let pathToFile = BMSLogger.logsDocumentPath + Constants.File.Logger.logs
        
        do {
            try FileManager().removeItem(atPath: pathToFile)
        } catch {
            
        }
        
        let loggerInstance = Logger.logger(name: fakePKG)
        Logger.isLogStorageEnabled = true
        Logger.logLevelFilter = LogLevel.fatal
        
        loggerInstance.debug(message: "Hello world")
        loggerInstance.info(message: "1242342342343243242342")
        loggerInstance.warn(message: "Str: heyoooooo")
        loggerInstance.error(message: "1 2 3 4")
        
        let fileExists = FileManager().fileExists(atPath: pathToFile)
        
        XCTAssertFalse(fileExists)
    }
    
    
    func testDisableLogging(){
        let fakePKG = "MYPKG"
        let pathToFile = BMSLogger.logsDocumentPath + Constants.File.Logger.logs
        
        do {
            try FileManager().removeItem(atPath: pathToFile)
        } catch {
            
        }
        
        let loggerInstance = Logger.logger(name: fakePKG)
        Logger.isLogStorageEnabled = false
        Logger.logLevelFilter = LogLevel.debug
        
        loggerInstance.debug(message: "Hello world")
        loggerInstance.info(message: "1242342342343243242342")
        loggerInstance.warn(message: "Str: heyoooooo")
        loggerInstance.error(message: "1 2 3 4")
        loggerInstance.fatal(message: "StephenColbert")
        
        let fileExists = FileManager().fileExists(atPath: pathToFile)
        
        XCTAssertFalse(fileExists)
    }
    
    
    func testLogException() {
        
        Logger.isLogStorageEnabled = true
        
        let pathToFile = BMSLogger.logsDocumentPath + Constants.File.Logger.logs
        
        do {
            try FileManager().removeItem(atPath: pathToFile)
        } catch {
            
        }
        
        let e = NSException(name: NSExceptionName("crashApp"), reason: "No reason at all just doing it for fun", userInfo: ["user":"nana"])
        
        BMSLogger.log(exception: e)
        
        guard let formattedContents = BMSLoggerTests.getContents(ofFile: pathToFile) else {
            XCTFail()
            return
        }
        let fileContents = "[\(formattedContents)]"
        let errorMessage = e.reason
        let logDict = fileContents.data(using: .utf8)!
        guard let jsonDict = BMSLoggerTests.convertToJson(logs: logDict) else {
            XCTFail()
            return
        }
        
        let exception = jsonDict[0]
        XCTAssertEqual(exception[Constants.Metadata.Logger.message] as? String, errorMessage)
        XCTAssertEqual(exception[Constants.Metadata.Logger.package] as? String, Constants.Package.logger)
        XCTAssertNotNil(exception[Constants.Metadata.Logger.timestamp])
        XCTAssertEqual(exception[Constants.Metadata.Logger.level] as? String, "FATAL")
    }
    
    
    
    // MARK: - Writing logs to file
    
    func testGetFilesForLogLevel(){
        let pathToLoggerFile = BMSLogger.logsDocumentPath + Constants.File.Logger.logs
        let pathToAnalyticsFile = BMSLogger.logsDocumentPath + Constants.File.Analytics.logs
        let pathToLoggerFileOverflow = BMSLogger.logsDocumentPath + Constants.File.Logger.overflowLogs
        let pathToAnalyticsFileOverflow = BMSLogger.logsDocumentPath + Constants.File.Analytics.overflowLogs
        
        var (logFile, logOverflowFile, fileDispatchQueue) = BMSLogger.getFiles(for: LogLevel.debug)
        
        XCTAssertTrue(logFile == pathToLoggerFile)
        XCTAssertTrue(logOverflowFile == pathToLoggerFileOverflow)
        XCTAssertNotNil(fileDispatchQueue)
        
        (logFile, logOverflowFile, fileDispatchQueue) = BMSLogger.getFiles(for: LogLevel.error)
        
        XCTAssertTrue(logFile == pathToLoggerFile)
        XCTAssertTrue(logOverflowFile == pathToLoggerFileOverflow)
        XCTAssertNotNil(fileDispatchQueue)
        
        (logFile, logOverflowFile, fileDispatchQueue) = BMSLogger.getFiles(for: LogLevel.fatal)
        
        XCTAssertTrue(logFile == pathToLoggerFile)
        XCTAssertTrue(logOverflowFile == pathToLoggerFileOverflow)
        XCTAssertNotNil(fileDispatchQueue)
        
        (logFile, logOverflowFile, fileDispatchQueue) = BMSLogger.getFiles(for: LogLevel.info)
        
        XCTAssertTrue(logFile == pathToLoggerFile)
        XCTAssertTrue(logOverflowFile == pathToLoggerFileOverflow)
        XCTAssertNotNil(fileDispatchQueue)
        
        (logFile, logOverflowFile, fileDispatchQueue) = BMSLogger.getFiles(for: LogLevel.error)
        
        XCTAssertTrue(logFile == pathToLoggerFile)
        XCTAssertTrue(logOverflowFile == pathToLoggerFileOverflow)
        XCTAssertNotNil(fileDispatchQueue)
        
        (logFile, logOverflowFile, fileDispatchQueue) = BMSLogger.getFiles(for: LogLevel.analytics)
        
        XCTAssertTrue(logFile == pathToAnalyticsFile)
        XCTAssertTrue(logOverflowFile == pathToAnalyticsFileOverflow)
        XCTAssertNotNil(fileDispatchQueue)
    }
    
    
    func testGetLogs(){
        let fakePKG = "MYPKG"
        let pathToFile = BMSLogger.logsDocumentPath + Constants.File.Logger.logs
        let pathToBuffer = BMSLogger.logsDocumentPath + Constants.File.Logger.outboundLogs
        
        do {
            try FileManager().removeItem(atPath: pathToFile)
            
        } catch {
            
        }
        
        do {
            try FileManager().removeItem(atPath: pathToBuffer)
            
        } catch {
            
        }
        
        let loggerInstance = Logger.logger(name: fakePKG)
        Logger.isLogStorageEnabled = true
        Logger.logLevelFilter = LogLevel.debug
        
        loggerInstance.debug(message: "Hello world")
        loggerInstance.info(message: "1242342342343243242342")
        loggerInstance.warn(message: "Str: heyoooooo")
        loggerInstance.error(message: "1 2 3 4")
        loggerInstance.fatal(message: "StephenColbert")
        
        guard let logs: String = BMSLoggerTests.getLogs(fromFile: LogFileType.LOGGER) else {
            XCTFail()
            return
        }
        
        XCTAssertTrue(FileManager().fileExists(atPath: pathToBuffer))
        
        let fileContents = "[\(logs)]"
        
        let logDict  = fileContents.data(using: .utf8)!
        guard let jsonDict = BMSLoggerTests.convertToJson(logs: logDict) else {
            XCTFail()
            return
        }
        
        let debugMessage = jsonDict[0]
        XCTAssertEqual(debugMessage[Constants.Metadata.Logger.message] as? String, "Hello world")
        XCTAssertEqual(debugMessage[Constants.Metadata.Logger.package] as? String, fakePKG)
        XCTAssertNotNil(debugMessage[Constants.Metadata.Logger.timestamp])
        XCTAssertEqual(debugMessage[Constants.Metadata.Logger.level] as? String, "DEBUG")
        
        let infoMessage = jsonDict[1]
        XCTAssertEqual(infoMessage[Constants.Metadata.Logger.message] as? String, "1242342342343243242342")
        XCTAssertEqual(infoMessage[Constants.Metadata.Logger.package] as? String, fakePKG)
        XCTAssertNotNil(infoMessage[Constants.Metadata.Logger.timestamp])
        XCTAssertEqual(infoMessage[Constants.Metadata.Logger.level] as? String, "INFO")
        
        let warnMessage = jsonDict[2]
        XCTAssertEqual(warnMessage[Constants.Metadata.Logger.message] as? String, "Str: heyoooooo")
        XCTAssertEqual(warnMessage[Constants.Metadata.Logger.package] as? String, fakePKG)
        XCTAssertNotNil(warnMessage[Constants.Metadata.Logger.timestamp])
        XCTAssertEqual(warnMessage[Constants.Metadata.Logger.level] as? String, "WARN")
        
        let errorMessage = jsonDict[3]
        XCTAssertEqual(errorMessage[Constants.Metadata.Logger.message] as? String, "1 2 3 4")
        XCTAssertEqual(errorMessage[Constants.Metadata.Logger.package] as? String, fakePKG)
        XCTAssertNotNil(errorMessage[Constants.Metadata.Logger.timestamp])
        XCTAssertEqual(errorMessage[Constants.Metadata.Logger.level] as? String, "ERROR")
        
        let fatalMessage = jsonDict[4]
        XCTAssertEqual(fatalMessage[Constants.Metadata.Logger.message] as? String, "StephenColbert")
        XCTAssertEqual(fatalMessage[Constants.Metadata.Logger.package] as? String, fakePKG)
        XCTAssertNotNil(fatalMessage[Constants.Metadata.Logger.timestamp])
        XCTAssertEqual(fatalMessage[Constants.Metadata.Logger.level] as? String, "FATAL")
    }
    
    
    func testGetLogWithAnalytics(){
        let pathToFile = BMSLogger.logsDocumentPath + Constants.File.Analytics.logs
        let pathToBuffer = BMSLogger.logsDocumentPath + Constants.File.Analytics.outboundLogs
        
        do {
            try FileManager().removeItem(atPath: pathToFile)
            
        } catch {
            
        }
        
        do {
            try FileManager().removeItem(atPath: pathToBuffer)
            
        } catch {
            
        }
        
        Analytics.isEnabled = true
        Logger.isLogStorageEnabled = true
        Logger.logLevelFilter = LogLevel.analytics
        let meta = ["hello": 1]
        
        Analytics.log(metadata: meta)
        
        guard let logs: String = BMSLoggerTests.getLogs(fromFile: LogFileType.ANALYTICS) else {
            XCTFail()
            return
        }
        
        let bufferFile = FileManager().fileExists(atPath: pathToBuffer)
        
        XCTAssertTrue(bufferFile)
        
        let fileContents = "[\(logs)]"
        
        let logDict = fileContents.data(using: .utf8)!
        guard let jsonDict = BMSLoggerTests.convertToJson(logs: logDict) else {
            XCTFail()
            return
        }
        
        let analyticsMessage = jsonDict[0]
        XCTAssertEqual(analyticsMessage[Constants.Metadata.Logger.message] as? String, "")
        XCTAssertEqual(analyticsMessage[Constants.Metadata.Logger.package] as? String, Logger.bmsLoggerPrefix + "analytics")
        XCTAssertNotNil(analyticsMessage[Constants.Metadata.Logger.timestamp])
        XCTAssertEqual(analyticsMessage[Constants.Metadata.Logger.level] as? String, "ANALYTICS")
        
        if let recordedMetadata = analyticsMessage[Constants.Metadata.Logger.metadata] as? [String: Int] {
            XCTAssertEqual(recordedMetadata, meta)
        }
        else {
            XCTFail("Should have recorded metadata from Analytics.log().")
        }
    }
    
    
    func testOverFlowLogging() {
        
        Analytics.initialize(appName: "testAppName", apiKey: "1234")
        
        let fakePKG = "MYPKG"
        let pathToFile = BMSLogger.logsDocumentPath + Constants.File.Logger.logs
        let pathToOverflow = BMSLogger.logsDocumentPath + Constants.File.Logger.overflowLogs
        
        do {
            try FileManager().removeItem(atPath: pathToFile)
            
        } catch {
            
        }
        
        do {
            try FileManager().removeItem(atPath: pathToOverflow)
        } catch {
            
        }
        
        let bundle = Bundle(for: type(of: self))
        let path = bundle.path(forResource: "LargeData", ofType: "txt")
        
        let loggerInstance = Logger.logger(name: fakePKG)
        guard let largeData = BMSLoggerTests.getContents(ofFile: path!) else {
            XCTFail()
            return
        }
        
        Logger.isLogStorageEnabled = true
        Logger.isInternalDebugLoggingEnabled = false
        Logger.logLevelFilter = LogLevel.debug
        
        loggerInstance.debug(message: largeData)
         loggerInstance.info(message: "1242342342343243242342")
        loggerInstance.warn(message: "Str: heyoooooo")
        loggerInstance.error(message: "1 2 3 4")
        loggerInstance.fatal(message: "StephenColbert")
        
        XCTAssertTrue(FileManager().fileExists(atPath: pathToOverflow))
        
        guard let formattedContents = BMSLoggerTests.getContents(ofFile: pathToFile) else {
            XCTFail()
            return
        }
        var fileContents = "[\(formattedContents)]"
        var logDict = fileContents.data(using: .utf8)!
        guard let jsonDict = BMSLoggerTests.convertToJson(logs: logDict) else {
            XCTFail()
            return
        }
        
        let infoMessage = jsonDict[0]
        XCTAssertEqual(infoMessage[Constants.Metadata.Logger.message] as? String, "1242342342343243242342")
        XCTAssertEqual(infoMessage[Constants.Metadata.Logger.package] as? String, fakePKG)
        XCTAssertNotNil(infoMessage[Constants.Metadata.Logger.timestamp])
        XCTAssertEqual(infoMessage[Constants.Metadata.Logger.level] as? String, "INFO")
        
        let warnMessage = jsonDict[1]
        XCTAssertEqual(warnMessage[Constants.Metadata.Logger.message] as? String, "Str: heyoooooo")
        XCTAssertEqual(warnMessage[Constants.Metadata.Logger.package] as? String, fakePKG)
        XCTAssertNotNil(warnMessage[Constants.Metadata.Logger.timestamp])
        XCTAssertEqual(warnMessage[Constants.Metadata.Logger.level] as? String, "WARN")
        
        let errorMessage = jsonDict[2]
        XCTAssertEqual(errorMessage[Constants.Metadata.Logger.message] as? String, "1 2 3 4")
        XCTAssertEqual(errorMessage[Constants.Metadata.Logger.package] as? String, fakePKG)
        XCTAssertNotNil(errorMessage[Constants.Metadata.Logger.timestamp])
        XCTAssertEqual(errorMessage[Constants.Metadata.Logger.level] as? String, "ERROR")
        
        let fatalMessage = jsonDict[3]
        XCTAssertEqual(fatalMessage[Constants.Metadata.Logger.message] as? String, "StephenColbert")
        XCTAssertEqual(fatalMessage[Constants.Metadata.Logger.package] as? String, fakePKG)
        XCTAssertNotNil(fatalMessage[Constants.Metadata.Logger.timestamp])
        XCTAssertEqual(fatalMessage[Constants.Metadata.Logger.level] as? String, "FATAL")
        
        guard let newFormattedContents = BMSLoggerTests.getContents(ofFile: pathToOverflow) else {
            XCTFail()
            return
        }
        fileContents = "[\(newFormattedContents)]"
        logDict  = fileContents.data(using: .utf8)!
        guard let newJsonDict = BMSLoggerTests.convertToJson(logs: logDict) else {
            XCTFail()
            return
        }
        
        
        let overflowMessage = newJsonDict[0]
        XCTAssertEqual(overflowMessage[Constants.Metadata.Logger.message] as? String, largeData)
        XCTAssertEqual(overflowMessage[Constants.Metadata.Logger.package] as? String, fakePKG)
        XCTAssertNotNil(overflowMessage[Constants.Metadata.Logger.timestamp])
        XCTAssertEqual(overflowMessage[Constants.Metadata.Logger.level] as? String, "DEBUG")
    }
    
    
    func testExistingOverflowFile() {
        
        Analytics.initialize(appName: "testAppName", apiKey: "1234")
        
        let fakePKG = "MYPKG"
        let pathToFile = BMSLogger.logsDocumentPath + Constants.File.Logger.logs
        let pathToOverflow = BMSLogger.logsDocumentPath + Constants.File.Logger.overflowLogs
        
        do {
            try FileManager().removeItem(atPath: pathToFile)
            
        } catch {
            
        }
        
        do {
            try FileManager().removeItem(atPath: pathToOverflow)
        } catch {
            
        }
        
        let bundle = Bundle(for: type(of: self))
        let path = bundle.path(forResource: "LargeData", ofType: "txt")
        
        guard let largeData = BMSLoggerTests.getContents(ofFile: path!) else {
            XCTFail()
            return
        }
        
        
        let loggerInstance = Logger.logger(name: fakePKG)
        Logger.isLogStorageEnabled = true
        Logger.isInternalDebugLoggingEnabled = false
        Logger.logLevelFilter = LogLevel.debug
        
        loggerInstance.debug(message: largeData)
        loggerInstance.info(message: largeData)
        loggerInstance.warn(message: largeData)
        loggerInstance.error(message: largeData)
        loggerInstance.fatal(message: largeData)
        
        
        XCTAssertTrue(FileManager().fileExists(atPath: pathToOverflow))
        
        guard let formattedContents = BMSLoggerTests.getContents(ofFile: pathToOverflow) else {
            XCTFail()
            return
        }
        
        
        var fileContents = "[\(formattedContents)]"
        var logDict = fileContents.data(using: .utf8)!
        guard let jsonDict = BMSLoggerTests.convertToJson(logs: logDict) else {
            XCTFail()
            return
        }
        
        XCTAssertTrue(jsonDict.count == 1)
        
        loggerInstance.debug(message: largeData)
        
        
        guard let newFormattedContents = BMSLoggerTests.getContents(ofFile: pathToOverflow) else {
            XCTFail()
            return
        }
        fileContents = "[\(newFormattedContents)]"
        logDict  = fileContents.data(using: .utf8)!
        guard let newJsonDict = BMSLoggerTests.convertToJson(logs: logDict) else {
            XCTFail()
            return
        }
        
        XCTAssertTrue(newJsonDict.count == 1)
    }
    
    
    
    // MARK: - Sending logs
    
    func testLogSendRequest(){
        let fakePKG = "MYPKG"
        let pathToFile = BMSLogger.logsDocumentPath + Constants.File.Logger.logs
        let pathToBuffer = BMSLogger.logsDocumentPath + Constants.File.Logger.outboundLogs
        let bmsClient = BMSClient.sharedInstance
        bmsClient.initialize(bluemixAppRoute: "bluemix", bluemixAppGUID: "appID1", bluemixRegion: BMSClient.Region.usSouth)
        Analytics.initialize(appName: "testAppName", apiKey: "1234")
        let url = "https://" + Constants.AnalyticsServer.hostName + BMSClient.Region.usSouth + Constants.AnalyticsServer.uploadPath
        
        let headers = ["Content-Type": "text/plain", Constants.analyticsApiKey: "1234", Constants.analyticsP30ApiKey: "appID1"]
        
        do {
            try FileManager().removeItem(atPath: pathToFile)
            
        } catch {
            
        }
        
        do {
            try FileManager().removeItem(atPath: pathToBuffer)
            
        } catch {
            
        }
        
        let loggerInstance = Logger.logger(name: fakePKG)
        Logger.isLogStorageEnabled = true
        Logger.logLevelFilter = LogLevel.debug
        
        loggerInstance.debug(message: "Hello world")
        loggerInstance.info(message: "1242342342343243242342")
        loggerInstance.warn(message: "Str: heyoooooo")
        loggerInstance.error(message: "1 2 3 4")
        loggerInstance.fatal(message: "StephenColbert")
        
        let request = try! BMSLogger.buildLogSendRequest() { (response, error) -> Void in
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
        bmsClient.initialize(bluemixAppRoute: "bluemix", bluemixAppGUID: "appID1", bluemixRegion: BMSClient.Region.usSouth)
        Analytics.initialize(appName: "testAppName", apiKey: "")
        
        do {
            try FileManager().removeItem(atPath: pathToFile)
            
        } catch {
            
        }
        
        do {
            try FileManager().removeItem(atPath: pathToBuffer)
            
        } catch {
            
        }
        
        let loggerInstance = Logger.logger(name: fakePKG)
        Logger.isLogStorageEnabled = true
        Logger.logLevelFilter = LogLevel.debug
        
        loggerInstance.debug(message: "Hello world")
        loggerInstance.info(message: "1242342342343243242342")
        loggerInstance.warn(message: "Str: heyoooooo")
        loggerInstance.error(message: "1 2 3 4")
        loggerInstance.fatal(message: "StephenColbert")
        
        guard let _ = BMSLoggerTests.getLogs(fromFile: LogFileType.LOGGER) else {
            XCTFail()
            return
        }
        
        XCTAssertTrue(FileManager().fileExists(atPath: pathToBuffer))
        
        let request = try! BMSLogger.buildLogSendRequest() { (response, error) -> Void in
        }
        
        XCTAssertNil(request)
        
        guard let formattedContents = BMSLoggerTests.getContents(ofFile: pathToFile) else {
            XCTFail()
            return
        }
        let fileContents = "[\(formattedContents)]"
        let logDict  = fileContents.data(using: .utf8)!
        
        guard let newJsonDict = BMSLoggerTests.convertToJson(logs: logDict) else {
            XCTFail()
            return
        }
        
        let error = newJsonDict[0]
        XCTAssertNotNil(error[Constants.Metadata.Logger.message])
        XCTAssertEqual(error[Constants.Metadata.Logger.package] as? String, fakePKG)
        XCTAssertNotNil(error[Constants.Metadata.Logger.timestamp])
        XCTAssertEqual(error[Constants.Metadata.Logger.level] as? String, "ERROR")
    }
    
    
    func testBuildLogSendRequestForBluemix() {
        
        let bmsClient = BMSClient.sharedInstance
        bmsClient.initialize(bluemixAppRoute: "bluemix", bluemixAppGUID: "appID1", bluemixRegion: BMSClient.Region.usSouth)
        Analytics.initialize(appName: "testAppName", apiKey: "1234")
        
        let bmsRequest = try! BMSLogger.buildLogSendRequest() { (response, error) -> Void in
        }
        
        XCTAssertNotNil(bmsRequest)
        XCTAssertTrue(bmsRequest is Request)
        
        let bmsLogUploadUrl = "https://" + Constants.AnalyticsServer.hostName + ".ng.bluemix.net" + Constants.AnalyticsServer.uploadPath
        XCTAssertEqual(bmsRequest!.resourceUrl, bmsLogUploadUrl)
    }
    
    
    func testBuildLogSendRequestForLocalhost() {
        
        let bmsClient = BMSClient.sharedInstance
        bmsClient.initialize(bluemixAppRoute: "bluemix", bluemixAppGUID: "appID1", bluemixRegion: "localhost:8000")
        Analytics.initialize(appName: "testAppName", apiKey: "1234")
        
        let bmsRequest = try! BMSLogger.buildLogSendRequest() { (response, error) -> Void in
        }
        
        XCTAssertNotNil(bmsRequest)
        XCTAssertTrue(bmsRequest is Request)
        
        let bmsLogUploadUrl = "http://" + "localhost:8000" + Constants.AnalyticsServer.uploadPath
        XCTAssertEqual(bmsRequest!.resourceUrl, bmsLogUploadUrl)
    }
    
    
    func testPreventSimultaneousSendRequests() {
        
        let bmsClient = BMSClient.sharedInstance
        bmsClient.initialize(bluemixAppRoute: "bluemix", bluemixAppGUID: "appID1", bluemixRegion: BMSClient.Region.usSouth)
        Analytics.initialize(appName: "testAppName", apiKey: "1234")
        
        XCTAssertFalse(Logger.currentlySendingLoggerLogs)
        XCTAssertFalse(Logger.currentlySendingAnalyticsLogs)
        
        let loggerSendFinished = expectation(description: "Logger send complete")
        let analyticsSendFinished = expectation(description: "Analytics send complete")
        
        Logger.send { (_, _) in
            XCTAssertFalse(Logger.currentlySendingLoggerLogs)
            loggerSendFinished.fulfill()
        }
        Analytics.send { (_, _) in
            XCTAssertFalse(Logger.currentlySendingAnalyticsLogs)
            analyticsSendFinished.fulfill()
        }
        
        XCTAssertTrue(Logger.currentlySendingLoggerLogs)
        XCTAssertTrue(Logger.currentlySendingAnalyticsLogs)
        
        waitForExpectations(timeout: 10.0) { (error: Error?) -> Void in
            if error != nil {
                XCTFail("Expectation failed with error: \(error)")
            }
        }
    }
    
    
    func testReturnInitializationError() {
        
        // BMSClient initialization
        BMSLogger.returnInitializationError(className: "BMSClient", missingValue:"test") { (response, error) -> Void in
            XCTAssertNil(response)
            XCTAssertEqual(error as? BMSCoreError, BMSCoreError.clientNotInitialized)
        }
        
        // Analytics initialization
        BMSLogger.returnInitializationError(className: "Analytics", missingValue:"test") { (response, error) -> Void in
            XCTAssertNil(response)
            XCTAssertEqual(error as? BMSAnalyticsError, BMSAnalyticsError.analyticsNotInitialized)
        }
        
        // Unknown initialization
        BMSLogger.returnInitializationError(className: "Unknown class", missingValue:"test") { (response, error) -> Void in
            XCTAssertNil(response)
            XCTAssertNil(error)
        }
    }
    
    
    func testDeleteFileFail(){
        let fakePKG = "bmssdk.logger"
        let pathToFile = BMSLogger.logsDocumentPath + Constants.File.Logger.logs
        let pathToBuffer = BMSLogger.logsDocumentPath + Constants.File.Logger.outboundLogs
        do {
            try FileManager().removeItem(atPath: pathToFile)
            
        } catch {
            
        }
        
        do {
            try FileManager().removeItem(atPath: pathToBuffer)
            
        } catch {
            
        }
        
        let loggerInstance = Logger.logger(name: fakePKG)
        Logger.isLogStorageEnabled = true
        Logger.logLevelFilter = LogLevel.debug
        
        loggerInstance.debug(message: "Hello world")
        
        guard let logs: String = BMSLoggerTests.getLogs(fromFile: LogFileType.LOGGER) else {
            XCTFail()
            return
        }
        
        XCTAssertTrue(FileManager().fileExists(atPath: pathToBuffer))
        
        XCTAssertNotNil(logs)
        
        do {
            try FileManager().removeItem(atPath: pathToBuffer)
        } catch {
            
        }
        
        BMSLogger.delete(file: Constants.File.Logger.outboundLogs)
        
        XCTAssertFalse(FileManager().fileExists(atPath: pathToBuffer))
    }
    
    
    func testDeleteFile(){
        let fakePKG = "MYPKG"
        let pathToFile = BMSLogger.logsDocumentPath + Constants.File.Logger.logs
        let pathToBuffer = BMSLogger.logsDocumentPath + Constants.File.Logger.outboundLogs
        
        do {
            try FileManager().removeItem(atPath: pathToFile)
            
        } catch {
            
        }
        
        do {
            try FileManager().removeItem(atPath: pathToBuffer)
            
        } catch {
            
        }
        
        let loggerInstance = Logger.logger(name: fakePKG)
        Logger.isLogStorageEnabled = true
        Logger.logLevelFilter = LogLevel.debug
        
        loggerInstance.debug(message: "Hello world")
        loggerInstance.info(message: "1242342342343243242342")
        loggerInstance.warn(message: "Str: heyoooooo")
        loggerInstance.error(message: "1 2 3 4")
        loggerInstance.fatal(message: "StephenColbert")
        
        guard let _ = BMSLoggerTests.getLogs(fromFile: LogFileType.LOGGER) else {
            XCTFail()
            return
        }
        
        XCTAssertTrue(FileManager().fileExists(atPath: pathToBuffer))
        
        BMSLogger.delete(file: Constants.File.Logger.outboundLogs)
        
        XCTAssertFalse(FileManager().fileExists(atPath: pathToBuffer))
    }
    
    
    func testExtractFileNameFromPath() {
        
        let logFile1 = "some/path/to/file.txt"
        let logFile2 = "path//with///extra///slashes.log.txt"
        let logFile3 = "/////"
        let logFile4 = ""
        let logFile5 = "pathWithoutSlashes"
        
        
        XCTAssertEqual(BMSLogger.extractFileName(fromPath: logFile1), "file.txt")
        XCTAssertEqual(BMSLogger.extractFileName(fromPath: logFile2), "slashes.log.txt")
        XCTAssertEqual(BMSLogger.extractFileName(fromPath: logFile3), "/")
        XCTAssertEqual(BMSLogger.extractFileName(fromPath: logFile4), Constants.File.unknown)
        XCTAssertEqual(BMSLogger.extractFileName(fromPath: logFile5), "pathWithoutSlashes")
    }
    
    
    
    // MARK: - Helpers
    
    static func getContents(ofFile pathToFile: String) -> String? {
        do {
            return try String(contentsOfFile: pathToFile, encoding: .utf8)
        }
        catch {
            return nil
        }
    }
    
    static func convertToJson(logs: Data) -> [[String: Any]]? {
        do {
            return try JSONSerialization.jsonObject(with: logs, options: .mutableContainers) as? [[String: Any]]
        }
        catch {
            return nil
        }
    }
    
    static func getLogs(fromFile logFile: LogFileType) -> String? {
        do {
            switch logFile {
            case .LOGGER:
                return try BMSLogger.getLogs(fromFile: Constants.File.Logger.logs, overflowFileName: Constants.File.Logger.overflowLogs, bufferFileName: Constants.File.Logger.outboundLogs)
            case .ANALYTICS:
                return try BMSLogger.getLogs(fromFile: Constants.File.Analytics.logs, overflowFileName: Constants.File.Analytics.overflowLogs, bufferFileName: Constants.File.Analytics.outboundLogs)
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
    
    
    
    
    
/**************************************************************************************************/
    
    
    
    
    
// MARK: - Swift 2
    
#else
    

    
class BMSLoggerTests: XCTestCase {
    
    
    override func tearDown() {
        BMSClient.sharedInstance.initialize(bluemixAppRoute: nil, bluemixAppGUID: nil, bluemixRegion: "")
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
    
    
    func testisLogStorageEnabled(){
        
        let capture1 = Logger.isLogStorageEnabled
        XCTAssertTrue(capture1, "should default to true");
        
        Logger.isLogStorageEnabled = false
        
        let capture2 = Logger.isLogStorageEnabled
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
        
        let loggerInstance = Logger.logger(name: fakePKG)
        Logger.isLogStorageEnabled = true
        Logger.logLevelFilter = LogLevel.debug
        Logger.isInternalDebugLoggingEnabled = false
        
        loggerInstance.debug(message: "Hello world")
        loggerInstance.info(message: "1242342342343243242342")
        loggerInstance.warn(message: "Str: heyoooooo")
        loggerInstance.error(message: "1 2 3 4")
        loggerInstance.fatal(message: "StephenColbert")
        
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
        XCTAssertNotNil(debugMessage[Constants.Metadata.Logger.timestamp])
        XCTAssertTrue(debugMessage[Constants.Metadata.Logger.level] == "DEBUG")
        
        let infoMessage = jsonDict[1]
        XCTAssertTrue(infoMessage[Constants.Metadata.Logger.message] == "1242342342343243242342")
        XCTAssertTrue(infoMessage[Constants.Metadata.Logger.package] == fakePKG)
        XCTAssertNotNil(infoMessage[Constants.Metadata.Logger.timestamp])
        XCTAssertTrue(infoMessage[Constants.Metadata.Logger.level] == "INFO")
        
        let warnMessage = jsonDict[2]
        XCTAssertTrue(warnMessage[Constants.Metadata.Logger.message] == "Str: heyoooooo")
        XCTAssertTrue(warnMessage[Constants.Metadata.Logger.package] == fakePKG)
        XCTAssertNotNil(warnMessage[Constants.Metadata.Logger.timestamp])
        XCTAssertTrue(warnMessage[Constants.Metadata.Logger.level] == "WARN")
        
        let errorMessage = jsonDict[3]
        XCTAssertTrue(errorMessage[Constants.Metadata.Logger.message] == "1 2 3 4")
        XCTAssertTrue(errorMessage[Constants.Metadata.Logger.package] == fakePKG)
        XCTAssertNotNil(errorMessage[Constants.Metadata.Logger.timestamp])
        XCTAssertTrue(errorMessage[Constants.Metadata.Logger.level] == "ERROR")
        
        let fatalMessage = jsonDict[4]
        XCTAssertTrue(fatalMessage[Constants.Metadata.Logger.message] == "StephenColbert")
        XCTAssertTrue(fatalMessage[Constants.Metadata.Logger.package] == fakePKG)
        XCTAssertNotNil(fatalMessage[Constants.Metadata.Logger.timestamp])
    }
    
    
    func testLogMethods(){
        let fakePKG = "MYPKG"
        let pathToFile = BMSLogger.logsDocumentPath + Constants.File.Logger.logs
        
        do {
            try NSFileManager().removeItemAtPath(pathToFile)
        } catch {
            
        }
        
        let loggerInstance = Logger.logger(name: fakePKG)
        Logger.isLogStorageEnabled = true
        Logger.logLevelFilter = LogLevel.debug
        
        loggerInstance.debug(message: "Hello world")
        loggerInstance.info(message: "1242342342343243242342")
        loggerInstance.warn(message: "Str: heyoooooo")
        loggerInstance.error(message: "1 2 3 4")
        loggerInstance.fatal(message: "StephenColbert")
        
        
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
        XCTAssertNotNil(debugMessage[Constants.Metadata.Logger.timestamp])
        XCTAssertTrue(debugMessage[Constants.Metadata.Logger.level] == "DEBUG")
        
        let infoMessage = jsonDict[1]
        XCTAssertTrue(infoMessage[Constants.Metadata.Logger.message] == "1242342342343243242342")
        XCTAssertTrue(infoMessage[Constants.Metadata.Logger.package] == fakePKG)
        XCTAssertNotNil(infoMessage[Constants.Metadata.Logger.timestamp])
        XCTAssertTrue(infoMessage[Constants.Metadata.Logger.level] == "INFO")
        
        let warnMessage = jsonDict[2]
        XCTAssertTrue(warnMessage[Constants.Metadata.Logger.message] == "Str: heyoooooo")
        XCTAssertTrue(warnMessage[Constants.Metadata.Logger.package] == fakePKG)
        XCTAssertNotNil(warnMessage[Constants.Metadata.Logger.timestamp])
        XCTAssertTrue(warnMessage[Constants.Metadata.Logger.level] == "WARN")
        
        let errorMessage = jsonDict[3]
        XCTAssertTrue(errorMessage[Constants.Metadata.Logger.message] == "1 2 3 4")
        XCTAssertTrue(errorMessage[Constants.Metadata.Logger.package] == fakePKG)
        XCTAssertNotNil(errorMessage[Constants.Metadata.Logger.timestamp])
        XCTAssertTrue(errorMessage[Constants.Metadata.Logger.level] == "ERROR")
        
        let fatalMessage = jsonDict[4]
        XCTAssertTrue(fatalMessage[Constants.Metadata.Logger.message] == "StephenColbert")
        XCTAssertTrue(fatalMessage[Constants.Metadata.Logger.package] == fakePKG)
        XCTAssertNotNil(fatalMessage[Constants.Metadata.Logger.timestamp])
    }
    
    
    func testLogWithNone(){
        let fakePKG = "MYPKG"
        let pathToFile = BMSLogger.logsDocumentPath + Constants.File.Logger.logs
        
        do {
            try NSFileManager().removeItemAtPath(pathToFile)
        } catch {
            
        }
        
        let loggerInstance = Logger.logger(name: fakePKG)
        Logger.isLogStorageEnabled = true
        Logger.logLevelFilter = LogLevel.none
        
        loggerInstance.debug(message: "Hello world")
        loggerInstance.info(message: "1242342342343243242342")
        loggerInstance.warn(message: "Str: heyoooooo")
        loggerInstance.error(message: "1 2 3 4")
        loggerInstance.fatal(message: "StephenColbert")
        
        XCTAssertFalse(NSFileManager().fileExistsAtPath(pathToFile))
    }
    
    
    func testIncorrectLogLevel(){
        let fakePKG = "MYPKG"
        let pathToFile = BMSLogger.logsDocumentPath + Constants.File.Logger.logs
        
        do {
            try NSFileManager().removeItemAtPath(pathToFile)
        } catch {
            
        }
        
        let loggerInstance = Logger.logger(name: fakePKG)
        Logger.isLogStorageEnabled = true
        Logger.logLevelFilter = LogLevel.fatal
        
        loggerInstance.debug(message: "Hello world")
        loggerInstance.info(message: "1242342342343243242342")
        loggerInstance.warn(message: "Str: heyoooooo")
        loggerInstance.error(message: "1 2 3 4")
        
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
        
        let loggerInstance = Logger.logger(name: fakePKG)
        Logger.isLogStorageEnabled = false
        Logger.logLevelFilter = LogLevel.debug
        
        loggerInstance.debug(message: "Hello world")
        loggerInstance.info(message: "1242342342343243242342")
        loggerInstance.warn(message: "Str: heyoooooo")
        loggerInstance.error(message: "1 2 3 4")
        loggerInstance.fatal(message: "StephenColbert")
        
        let fileExists = NSFileManager().fileExistsAtPath(pathToFile)
        
        XCTAssertFalse(fileExists)
    }
    
    
    func testLogException() {
       
        Logger.isLogStorageEnabled = true
        
        let pathToFile = BMSLogger.logsDocumentPath + Constants.File.Logger.logs
        
        do {
            try NSFileManager().removeItemAtPath(pathToFile)
        } catch {
            
        }
        
        let e = NSException(name:"crashApp", reason:"No reason at all just doing it for fun", userInfo:["user":"nana"])
        
        BMSLogger.log(exception: e)
        
        guard let formattedContents = BMSLoggerTests.getFileContents(pathToFile) else {
            XCTFail()
            return
        }
        let fileContents = "[\(formattedContents)]"
        let errorMessage = e.reason!
        let logDict : NSData = fileContents.dataUsingEncoding(NSUTF8StringEncoding)!
        guard let jsonDict = BMSLoggerTests.convertLogsToJson(logDict) else {
            XCTFail()
            return
        }
        
        let exception = jsonDict[0]
        XCTAssertTrue(exception[Constants.Metadata.Logger.message] == errorMessage)
        XCTAssertTrue(exception[Constants.Metadata.Logger.package] == Constants.Package.logger)
        XCTAssertNotNil(exception[Constants.Metadata.Logger.timestamp])
        XCTAssertTrue(exception[Constants.Metadata.Logger.level] == "FATAL")
    }
    
    
    
    // MARK: - Writing logs to file
    
    func testGetFilesForLogLevel(){
        let pathToLoggerFile = BMSLogger.logsDocumentPath + Constants.File.Logger.logs
        let pathToAnalyticsFile = BMSLogger.logsDocumentPath + Constants.File.Analytics.logs
        let pathToLoggerFileOverflow = BMSLogger.logsDocumentPath + Constants.File.Logger.overflowLogs
        let pathToAnalyticsFileOverflow = BMSLogger.logsDocumentPath + Constants.File.Analytics.overflowLogs
        
        var (logFile, logOverflowFile, fileDispatchQueue) = BMSLogger.getFiles(for: LogLevel.debug)
        
        XCTAssertTrue(logFile == pathToLoggerFile)
        XCTAssertTrue(logOverflowFile == pathToLoggerFileOverflow)
        XCTAssertNotNil(fileDispatchQueue)
        
        (logFile, logOverflowFile, fileDispatchQueue) = BMSLogger.getFiles(for: LogLevel.error)
        
        XCTAssertTrue(logFile == pathToLoggerFile)
        XCTAssertTrue(logOverflowFile == pathToLoggerFileOverflow)
        XCTAssertNotNil(fileDispatchQueue)
        
        (logFile, logOverflowFile, fileDispatchQueue) = BMSLogger.getFiles(for: LogLevel.fatal)
        
        XCTAssertTrue(logFile == pathToLoggerFile)
        XCTAssertTrue(logOverflowFile == pathToLoggerFileOverflow)
        XCTAssertNotNil(fileDispatchQueue)
        
        (logFile, logOverflowFile, fileDispatchQueue) = BMSLogger.getFiles(for: LogLevel.info)
        
        XCTAssertTrue(logFile == pathToLoggerFile)
        XCTAssertTrue(logOverflowFile == pathToLoggerFileOverflow)
        XCTAssertNotNil(fileDispatchQueue)
        
        (logFile, logOverflowFile, fileDispatchQueue) = BMSLogger.getFiles(for: LogLevel.error)
        
        XCTAssertTrue(logFile == pathToLoggerFile)
        XCTAssertTrue(logOverflowFile == pathToLoggerFileOverflow)
        XCTAssertNotNil(fileDispatchQueue)
        
        (logFile, logOverflowFile, fileDispatchQueue) = BMSLogger.getFiles(for: LogLevel.analytics)
        
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
        
        let loggerInstance = Logger.logger(name: fakePKG)
        Logger.isLogStorageEnabled = true
        Logger.logLevelFilter = LogLevel.debug
        
        loggerInstance.debug(message: "Hello world")
        loggerInstance.info(message: "1242342342343243242342")
        loggerInstance.warn(message: "Str: heyoooooo")
        loggerInstance.error(message: "1 2 3 4")
        loggerInstance.fatal(message: "StephenColbert")
        
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
        XCTAssertNotNil(debugMessage[Constants.Metadata.Logger.timestamp])
        XCTAssertTrue(debugMessage[Constants.Metadata.Logger.level] == "DEBUG")
        
        let infoMessage = jsonDict[1]
        XCTAssertTrue(infoMessage[Constants.Metadata.Logger.message] == "1242342342343243242342")
        XCTAssertTrue(infoMessage[Constants.Metadata.Logger.package] == fakePKG)
        XCTAssertNotNil(infoMessage[Constants.Metadata.Logger.timestamp])
        XCTAssertTrue(infoMessage[Constants.Metadata.Logger.level] == "INFO")
        
        let warnMessage = jsonDict[2]
        XCTAssertTrue(warnMessage[Constants.Metadata.Logger.message] == "Str: heyoooooo")
        XCTAssertTrue(warnMessage[Constants.Metadata.Logger.package] == fakePKG)
        XCTAssertNotNil(warnMessage[Constants.Metadata.Logger.timestamp])
        XCTAssertTrue(warnMessage[Constants.Metadata.Logger.level] == "WARN")
        
        let errorMessage = jsonDict[3]
        XCTAssertTrue(errorMessage[Constants.Metadata.Logger.message] == "1 2 3 4")
        XCTAssertTrue(errorMessage[Constants.Metadata.Logger.package] == fakePKG)
        XCTAssertNotNil(errorMessage[Constants.Metadata.Logger.timestamp])
        XCTAssertTrue(errorMessage[Constants.Metadata.Logger.level] == "ERROR")
        
        let fatalMessage = jsonDict[4]
        XCTAssertTrue(fatalMessage[Constants.Metadata.Logger.message] == "StephenColbert")
        XCTAssertTrue(fatalMessage[Constants.Metadata.Logger.package] == fakePKG)
        XCTAssertNotNil(fatalMessage[Constants.Metadata.Logger.timestamp])
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
        
        Analytics.isEnabled = true
        Logger.isLogStorageEnabled = true
        Logger.logLevelFilter = LogLevel.analytics
        let meta = ["hello": 1]
        
        Analytics.log(metadata: meta)
        
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
        XCTAssertNotNil(analyticsMessage[Constants.Metadata.Logger.timestamp])
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
        
        let loggerInstance = Logger.logger(name: fakePKG)
        guard let largeData = BMSLoggerTests.getFileContents(path!) else {
            XCTFail()
            return
        }
        
        Logger.isLogStorageEnabled = true
        Logger.isInternalDebugLoggingEnabled = false
        Logger.logLevelFilter = LogLevel.debug
        
        loggerInstance.debug(message: largeData)
        loggerInstance.info(message: "1242342342343243242342")
        loggerInstance.warn(message: "Str: heyoooooo")
        loggerInstance.error(message: "1 2 3 4")
        loggerInstance.fatal(message: "StephenColbert")
        
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
        XCTAssertNotNil(infoMessage[Constants.Metadata.Logger.timestamp])
        XCTAssertTrue(infoMessage[Constants.Metadata.Logger.level] == "INFO")
        
        let warnMessage = jsonDict[1]
        XCTAssertTrue(warnMessage[Constants.Metadata.Logger.message] == "Str: heyoooooo")
        XCTAssertTrue(warnMessage[Constants.Metadata.Logger.package] == fakePKG)
        XCTAssertNotNil(warnMessage[Constants.Metadata.Logger.timestamp])
        XCTAssertTrue(warnMessage[Constants.Metadata.Logger.level] == "WARN")
        
        let errorMessage = jsonDict[2]
        XCTAssertTrue(errorMessage[Constants.Metadata.Logger.message] == "1 2 3 4")
        XCTAssertTrue(errorMessage[Constants.Metadata.Logger.package] == fakePKG)
        XCTAssertNotNil(errorMessage[Constants.Metadata.Logger.timestamp])
        XCTAssertTrue(errorMessage[Constants.Metadata.Logger.level] == "ERROR")
        
        let fatalMessage = jsonDict[3]
        XCTAssertTrue(fatalMessage[Constants.Metadata.Logger.message] == "StephenColbert")
        XCTAssertTrue(fatalMessage[Constants.Metadata.Logger.package] == fakePKG)
        XCTAssertNotNil(fatalMessage[Constants.Metadata.Logger.timestamp])
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
        XCTAssertNotNil(overflowMessage[Constants.Metadata.Logger.timestamp])
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
        
        
        let loggerInstance = Logger.logger(name: fakePKG)
        Logger.isLogStorageEnabled = true
        Logger.isInternalDebugLoggingEnabled = false
        Logger.logLevelFilter = LogLevel.debug
        
        loggerInstance.debug(message: largeData)
        loggerInstance.info(message: largeData)
        loggerInstance.warn(message: largeData)
        loggerInstance.error(message: largeData)
        loggerInstance.fatal(message: largeData)
        
        
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
        
        loggerInstance.debug(message: largeData)
        
        
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
        let pathToFile = BMSLogger.logsDocumentPath + Constants.File.Logger.logs
        let pathToBuffer = BMSLogger.logsDocumentPath + Constants.File.Logger.outboundLogs
        let bmsClient = BMSClient.sharedInstance
        bmsClient.initialize(bluemixAppRoute: "bluemix", bluemixAppGUID: "appID1", bluemixRegion: BMSClient.Region.usSouth)
        Analytics.initialize(appName: "testAppName", apiKey: "1234")
        let url = "https://" + Constants.AnalyticsServer.hostName + BMSClient.Region.usSouth + Constants.AnalyticsServer.uploadPath
        
        let headers = ["Content-Type": "text/plain", Constants.analyticsApiKey: "1234", Constants.analyticsP30ApiKey: "appID1"]
        
        do {
            try NSFileManager().removeItemAtPath(pathToFile)
            
        } catch {
            
        }
        
        do {
            try NSFileManager().removeItemAtPath(pathToBuffer)
            
        } catch {
            
        }
        
        let loggerInstance = Logger.logger(name: fakePKG)
        Logger.isLogStorageEnabled = true
        Logger.logLevelFilter = LogLevel.debug
        
        loggerInstance.debug(message: "Hello world")
        loggerInstance.info(message: "1242342342343243242342")
        loggerInstance.warn(message: "Str: heyoooooo")
        loggerInstance.error(message: "1 2 3 4")
        loggerInstance.fatal(message: "StephenColbert")
        
        let request = try! BMSLogger.buildLogSendRequest() { (response, error) -> Void in
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
        bmsClient.initialize(bluemixAppRoute: "bluemix", bluemixAppGUID: "appID1", bluemixRegion: BMSClient.Region.usSouth)
        Analytics.initialize(appName: "testAppName", apiKey: "")
        
        do {
            try NSFileManager().removeItemAtPath(pathToFile)
            
        } catch {
            
        }
        
        do {
            try NSFileManager().removeItemAtPath(pathToBuffer)
            
        } catch {
            
        }
        
        let loggerInstance = Logger.logger(name: fakePKG)
        Logger.isLogStorageEnabled = true
        Logger.logLevelFilter = LogLevel.debug
        
        loggerInstance.debug(message: "Hello world")
        loggerInstance.info(message: "1242342342343243242342")
        loggerInstance.warn(message: "Str: heyoooooo")
        loggerInstance.error(message: "1 2 3 4")
        loggerInstance.fatal(message: "StephenColbert")
        
        guard let _ = BMSLoggerTests.getLogs(LogFileType.LOGGER) else {
            XCTFail()
            return
        }
        
        XCTAssertTrue(NSFileManager().fileExistsAtPath(pathToBuffer))
        
        let request = try! BMSLogger.buildLogSendRequest() { (response, error) -> Void in
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
        XCTAssertNotNil(error[Constants.Metadata.Logger.message])
        XCTAssertTrue(error[Constants.Metadata.Logger.package] == fakePKG)
        XCTAssertNotNil(error[Constants.Metadata.Logger.timestamp])
        XCTAssertTrue(error[Constants.Metadata.Logger.level] == "ERROR")
    }
    
    
    func testBuildLogSendRequestForBluemix() {
        
        let bmsClient = BMSClient.sharedInstance
        bmsClient.initialize(bluemixAppRoute: "bluemix", bluemixAppGUID: "appID1", bluemixRegion: BMSClient.Region.usSouth)
        Analytics.initialize(appName: "testAppName", apiKey: "1234")
        
        let bmsRequest = try! BMSLogger.buildLogSendRequest() { (response, error) -> Void in
        }
        
        XCTAssertNotNil(bmsRequest)
        XCTAssertTrue(bmsRequest is Request)
        
        let bmsLogUploadUrl = "https://" + Constants.AnalyticsServer.hostName + ".ng.bluemix.net" + Constants.AnalyticsServer.uploadPath
        XCTAssertEqual(bmsRequest!.resourceUrl, bmsLogUploadUrl)
    }
    
    
    func testBuildLogSendRequestForLocalhost() {
    
        let bmsClient = BMSClient.sharedInstance
        bmsClient.initialize(bluemixAppRoute: "bluemix", bluemixAppGUID: "appID1", bluemixRegion: "localhost:8000")
        Analytics.initialize(appName: "testAppName", apiKey: "1234")
        
        let bmsRequest = try! BMSLogger.buildLogSendRequest() { (response, error) -> Void in
        }
        
        XCTAssertNotNil(bmsRequest)
        XCTAssertTrue(bmsRequest is Request)
        
        let bmsLogUploadUrl = "http://" + "localhost:8000" + Constants.AnalyticsServer.uploadPath
        XCTAssertEqual(bmsRequest!.resourceUrl, bmsLogUploadUrl)
    }
    
    
    func testPreventSimultaneousSendRequests() {
        
        let bmsClient = BMSClient.sharedInstance
        bmsClient.initialize(bluemixAppRoute: "bluemix", bluemixAppGUID: "appID1", bluemixRegion: BMSClient.Region.usSouth)
        Analytics.initialize(appName: "testAppName", apiKey: "1234")
        
        XCTAssertFalse(Logger.currentlySendingLoggerLogs)
        XCTAssertFalse(Logger.currentlySendingAnalyticsLogs)
        
        let loggerSendFinished = expectationWithDescription("Logger send complete")
        let analyticsSendFinished = expectationWithDescription("Analytics send complete")
        
        Logger.send { (_, _) in
            XCTAssertFalse(Logger.currentlySendingLoggerLogs)
            loggerSendFinished.fulfill()
        }
        Analytics.send { (_, _) in
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
        BMSLogger.returnInitializationError(className: "BMSClient", missingValue:"test") { (response, error) -> Void in
            XCTAssertNil(response)
            XCTAssertNotNil(error)
            XCTAssertEqual(error!.code, BMSCoreError.clientNotInitialized.rawValue)
            XCTAssertEqual(error!.domain, BMSAnalyticsError.domain)
        }
        
        // Analytics initialization
        BMSLogger.returnInitializationError(className: "Analytics", missingValue:"test") { (response, error) -> Void in
            XCTAssertNil(response)
            XCTAssertNotNil(error)
            XCTAssertEqual(error!.code, BMSAnalyticsError.analyticsNotInitialized.rawValue)
            XCTAssertEqual(error!.domain, BMSAnalyticsError.domain)
        }
        
        // Unknown initialization
        BMSLogger.returnInitializationError(className: "Unknown class", missingValue:"test") { (response, error) -> Void in
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
        
        let loggerInstance = Logger.logger(name: fakePKG)
        Logger.isLogStorageEnabled = true
        Logger.logLevelFilter = LogLevel.debug
        
        loggerInstance.debug(message: "Hello world")
        
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
        
        BMSLogger.delete(file: Constants.File.Logger.outboundLogs)
        
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
        
        let loggerInstance = Logger.logger(name: fakePKG)
        Logger.isLogStorageEnabled = true
        Logger.logLevelFilter = LogLevel.debug
        
        loggerInstance.debug(message: "Hello world")
        loggerInstance.info(message: "1242342342343243242342")
        loggerInstance.warn(message: "Str: heyoooooo")
        loggerInstance.error(message: "1 2 3 4")
        loggerInstance.fatal(message: "StephenColbert")
        
        guard let _ = BMSLoggerTests.getLogs(LogFileType.LOGGER) else {
            XCTFail()
            return
        }
        
        XCTAssertTrue(NSFileManager().fileExistsAtPath(pathToBuffer))
        
        BMSLogger.delete(file: Constants.File.Logger.outboundLogs)
        
        XCTAssertFalse(NSFileManager().fileExistsAtPath(pathToBuffer))
    }
    
    
    func testExtractFileNameFromPath() {
        
        let logFile1 = "some/path/to/file.txt"
        let logFile2 = "path//with///extra///slashes.log.txt"
        let logFile3 = "/////"
        let logFile4 = ""
        let logFile5 = "pathWithoutSlashes"
        
        
        XCTAssertEqual(BMSLogger.extractFileName(fromPath: logFile1), "file.txt")
        XCTAssertEqual(BMSLogger.extractFileName(fromPath: logFile2), "slashes.log.txt")
        XCTAssertEqual(BMSLogger.extractFileName(fromPath: logFile3), "/")
        XCTAssertEqual(BMSLogger.extractFileName(fromPath: logFile4), Constants.File.unknown)
        XCTAssertEqual(BMSLogger.extractFileName(fromPath: logFile5), "pathWithoutSlashes")
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
                return try BMSLogger.getLogs(fromFile: Constants.File.Logger.logs, overflowFileName: Constants.File.Logger.overflowLogs, bufferFileName: Constants.File.Logger.outboundLogs)
            case .ANALYTICS:
                return try BMSLogger.getLogs(fromFile: Constants.File.Analytics.logs, overflowFileName: Constants.File.Analytics.overflowLogs, bufferFileName: Constants.File.Analytics.outboundLogs)
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



#endif
