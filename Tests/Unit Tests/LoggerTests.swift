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


class LoggerTests: XCTestCase {
    
    
    func testIsUncaughtException(){

        Logger.isUncaughtExceptionDetected = false
        XCTAssertFalse(Logger.isUncaughtExceptionDetected)
        Logger.isUncaughtExceptionDetected = true
        XCTAssertTrue(Logger.isUncaughtExceptionDetected)
    }

    
    func testSetGetMaxLogStoreSize(){
    
        let size1 = Logger.maxLogStoreSize
        XCTAssertTrue(size1 == Logger.DEFAULT_MAX_STORE_SIZE)

        Logger.maxLogStoreSize = 12345678 as UInt64
        let size3 = Logger.maxLogStoreSize
        XCTAssertTrue(size3 == 12345678)
    }

    
    func testlogStoreEnabled(){
        
        let capture1 = Logger.logStoreEnabled
        XCTAssertTrue(capture1, "should default to true");

        Logger.logStoreEnabled = false
    
        let capture2 = Logger.logStoreEnabled
        XCTAssertFalse(capture2)
    }
    
    
    func testAnalyticsLog(){
        let fakePKG = "MYPKG"
        let pathToFile = Logger.logsDocumentPath + Logger.FILE_ANALYTICS_LOGS
        
        do {
            try NSFileManager().removeItemAtPath(pathToFile)
        } catch {
            print("Could not delete " + pathToFile)
        }
        
        let loggerInstance = Logger.getLoggerForName(fakePKG)
        Logger.logStoreEnabled = true
        Logger.logLevelFilter = LogLevel.Analytics
        Logger.maxLogStoreSize = Logger.DEFAULT_MAX_STORE_SIZE
        let meta = ["hello": 1]
        
        loggerInstance.analytics(meta)
        
        guard let formattedContents = LoggerTests.getFileContents(pathToFile) else {
            XCTFail()
            return
        }
        let fileContents = "[\(formattedContents)]"
        let logDict : NSData = fileContents.dataUsingEncoding(NSUTF8StringEncoding)!
        guard let jsonDict = LoggerTests.convertLogsToJson(logDict) else {
            XCTFail()
            return
        }
        
        let debugMessage = jsonDict[0]
        XCTAssertTrue(debugMessage[Logger.TAG_MESSAGE] == "")
        XCTAssertTrue(debugMessage[Logger.TAG_PACKAGE] == fakePKG)
        XCTAssertTrue(debugMessage[Logger.TAG_TIMESTAMP] != nil)
        XCTAssertTrue(debugMessage[Logger.TAG_LEVEL] == "ANALYTICS")
        print(debugMessage[Logger.TAG_METADATA])
        XCTAssertTrue(debugMessage[Logger.TAG_METADATA] == meta)
    }
    
    
    func testDisableAnalyticsLogging(){
        let fakePKG = "MYPKG"
        let pathToFile = Logger.logsDocumentPath + Logger.FILE_ANALYTICS_LOGS
        
        do {
            try NSFileManager().removeItemAtPath(pathToFile)
        } catch {
            print("Could not delete " + pathToFile)
        }
        
        let loggerInstance = Logger.getLoggerForName(fakePKG)
        Logger.logLevelFilter = LogLevel.Analytics
        Analytics.enabled = false
        Logger.maxLogStoreSize = Logger.DEFAULT_MAX_STORE_SIZE
        let meta = ["hello": 1]
        
        loggerInstance.analytics(meta)
        
        let fileExists = NSFileManager().fileExistsAtPath(pathToFile)
        
        XCTAssertFalse(fileExists)
    }
    
    
    func testNoInternalLogging(){
        let fakePKG = Logger.MFP_LOGGER_PACKAGE
        let pathToFile = Logger.logsDocumentPath + Logger.FILE_LOGGER_LOGS
        
        do {
            try NSFileManager().removeItemAtPath(pathToFile)
        } catch {
            print("Could not delete " + pathToFile)
        }
        
        let loggerInstance = Logger.getLoggerForName(fakePKG)
        Logger.logStoreEnabled = true
        Logger.logLevelFilter = LogLevel.Debug
        Logger.maxLogStoreSize = Logger.DEFAULT_MAX_STORE_SIZE
        Logger.sdkDebugLoggingEnabled = false
        
        loggerInstance.debug("Hello world")
        loggerInstance.info("1242342342343243242342")
        loggerInstance.warn("Str: heyoooooo")
        loggerInstance.error("1 2 3 4")
        loggerInstance.fatal("StephenColbert")

        guard let formattedContents = LoggerTests.getFileContents(pathToFile) else {
            XCTFail()
            return
        }
        let fileContents = "[\(formattedContents)]"
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
    }

    
    func testLogMethods(){
        let fakePKG = "MYPKG"
        let pathToFile = Logger.logsDocumentPath + Logger.FILE_LOGGER_LOGS
        
        do {
            try NSFileManager().removeItemAtPath(pathToFile)
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
    
        
        guard let formattedContents = LoggerTests.getFileContents(pathToFile) else {
            XCTFail()
            return
        }
        let fileContents = "[\(formattedContents)]"
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
    }
    
    
    func testLogWithNone(){
        let fakePKG = "MYPKG"
        let pathToFile = Logger.logsDocumentPath + Logger.FILE_LOGGER_LOGS
        
        do {
            try NSFileManager().removeItemAtPath(pathToFile)
        } catch {
            
        }
        
        let loggerInstance = Logger.getLoggerForName(fakePKG)
        Logger.logStoreEnabled = true
        Logger.logLevelFilter = LogLevel.None
        Logger.maxLogStoreSize = Logger.DEFAULT_MAX_STORE_SIZE
        
        loggerInstance.debug("Hello world")
        loggerInstance.info("1242342342343243242342")
        loggerInstance.warn("Str: heyoooooo")
        loggerInstance.error("1 2 3 4")
        loggerInstance.fatal("StephenColbert")
        
        XCTAssertFalse(NSFileManager().fileExistsAtPath(pathToFile))
    }
    
    
    func testIncorrectLogLevel(){
        let fakePKG = "MYPKG"
        let pathToFile = Logger.logsDocumentPath + Logger.FILE_LOGGER_LOGS
        
        do {
            try NSFileManager().removeItemAtPath(pathToFile)
        } catch {
            
        }
        
        let loggerInstance = Logger.getLoggerForName(fakePKG)
        Logger.logStoreEnabled = true
        Logger.logLevelFilter = LogLevel.Fatal
        Logger.maxLogStoreSize = Logger.DEFAULT_MAX_STORE_SIZE
        
        loggerInstance.debug("Hello world")
        loggerInstance.info("1242342342343243242342")
        loggerInstance.warn("Str: heyoooooo")
        loggerInstance.error("1 2 3 4")
        
        let fileExists = NSFileManager().fileExistsAtPath(pathToFile)
        
        XCTAssertFalse(fileExists)
    }
    
    
    func testDisableLogging(){
        let fakePKG = "MYPKG"
        let pathToFile = Logger.logsDocumentPath + Logger.FILE_LOGGER_LOGS
        
        do {
            try NSFileManager().removeItemAtPath(pathToFile)
        } catch {
            
        }
        
        let loggerInstance = Logger.getLoggerForName(fakePKG)
        Logger.logStoreEnabled = false
        Logger.logLevelFilter = LogLevel.Debug
        Logger.maxLogStoreSize = Logger.DEFAULT_MAX_STORE_SIZE
        
        loggerInstance.debug("Hello world")
        loggerInstance.info("1242342342343243242342")
        loggerInstance.warn("Str: heyoooooo")
        loggerInstance.error("1 2 3 4")
        loggerInstance.fatal("StephenColbert")
        
        let fileExists = NSFileManager().fileExistsAtPath(pathToFile)
        
        XCTAssertFalse(fileExists)
    }
    
    
    func testLogException(){
        let pathToFile = Logger.logsDocumentPath + Logger.FILE_LOGGER_LOGS
        
        do {
            try NSFileManager().removeItemAtPath(pathToFile)
        } catch {
            
        }
        
        let e = NSException(name:"crashApp", reason:"No reason at all just doing it for fun", userInfo:["user":"nana"])
        
        Logger.logException(e)
        
        guard let formattedContents = LoggerTests.getFileContents(pathToFile) else {
            XCTFail()
            return
        }
        let fileContents = "[\(formattedContents)]"
        let reason = e.reason!
        let errorMessage = "Uncaught Exception: \(e.name)." + " Reason: \(reason)."
        let logDict : NSData = fileContents.dataUsingEncoding(NSUTF8StringEncoding)!
        guard let jsonDict = LoggerTests.convertLogsToJson(logDict) else {
            XCTFail()
            return
        }
        
        let exception = jsonDict[0]
        XCTAssertTrue(exception[Logger.TAG_MESSAGE] == errorMessage)
        XCTAssertTrue(exception[Logger.TAG_PACKAGE] == Logger.MFP_LOGGER_PACKAGE)
        XCTAssertTrue(exception[Logger.TAG_TIMESTAMP] != nil)
        XCTAssertTrue(exception[Logger.TAG_LEVEL] == "FATAL")
    }
    
    
    
    // MARK: Helpers
    
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
                return try LogSender.getLogs(fileName: Logger.FILE_LOGGER_LOGS, overflowFileName: Logger.FILE_LOGGER_OVERFLOW, bufferFileName: Logger.FILE_LOGGER_SEND)
            case .ANALYTICS:
                return try LogSender.getLogs(fileName: Logger.FILE_ANALYTICS_LOGS, overflowFileName: Logger.FILE_ANALYTICS_OVERFLOW, bufferFileName: Logger.FILE_ANALYTICS_SEND)
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

