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


class LoggerTests: XCTestCase {
    
    
    func testIsUncaughtException(){

        Logger.isUncaughtExceptionDetected = false
        XCTAssertFalse(Logger.isUncaughtExceptionDetected)
        Logger.isUncaughtExceptionDetected = true
        XCTAssertTrue(Logger.isUncaughtExceptionDetected)
    }

    
    func testSetGetMaxLogStoreSize(){
    
        let size1 = Logger.maxLogStoreSize
        XCTAssertTrue(size1 == Constants.File.defaultMaxSize)

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
        let pathToFile = Logger.logsDocumentPath + Constants.File.Analytics.logs
        
        do {
            try NSFileManager().removeItemAtPath(pathToFile)
        } catch {
            print("Could not delete " + pathToFile)
        }
        
        let loggerInstance = Logger.loggerForName(fakePKG)
        Logger.logStoreEnabled = true
        Logger.logLevelFilter = LogLevel.Analytics
        Logger.maxLogStoreSize = Constants.File.defaultMaxSize
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
        XCTAssertTrue(debugMessage[Constants.Metadata.Logger.message] == "")
        XCTAssertTrue(debugMessage[Constants.Metadata.Logger.package] == fakePKG)
        XCTAssertTrue(debugMessage[Constants.Metadata.Logger.timestamp] != nil)
        XCTAssertTrue(debugMessage[Constants.Metadata.Logger.level] == "ANALYTICS")
        print(debugMessage[Constants.Metadata.Logger.metadata])
        XCTAssertTrue(debugMessage[Constants.Metadata.Logger.metadata] == meta)
    }
    
    
    func testDisableAnalyticsLogging(){
        let fakePKG = "MYPKG"
        let pathToFile = Logger.logsDocumentPath + Constants.File.Analytics.logs
        
        do {
            try NSFileManager().removeItemAtPath(pathToFile)
        } catch {
            print("Could not delete " + pathToFile)
        }
        
        let loggerInstance = Logger.loggerForName(fakePKG)
        Logger.logLevelFilter = LogLevel.Analytics
        Analytics.enabled = false
        Logger.maxLogStoreSize = Constants.File.defaultMaxSize
        let meta = ["hello": 1]
        
        loggerInstance.analytics(meta)
        
        let fileExists = NSFileManager().fileExistsAtPath(pathToFile)
        
        XCTAssertFalse(fileExists)
    }
    
    
    func testNoInternalLogging(){
        let fakePKG = Constants.Package.logger
        let pathToFile = Logger.logsDocumentPath + Constants.File.Logger.logs
        
        do {
            try NSFileManager().removeItemAtPath(pathToFile)
        } catch {
            print("Could not delete " + pathToFile)
        }
        
        let loggerInstance = Logger.loggerForName(fakePKG)
        Logger.logStoreEnabled = true
        Logger.logLevelFilter = LogLevel.Debug
        Logger.maxLogStoreSize = Constants.File.defaultMaxSize
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
        let pathToFile = Logger.logsDocumentPath + Constants.File.Logger.logs
        
        do {
            try NSFileManager().removeItemAtPath(pathToFile)
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
        let pathToFile = Logger.logsDocumentPath + Constants.File.Logger.logs
        
        do {
            try NSFileManager().removeItemAtPath(pathToFile)
        } catch {
            
        }
        
        let loggerInstance = Logger.loggerForName(fakePKG)
        Logger.logStoreEnabled = true
        Logger.logLevelFilter = LogLevel.None
        Logger.maxLogStoreSize = Constants.File.defaultMaxSize
        
        loggerInstance.debug("Hello world")
        loggerInstance.info("1242342342343243242342")
        loggerInstance.warn("Str: heyoooooo")
        loggerInstance.error("1 2 3 4")
        loggerInstance.fatal("StephenColbert")
        
        XCTAssertFalse(NSFileManager().fileExistsAtPath(pathToFile))
    }
    
    
    func testIncorrectLogLevel(){
        let fakePKG = "MYPKG"
        let pathToFile = Logger.logsDocumentPath + Constants.File.Logger.logs
        
        do {
            try NSFileManager().removeItemAtPath(pathToFile)
        } catch {
            
        }
        
        let loggerInstance = Logger.loggerForName(fakePKG)
        Logger.logStoreEnabled = true
        Logger.logLevelFilter = LogLevel.Fatal
        Logger.maxLogStoreSize = Constants.File.defaultMaxSize
        
        loggerInstance.debug("Hello world")
        loggerInstance.info("1242342342343243242342")
        loggerInstance.warn("Str: heyoooooo")
        loggerInstance.error("1 2 3 4")
        
        let fileExists = NSFileManager().fileExistsAtPath(pathToFile)
        
        XCTAssertFalse(fileExists)
    }
    
    
    func testDisableLogging(){
        let fakePKG = "MYPKG"
        let pathToFile = Logger.logsDocumentPath + Constants.File.Logger.logs
        
        do {
            try NSFileManager().removeItemAtPath(pathToFile)
        } catch {
            
        }
        
        let loggerInstance = Logger.loggerForName(fakePKG)
        Logger.logStoreEnabled = false
        Logger.logLevelFilter = LogLevel.Debug
        Logger.maxLogStoreSize = Constants.File.defaultMaxSize
        
        loggerInstance.debug("Hello world")
        loggerInstance.info("1242342342343243242342")
        loggerInstance.warn("Str: heyoooooo")
        loggerInstance.error("1 2 3 4")
        loggerInstance.fatal("StephenColbert")
        
        let fileExists = NSFileManager().fileExistsAtPath(pathToFile)
        
        XCTAssertFalse(fileExists)
    }
    
    
    func testLogException(){
        let pathToFile = Logger.logsDocumentPath + Constants.File.Logger.logs
        
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
        XCTAssertTrue(exception[Constants.Metadata.Logger.message] == errorMessage)
        XCTAssertTrue(exception[Constants.Metadata.Logger.package] == Constants.Package.logger)
        XCTAssertTrue(exception[Constants.Metadata.Logger.timestamp] != nil)
        XCTAssertTrue(exception[Constants.Metadata.Logger.level] == "FATAL")
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
                return try LogSender.getLogs(fileName: Constants.File.Logger.logs, overflowFileName: Constants.File.Logger.overflowLogs, bufferFileName: Constants.File.Logger.outboundLogs)
            case .ANALYTICS:
                return try LogSender.getLogs(fileName: Constants.File.Analytics.logs, overflowFileName: Constants.File.Analytics.overflowLogs, bufferFileName: Constants.File.Analytics.outboundLogs)
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

