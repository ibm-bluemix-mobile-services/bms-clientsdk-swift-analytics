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
@testable import MFPAnalytics


class LogRecorderTests: XCTestCase {

    func testGetFilesForLogLevel(){
        let pathToLoggerFile = Logger.logsDocumentPath + Constants.File.Logger.logs
        let pathToAnalyticsFile = Logger.logsDocumentPath + Constants.File.Analytics.logs
        let pathToLoggerFileOverflow = Logger.logsDocumentPath + Constants.File.Logger.overflowLogs
        let pathToAnalyticsFileOverflow = Logger.logsDocumentPath + Constants.File.Analytics.overflowLogs
        
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
        
        let loggerInstance = Logger.loggerForName(fakePKG)
        Logger.logStoreEnabled = true
        Logger.logLevelFilter = LogLevel.Debug
        Logger.maxLogStoreSize = Constants.File.defaultMaxSize
        
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
        let fakePKG = "MYPKG"
        let pathToFile = Logger.logsDocumentPath + Constants.File.Analytics.logs
        let pathToBuffer = Logger.logsDocumentPath + Constants.File.Analytics.outboundLogs
        
        do {
            try NSFileManager().removeItemAtPath(pathToFile)
            
        } catch {
            
        }
        
        do {
            try NSFileManager().removeItemAtPath(pathToBuffer)
            
        } catch {
            
        }
        
        let loggerInstance = Logger.loggerForName(fakePKG)
        Analytics.enabled = true
        Logger.logLevelFilter = LogLevel.Debug
        Logger.maxLogStoreSize = Constants.File.defaultMaxSize
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
        XCTAssertTrue(analyticsMessage[Constants.Metadata.Logger.message] == "")
        XCTAssertTrue(analyticsMessage[Constants.Metadata.Logger.package] == fakePKG)
        XCTAssertTrue(analyticsMessage[Constants.Metadata.Logger.timestamp] != nil)
        XCTAssertTrue(analyticsMessage[Constants.Metadata.Logger.level] == "ANALYTICS")
        XCTAssertTrue(analyticsMessage[Constants.Metadata.Logger.metadata] == meta)
    }
    
    
    func testOverFlowLogging(){
        let fakePKG = "MYPKG"
        let pathToFile = Logger.logsDocumentPath + Constants.File.Logger.logs
        let pathToOverflow = Logger.logsDocumentPath + Constants.File.Logger.overflowLogs
        
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
        
        let loggerInstance = Logger.loggerForName(fakePKG)
        guard let largeData = LoggerTests.getFileContents(path!) else {
            XCTFail()
            return
        }
        
        Logger.logStoreEnabled = true
        Logger.sdkDebugLoggingEnabled = false
        Logger.logLevelFilter = LogLevel.Debug
        Logger.maxLogStoreSize = Constants.File.defaultMaxSize
        
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
        XCTAssertTrue(overflowMessage[Constants.Metadata.Logger.message] == largeData)
        XCTAssertTrue(overflowMessage[Constants.Metadata.Logger.package] == fakePKG)
        XCTAssertTrue(overflowMessage[Constants.Metadata.Logger.timestamp] != nil)
        XCTAssertTrue(overflowMessage[Constants.Metadata.Logger.level] == "DEBUG")
    }
    
    
    func testExistingOverflowFile(){
        let fakePKG = "MYPKG"
        let pathToFile = Logger.logsDocumentPath + Constants.File.Logger.logs
        let pathToOverflow = Logger.logsDocumentPath + Constants.File.Logger.overflowLogs
        
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
        
        
        let loggerInstance = Logger.loggerForName(fakePKG)
        Logger.logStoreEnabled = true
        Logger.sdkDebugLoggingEnabled = false
        Logger.logLevelFilter = LogLevel.Debug
        Logger.maxLogStoreSize = Constants.File.defaultMaxSize
        
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
