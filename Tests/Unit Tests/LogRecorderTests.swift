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


class LogRecorderTests: XCTestCase {

    func testGetFilesForLogLevel(){
        let pathToLoggerFile = Logger.logsDocumentPath + Logger.FILE_LOGGER_LOGS
        let pathToAnalyticsFile = Logger.logsDocumentPath + Logger.FILE_ANALYTICS_LOGS
        let pathToLoggerFileOverflow = Logger.logsDocumentPath + Logger.FILE_LOGGER_OVERFLOW
        let pathToAnalyticsFileOverflow = Logger.logsDocumentPath + Logger.FILE_ANALYTICS_OVERFLOW
        
        var (logFile, logOverflowFile, fileDispatchQueue) = LogRecorder.getFilesForLogLevel(LogLevel.Debug)
        
        XCTAssertTrue(logFile == pathToLoggerFile)
        XCTAssertTrue(logOverflowFile == pathToLoggerFileOverflow)
        XCTAssertNotNil(fileDispatchQueue)
        
        (logFile, logOverflowFile, fileDispatchQueue) = LogRecorder.getFilesForLogLevel(LogLevel.Error)
        
        XCTAssertTrue(logFile == pathToLoggerFile)
        XCTAssertTrue(logOverflowFile == pathToLoggerFileOverflow)
        XCTAssertNotNil(fileDispatchQueue)
        
        (logFile, logOverflowFile, fileDispatchQueue) = LogRecorder.getFilesForLogLevel(LogLevel.Fatal)
        
        XCTAssertTrue(logFile == pathToLoggerFile)
        XCTAssertTrue(logOverflowFile == pathToLoggerFileOverflow)
        XCTAssertNotNil(fileDispatchQueue)
        
        (logFile, logOverflowFile, fileDispatchQueue) = LogRecorder.getFilesForLogLevel(LogLevel.Info)
        
        XCTAssertTrue(logFile == pathToLoggerFile)
        XCTAssertTrue(logOverflowFile == pathToLoggerFileOverflow)
        XCTAssertNotNil(fileDispatchQueue)
        
        (logFile, logOverflowFile, fileDispatchQueue) = LogRecorder.getFilesForLogLevel(LogLevel.Error)
        
        XCTAssertTrue(logFile == pathToLoggerFile)
        XCTAssertTrue(logOverflowFile == pathToLoggerFileOverflow)
        XCTAssertNotNil(fileDispatchQueue)
        
        (logFile, logOverflowFile, fileDispatchQueue) = LogRecorder.getFilesForLogLevel(LogLevel.Analytics)
        
        XCTAssertTrue(logFile == pathToAnalyticsFile)
        XCTAssertTrue(logOverflowFile == pathToAnalyticsFileOverflow)
        XCTAssertNotNil(fileDispatchQueue)
    }

    
    func testGetLogs(){
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
        
        guard let logs: String = LoggerTests.getLogs(LogFileType.LOGGER) else {
            XCTFail()
            return
        }
        
        XCTAssertTrue(NSFileManager().fileExistsAtPath(pathToBuffer))
        
        let fileContents = "[\(logs)]"
        
        let logDict : NSData = fileContents.dataUsingEncoding(NSUTF8StringEncoding)!
        guard let jsonDict = LoggerTests.convertLogsToJson(logDict) else {
            XCTFail()
            return
        }
        
        let debugMessage = jsonDict[0]
        XCTAssertTrue(debugMessage[Logger.TAG_MESSAGE] == "Hello world")
        XCTAssertTrue(debugMessage[Logger.TAG_PACKAGE] == fakePKG)
        XCTAssertTrue(debugMessage[Logger.TAG_TIMESTAMP] != nil)
        XCTAssertTrue(debugMessage[Logger.TAG_LEVEL] == "DEBUG")
        
        let infoMessage = jsonDict[1]
        XCTAssertTrue(infoMessage[Logger.TAG_MESSAGE] == "1242342342343243242342")
        XCTAssertTrue(infoMessage[Logger.TAG_PACKAGE] == fakePKG)
        XCTAssertTrue(infoMessage[Logger.TAG_TIMESTAMP] != nil)
        XCTAssertTrue(infoMessage[Logger.TAG_LEVEL] == "INFO")
        
        let warnMessage = jsonDict[2]
        XCTAssertTrue(warnMessage[Logger.TAG_MESSAGE] == "Str: heyoooooo")
        XCTAssertTrue(warnMessage[Logger.TAG_PACKAGE] == fakePKG)
        XCTAssertTrue(warnMessage[Logger.TAG_TIMESTAMP] != nil)
        XCTAssertTrue(warnMessage[Logger.TAG_LEVEL] == "WARN")
        
        let errorMessage = jsonDict[3]
        XCTAssertTrue(errorMessage[Logger.TAG_MESSAGE] == "1 2 3 4")
        XCTAssertTrue(errorMessage[Logger.TAG_PACKAGE] == fakePKG)
        XCTAssertTrue(errorMessage[Logger.TAG_TIMESTAMP] != nil)
        XCTAssertTrue(errorMessage[Logger.TAG_LEVEL] == "ERROR")
        
        let fatalMessage = jsonDict[4]
        XCTAssertTrue(fatalMessage[Logger.TAG_MESSAGE] == "StephenColbert")
        XCTAssertTrue(fatalMessage[Logger.TAG_PACKAGE] == fakePKG)
        XCTAssertTrue(fatalMessage[Logger.TAG_TIMESTAMP] != nil)
        XCTAssertTrue(fatalMessage[Logger.TAG_LEVEL] == "FATAL")
    }
    
    
    func testGetLogWithAnalytics(){
        let fakePKG = "MYPKG"
        let pathToFile = Logger.logsDocumentPath + Logger.FILE_ANALYTICS_LOGS
        let pathToBuffer = Logger.logsDocumentPath + Logger.FILE_ANALYTICS_SEND
        
        do {
            try NSFileManager().removeItemAtPath(pathToFile)
            
        } catch {
            
        }
        
        do {
            try NSFileManager().removeItemAtPath(pathToBuffer)
            
        } catch {
            
        }
        
        let loggerInstance = Logger.getLoggerForName(fakePKG)
        Analytics.enabled = true
        Logger.logLevelFilter = LogLevel.Debug
        Logger.maxLogStoreSize = Logger.DEFAULT_MAX_STORE_SIZE
        let meta = ["hello": 1]
        
        loggerInstance.analytics(meta)
        
        guard let logs: String = LoggerTests.getLogs(LogFileType.ANALYTICS) else {
            XCTFail()
            return
        }
        
        let bufferFile = NSFileManager().fileExistsAtPath(pathToBuffer)
        
        XCTAssertTrue(bufferFile)
        
        let fileContents = "[\(logs)]"
        
        let logDict : NSData = fileContents.dataUsingEncoding(NSUTF8StringEncoding)!
        guard let jsonDict = LoggerTests.convertLogsToJson(logDict) else {
            XCTFail()
            return
        }
        
        let analyticsMessage = jsonDict[0]
        XCTAssertTrue(analyticsMessage[Logger.TAG_MESSAGE] == "")
        XCTAssertTrue(analyticsMessage[Logger.TAG_PACKAGE] == fakePKG)
        XCTAssertTrue(analyticsMessage[Logger.TAG_TIMESTAMP] != nil)
        XCTAssertTrue(analyticsMessage[Logger.TAG_LEVEL] == "ANALYTICS")
        XCTAssertTrue(analyticsMessage[Logger.TAG_METADATA] == meta)
    }
    
    
    func testOverFlowLogging(){
        let fakePKG = "MYPKG"
        let pathToFile = Logger.logsDocumentPath + Logger.FILE_LOGGER_LOGS
        let pathToOverflow = Logger.logsDocumentPath + Logger.FILE_LOGGER_OVERFLOW
        
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
        
        let loggerInstance = Logger.getLoggerForName(fakePKG)
        guard let largeData = LoggerTests.getFileContents(path!) else {
            XCTFail()
            return
        }
        
        Logger.logStoreEnabled = true
        Logger.sdkDebugLoggingEnabled = false
        Logger.logLevelFilter = LogLevel.Debug
        Logger.maxLogStoreSize = Logger.DEFAULT_MAX_STORE_SIZE
        
        loggerInstance.debug(largeData)
        loggerInstance.info("1242342342343243242342")
        loggerInstance.warn("Str: heyoooooo")
        loggerInstance.error("1 2 3 4")
        loggerInstance.fatal("StephenColbert")
        
        XCTAssertTrue(NSFileManager().fileExistsAtPath(pathToOverflow))
        
        guard let formattedContents = LoggerTests.getFileContents(pathToFile) else {
            XCTFail()
            return
        }
        var fileContents = "[\(formattedContents)]"
        var logDict : NSData = fileContents.dataUsingEncoding(NSUTF8StringEncoding)!
        guard let jsonDict = LoggerTests.convertLogsToJson(logDict) else {
            XCTFail()
            return
        }
        
        let infoMessage = jsonDict[0]
        XCTAssertTrue(infoMessage[Logger.TAG_MESSAGE] == "1242342342343243242342")
        XCTAssertTrue(infoMessage[Logger.TAG_PACKAGE] == fakePKG)
        XCTAssertTrue(infoMessage[Logger.TAG_TIMESTAMP] != nil)
        XCTAssertTrue(infoMessage[Logger.TAG_LEVEL] == "INFO")
        
        let warnMessage = jsonDict[1]
        XCTAssertTrue(warnMessage[Logger.TAG_MESSAGE] == "Str: heyoooooo")
        XCTAssertTrue(warnMessage[Logger.TAG_PACKAGE] == fakePKG)
        XCTAssertTrue(warnMessage[Logger.TAG_TIMESTAMP] != nil)
        XCTAssertTrue(warnMessage[Logger.TAG_LEVEL] == "WARN")
        
        let errorMessage = jsonDict[2]
        XCTAssertTrue(errorMessage[Logger.TAG_MESSAGE] == "1 2 3 4")
        XCTAssertTrue(errorMessage[Logger.TAG_PACKAGE] == fakePKG)
        XCTAssertTrue(errorMessage[Logger.TAG_TIMESTAMP] != nil)
        XCTAssertTrue(errorMessage[Logger.TAG_LEVEL] == "ERROR")
        
        let fatalMessage = jsonDict[3]
        XCTAssertTrue(fatalMessage[Logger.TAG_MESSAGE] == "StephenColbert")
        XCTAssertTrue(fatalMessage[Logger.TAG_PACKAGE] == fakePKG)
        XCTAssertTrue(fatalMessage[Logger.TAG_TIMESTAMP] != nil)
        XCTAssertTrue(fatalMessage[Logger.TAG_LEVEL] == "FATAL")
        
        guard let newFormattedContents = LoggerTests.getFileContents(pathToOverflow) else {
            XCTFail()
            return
        }
        fileContents = "[\(newFormattedContents)]"
        logDict  = fileContents.dataUsingEncoding(NSUTF8StringEncoding)!
        guard let newJsonDict = LoggerTests.convertLogsToJson(logDict) else {
            XCTFail()
            return
        }
        
        
        let overflowMessage = newJsonDict[0]
        XCTAssertTrue(overflowMessage[Logger.TAG_MESSAGE] == largeData)
        XCTAssertTrue(overflowMessage[Logger.TAG_PACKAGE] == fakePKG)
        XCTAssertTrue(overflowMessage[Logger.TAG_TIMESTAMP] != nil)
        XCTAssertTrue(overflowMessage[Logger.TAG_LEVEL] == "DEBUG")
    }
    
    
    func testExistingOverflowFile(){
        let fakePKG = "MYPKG"
        let pathToFile = Logger.logsDocumentPath + Logger.FILE_LOGGER_LOGS
        let pathToOverflow = Logger.logsDocumentPath + Logger.FILE_LOGGER_OVERFLOW
        
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
        
        guard let largeData = LoggerTests.getFileContents(path!) else {
            XCTFail()
            return
        }
        
        
        let loggerInstance = Logger.getLoggerForName(fakePKG)
        Logger.logStoreEnabled = true
        Logger.sdkDebugLoggingEnabled = false
        Logger.logLevelFilter = LogLevel.Debug
        Logger.maxLogStoreSize = Logger.DEFAULT_MAX_STORE_SIZE
        
        loggerInstance.debug(largeData)
        loggerInstance.info(largeData)
        loggerInstance.warn(largeData)
        loggerInstance.error(largeData)
        loggerInstance.fatal(largeData)
        
        
        XCTAssertTrue(NSFileManager().fileExistsAtPath(pathToOverflow))
        
        guard let formattedContents = LoggerTests.getFileContents(pathToOverflow) else {
            XCTFail()
            return
        }
        
        
        var fileContents = "[\(formattedContents)]"
        var logDict : NSData = fileContents.dataUsingEncoding(NSUTF8StringEncoding)!
        guard let jsonDict = LoggerTests.convertLogsToJson(logDict) else {
            XCTFail()
            return
        }
        
        XCTAssertTrue(jsonDict.count == 1)
        
        loggerInstance.debug(largeData)
        
        
        guard let newFormattedContents = LoggerTests.getFileContents(pathToOverflow) else {
            XCTFail()
            return
        }
        fileContents = "[\(newFormattedContents)]"
        logDict  = fileContents.dataUsingEncoding(NSUTF8StringEncoding)!
        guard let newJsonDict = LoggerTests.convertLogsToJson(logDict) else {
            XCTFail()
            return
        }
        
        XCTAssertTrue(newJsonDict.count == 1)
    }
    

}
