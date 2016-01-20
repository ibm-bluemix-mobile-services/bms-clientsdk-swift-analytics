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
    
    func testGetFilesForLogLevel(){
        let fakePKG = "MYPKG"
        let pathToLoggerFile = Logger.logsDocumentPath + Logger.FILE_LOGGER_LOGS
        let pathToAnalyticsFile = Logger.logsDocumentPath + Logger.FILE_ANALYTICS_LOGS
        let pathToLoggerFileOverflow = Logger.logsDocumentPath + Logger.FILE_LOGGER_OVERFLOW
        let pathToAnalyticsFileOverflow = Logger.logsDocumentPath + Logger.FILE_ANALYTICS_OVERFLOW
        
        let loggerInstance = Logger.getLoggerForName(fakePKG)
    
        var (logFile, logOverflowFile, fileDispatchQueue) = loggerInstance.getFilesForLogLevel(LogLevel.Debug)
        
        XCTAssertTrue(logFile == pathToLoggerFile)
        XCTAssertTrue(logOverflowFile == pathToLoggerFileOverflow)
        XCTAssertNotNil(fileDispatchQueue)
        
        (logFile, logOverflowFile, fileDispatchQueue) = loggerInstance.getFilesForLogLevel(LogLevel.Error)
        
        XCTAssertTrue(logFile == pathToLoggerFile)
        XCTAssertTrue(logOverflowFile == pathToLoggerFileOverflow)
        XCTAssertNotNil(fileDispatchQueue)
        
        (logFile, logOverflowFile, fileDispatchQueue) = loggerInstance.getFilesForLogLevel(LogLevel.Fatal)
        
        XCTAssertTrue(logFile == pathToLoggerFile)
        XCTAssertTrue(logOverflowFile == pathToLoggerFileOverflow)
        XCTAssertNotNil(fileDispatchQueue)
        
        (logFile, logOverflowFile, fileDispatchQueue) = loggerInstance.getFilesForLogLevel(LogLevel.Info)
        
        XCTAssertTrue(logFile == pathToLoggerFile)
        XCTAssertTrue(logOverflowFile == pathToLoggerFileOverflow)
        XCTAssertNotNil(fileDispatchQueue)
        
        (logFile, logOverflowFile, fileDispatchQueue) = loggerInstance.getFilesForLogLevel(LogLevel.Error)
        
        XCTAssertTrue(logFile == pathToLoggerFile)
        XCTAssertTrue(logOverflowFile == pathToLoggerFileOverflow)
        XCTAssertNotNil(fileDispatchQueue)
        
        (logFile, logOverflowFile, fileDispatchQueue) = loggerInstance.getFilesForLogLevel(LogLevel.Analytics)
        
        XCTAssertTrue(logFile == pathToAnalyticsFile)
        XCTAssertTrue(logOverflowFile == pathToAnalyticsFileOverflow)
        XCTAssertNotNil(fileDispatchQueue)

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
        
        let formattedContents = try! String(contentsOfFile: pathToFile, encoding: NSUTF8StringEncoding)
        let fileContents = "[\(formattedContents)]"
        let logDict : NSData = fileContents.dataUsingEncoding(NSUTF8StringEncoding)!
        let jsonDict: AnyObject? = try! NSJSONSerialization.JSONObjectWithData(logDict, options:NSJSONReadingOptions.MutableContainers)
        
        let debugMessage = jsonDict![0]
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

        let formattedContents = try! String(contentsOfFile: pathToFile, encoding: NSUTF8StringEncoding)
        let fileContents = "[\(formattedContents)]"
        let logDict : NSData = fileContents.dataUsingEncoding(NSUTF8StringEncoding)!
        let jsonDict: AnyObject? = try! NSJSONSerialization.JSONObjectWithData(logDict, options:NSJSONReadingOptions.MutableContainers)
        
        let debugMessage = jsonDict![0]
        XCTAssertTrue(debugMessage[Logger.TAG_MESSAGE] == "Hello world")
        XCTAssertTrue(debugMessage[Logger.TAG_PACKAGE] == fakePKG)
        XCTAssertTrue(debugMessage[Logger.TAG_TIMESTAMP] != nil)
        XCTAssertTrue(debugMessage[Logger.TAG_LEVEL] == "DEBUG")
        
        let infoMessage = jsonDict![1]
        XCTAssertTrue(infoMessage[Logger.TAG_MESSAGE] == "1242342342343243242342")
        XCTAssertTrue(infoMessage[Logger.TAG_PACKAGE] == fakePKG)
        XCTAssertTrue(infoMessage[Logger.TAG_TIMESTAMP] != nil)
        XCTAssertTrue(infoMessage[Logger.TAG_LEVEL] == "INFO")
        
        let warnMessage = jsonDict![2]
        XCTAssertTrue(warnMessage[Logger.TAG_MESSAGE] == "Str: heyoooooo")
        XCTAssertTrue(warnMessage[Logger.TAG_PACKAGE] == fakePKG)
        XCTAssertTrue(warnMessage[Logger.TAG_TIMESTAMP] != nil)
        XCTAssertTrue(warnMessage[Logger.TAG_LEVEL] == "WARN")
        
        let errorMessage = jsonDict![3]
        XCTAssertTrue(errorMessage[Logger.TAG_MESSAGE] == "1 2 3 4")
        XCTAssertTrue(errorMessage[Logger.TAG_PACKAGE] == fakePKG)
        XCTAssertTrue(errorMessage[Logger.TAG_TIMESTAMP] != nil)
        XCTAssertTrue(errorMessage[Logger.TAG_LEVEL] == "ERROR")
        
        let fatalMessage = jsonDict![4]
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
    
        
        let formattedContents = try! String(contentsOfFile: pathToFile, encoding: NSUTF8StringEncoding)
        let fileContents = "[\(formattedContents)]"
        let logDict : NSData = fileContents.dataUsingEncoding(NSUTF8StringEncoding)!
        let jsonDict: AnyObject? = try! NSJSONSerialization.JSONObjectWithData(logDict, options:NSJSONReadingOptions.MutableContainers)

        let debugMessage = jsonDict![0]
        XCTAssertTrue(debugMessage[Logger.TAG_MESSAGE] == "Hello world")
        XCTAssertTrue(debugMessage[Logger.TAG_PACKAGE] == fakePKG)
        XCTAssertTrue(debugMessage[Logger.TAG_TIMESTAMP] != nil)
        XCTAssertTrue(debugMessage[Logger.TAG_LEVEL] == "DEBUG")

        let infoMessage = jsonDict![1]
        XCTAssertTrue(infoMessage[Logger.TAG_MESSAGE] == "1242342342343243242342")
        XCTAssertTrue(infoMessage[Logger.TAG_PACKAGE] == fakePKG)
        XCTAssertTrue(infoMessage[Logger.TAG_TIMESTAMP] != nil)
        XCTAssertTrue(infoMessage[Logger.TAG_LEVEL] == "INFO")

        let warnMessage = jsonDict![2]
        XCTAssertTrue(warnMessage[Logger.TAG_MESSAGE] == "Str: heyoooooo")
        XCTAssertTrue(warnMessage[Logger.TAG_PACKAGE] == fakePKG)
        XCTAssertTrue(warnMessage[Logger.TAG_TIMESTAMP] != nil)
        XCTAssertTrue(warnMessage[Logger.TAG_LEVEL] == "WARN")

        let errorMessage = jsonDict![3]
        XCTAssertTrue(errorMessage[Logger.TAG_MESSAGE] == "1 2 3 4")
        XCTAssertTrue(errorMessage[Logger.TAG_PACKAGE] == fakePKG)
        XCTAssertTrue(errorMessage[Logger.TAG_TIMESTAMP] != nil)
        XCTAssertTrue(errorMessage[Logger.TAG_LEVEL] == "ERROR")

        let fatalMessage = jsonDict![4]
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
        
        let formattedContents = try! String(contentsOfFile: pathToFile, encoding: NSUTF8StringEncoding)
        let fileContents = "[\(formattedContents)]"
        let reason = e.reason!
        let errorMessage = "Uncaught Exception: \(e.name)." + " Reason: \(reason)."
        let logDict : NSData = fileContents.dataUsingEncoding(NSUTF8StringEncoding)!
        let jsonDict: AnyObject? = try! NSJSONSerialization.JSONObjectWithData(logDict, options:NSJSONReadingOptions.MutableContainers)
        
        let exception = jsonDict![0]
        XCTAssertTrue(exception[Logger.TAG_MESSAGE] == errorMessage)
        XCTAssertTrue(exception[Logger.TAG_PACKAGE] == Logger.MFP_LOGGER_PACKAGE)
        XCTAssertTrue(exception[Logger.TAG_TIMESTAMP] != nil)
        XCTAssertTrue(exception[Logger.TAG_LEVEL] == "FATAL")
        
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
        
        let logs: String! =  try! Logger.getLogs(fileName: Logger.FILE_LOGGER_LOGS, overflowFileName: Logger.FILE_LOGGER_OVERFLOW, bufferFileName: Logger.FILE_LOGGER_SEND)
        
        XCTAssertTrue(NSFileManager().fileExistsAtPath(pathToBuffer))
        
        let fileContents = "[\(logs)]"
        
        let logDict : NSData = fileContents.dataUsingEncoding(NSUTF8StringEncoding)!
        let jsonDict: AnyObject? = try! NSJSONSerialization.JSONObjectWithData(logDict, options:NSJSONReadingOptions.MutableContainers)
        
        let debugMessage = jsonDict![0]
        XCTAssertTrue(debugMessage[Logger.TAG_MESSAGE] == "Hello world")
        XCTAssertTrue(debugMessage[Logger.TAG_PACKAGE] == fakePKG)
        XCTAssertTrue(debugMessage[Logger.TAG_TIMESTAMP] != nil)
        XCTAssertTrue(debugMessage[Logger.TAG_LEVEL] == "DEBUG")
        
        let infoMessage = jsonDict![1]
        XCTAssertTrue(infoMessage[Logger.TAG_MESSAGE] == "1242342342343243242342")
        XCTAssertTrue(infoMessage[Logger.TAG_PACKAGE] == fakePKG)
        XCTAssertTrue(infoMessage[Logger.TAG_TIMESTAMP] != nil)
        XCTAssertTrue(infoMessage[Logger.TAG_LEVEL] == "INFO")
        
        let warnMessage = jsonDict![2]
        XCTAssertTrue(warnMessage[Logger.TAG_MESSAGE] == "Str: heyoooooo")
        XCTAssertTrue(warnMessage[Logger.TAG_PACKAGE] == fakePKG)
        XCTAssertTrue(warnMessage[Logger.TAG_TIMESTAMP] != nil)
        XCTAssertTrue(warnMessage[Logger.TAG_LEVEL] == "WARN")
        
        let errorMessage = jsonDict![3]
        XCTAssertTrue(errorMessage[Logger.TAG_MESSAGE] == "1 2 3 4")
        XCTAssertTrue(errorMessage[Logger.TAG_PACKAGE] == fakePKG)
        XCTAssertTrue(errorMessage[Logger.TAG_TIMESTAMP] != nil)
        XCTAssertTrue(errorMessage[Logger.TAG_LEVEL] == "ERROR")
        
        let fatalMessage = jsonDict![4]
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
        
        let logs: String! =  try! Logger.getLogs(fileName: Logger.FILE_ANALYTICS_LOGS, overflowFileName: Logger.FILE_ANALYTICS_OVERFLOW, bufferFileName: Logger.FILE_ANALYTICS_SEND)
        
        let bufferFile = NSFileManager().fileExistsAtPath(pathToBuffer)
        
        XCTAssertTrue(bufferFile)
        
        let fileContents = "[\(logs)]"
        
        let logDict : NSData = fileContents.dataUsingEncoding(NSUTF8StringEncoding)!
        let jsonDict: AnyObject? = try! NSJSONSerialization.JSONObjectWithData(logDict, options:NSJSONReadingOptions.MutableContainers)
        
        let analyticsMessage = jsonDict![0]
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
        let largeData = try! String(contentsOfFile: path!)
        
        let loggerInstance = Logger.getLoggerForName(fakePKG)
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
        
        var formattedContents = try! String(contentsOfFile: pathToFile, encoding: NSUTF8StringEncoding)
        var fileContents = "[\(formattedContents)]"
        var logDict : NSData = fileContents.dataUsingEncoding(NSUTF8StringEncoding)!
        var jsonDict: AnyObject? = try! NSJSONSerialization.JSONObjectWithData(logDict, options:NSJSONReadingOptions.MutableContainers)
        
        let infoMessage = jsonDict![0]
        XCTAssertTrue(infoMessage[Logger.TAG_MESSAGE] == "1242342342343243242342")
        XCTAssertTrue(infoMessage[Logger.TAG_PACKAGE] == fakePKG)
        XCTAssertTrue(infoMessage[Logger.TAG_TIMESTAMP] != nil)
        XCTAssertTrue(infoMessage[Logger.TAG_LEVEL] == "INFO")
        
        let warnMessage = jsonDict![1]
        XCTAssertTrue(warnMessage[Logger.TAG_MESSAGE] == "Str: heyoooooo")
        XCTAssertTrue(warnMessage[Logger.TAG_PACKAGE] == fakePKG)
        XCTAssertTrue(warnMessage[Logger.TAG_TIMESTAMP] != nil)
        XCTAssertTrue(warnMessage[Logger.TAG_LEVEL] == "WARN")
        
        let errorMessage = jsonDict![2]
        XCTAssertTrue(errorMessage[Logger.TAG_MESSAGE] == "1 2 3 4")
        XCTAssertTrue(errorMessage[Logger.TAG_PACKAGE] == fakePKG)
        XCTAssertTrue(errorMessage[Logger.TAG_TIMESTAMP] != nil)
        XCTAssertTrue(errorMessage[Logger.TAG_LEVEL] == "ERROR")
        
        let fatalMessage = jsonDict![3]
        XCTAssertTrue(fatalMessage[Logger.TAG_MESSAGE] == "StephenColbert")
        XCTAssertTrue(fatalMessage[Logger.TAG_PACKAGE] == fakePKG)
        XCTAssertTrue(fatalMessage[Logger.TAG_TIMESTAMP] != nil)
        XCTAssertTrue(fatalMessage[Logger.TAG_LEVEL] == "FATAL")
        
        formattedContents = try! String(contentsOfFile: pathToOverflow, encoding: NSUTF8StringEncoding)
        fileContents = "[\(formattedContents)]"
        logDict  = fileContents.dataUsingEncoding(NSUTF8StringEncoding)!
        jsonDict = try! NSJSONSerialization.JSONObjectWithData(logDict, options:NSJSONReadingOptions.MutableContainers)
        
        
        let overflowMessage = jsonDict![0]
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
        let largeData = try! String(contentsOfFile: path!)
        
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
        
        var formattedContents = try! String(contentsOfFile: pathToOverflow, encoding: NSUTF8StringEncoding)
        var fileContents = "[\(formattedContents)]"
        var logDict : NSData = fileContents.dataUsingEncoding(NSUTF8StringEncoding)!
        var jsonDict: AnyObject? = try! NSJSONSerialization.JSONObjectWithData(logDict, options:NSJSONReadingOptions.MutableContainers)
        
        XCTAssertTrue(jsonDict!.count == 1)
        
        loggerInstance.debug(largeData)
        
     
        formattedContents = try! String(contentsOfFile: pathToOverflow, encoding: NSUTF8StringEncoding)
        fileContents = "[\(formattedContents)]"
        logDict  = fileContents.dataUsingEncoding(NSUTF8StringEncoding)!
        jsonDict = try! NSJSONSerialization.JSONObjectWithData(logDict, options:NSJSONReadingOptions.MutableContainers)
        
        
        XCTAssertTrue(jsonDict!.count == 1)

    }
    
    func testLogSendRequest(){
        let fakePKG = "MYPKG"
        let API_KEY = "apikey"
        let APP_NAME = "myApp"
        let pathToFile = Logger.logsDocumentPath + Logger.FILE_LOGGER_LOGS
        let pathToBuffer = Logger.logsDocumentPath + Logger.FILE_LOGGER_SEND
        let bmsClient = BMSClient.sharedInstance
        bmsClient.initializeWithBluemixAppRoute("bluemix", bluemixAppGUID: "appID1", bluemixRegionSuffix: BMSClient.REGION_US_SOUTH)
        Analytics.initializeWithAppName("testAppName", apiKey: "testApiKey")
        let url = "https://" + Logger.HOST_NAME + BMSClient.REGION_US_SOUTH + Logger.UPLOAD_PATH + bmsClient.bluemixAppGUID!
        
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
        
        let logs: String! =  try! Logger.getLogs(fileName: Logger.FILE_LOGGER_LOGS, overflowFileName: Logger.FILE_LOGGER_OVERFLOW, bufferFileName: Logger.FILE_LOGGER_SEND)
        
        let formattedLogs = "[\(logs)]"
        
        XCTAssertTrue(NSFileManager().fileExistsAtPath(pathToBuffer))
        
        let (request, payload) = Logger.buildLogSendRequest(logs) { (response, error) -> Void in
        }!
        
        XCTAssertTrue(request.resourceUrl == url)
        XCTAssertTrue(request.headers == headers)
        XCTAssertNil(request.queryParameters)
        XCTAssertTrue(request.httpMethod == HttpMethod.POST)
        
        XCTAssertTrue(payload == formattedLogs)
    }
    
    func testBuildLogSendRequestAPIKeyEmptyStringFail(){
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
        
        let logs: String! =  try! Logger.getLogs(fileName: Logger.FILE_LOGGER_LOGS, overflowFileName: Logger.FILE_LOGGER_OVERFLOW, bufferFileName: Logger.FILE_LOGGER_SEND)
        
        XCTAssertTrue(NSFileManager().fileExistsAtPath(pathToBuffer))
        
        let request = Logger.buildLogSendRequest(logs) { (response, error) -> Void in
        }
        
        XCTAssertNil(request)
        
        let formattedContents = try! String(contentsOfFile: pathToFile, encoding: NSUTF8StringEncoding)
        let fileContents = "[\(formattedContents)]"
        let logDict  = fileContents.dataUsingEncoding(NSUTF8StringEncoding)!
        let jsonDict = try! NSJSONSerialization.JSONObjectWithData(logDict, options:NSJSONReadingOptions.MutableContainers)
        
        
        let error = jsonDict[0]
        XCTAssertTrue(error[Logger.TAG_MESSAGE] != nil)
        XCTAssertTrue(error[Logger.TAG_PACKAGE] == fakePKG)
        XCTAssertTrue(error[Logger.TAG_TIMESTAMP] != nil)
        XCTAssertTrue(error[Logger.TAG_LEVEL] == "ERROR")
    }
    
    func testBuildLogSendRequestFail(){
        let fakePKG = Logger.MFP_LOGGER_PACKAGE
        let missingValue = "bluemixAppGUID"
        let bmsClient = BMSClient.sharedInstance
        bmsClient.initializeWithBluemixAppRoute("bluemix", bluemixAppGUID: "appID1", bluemixRegionSuffix: BMSClient.REGION_US_SOUTH)
        // TODO: Make these tests pass without the commented-out method
//        bmsClient.uninitalizeBluemixAppGUID()
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
        
        let logs: String! = try! Logger.getLogs(fileName: Logger.FILE_LOGGER_LOGS, overflowFileName: Logger.FILE_LOGGER_OVERFLOW, bufferFileName: Logger.FILE_LOGGER_SEND)
        XCTAssertTrue(NSFileManager().fileExistsAtPath(pathToBuffer))
        
        let request = Logger.buildLogSendRequest(logs) { (response, error) -> Void in
                XCTAssertNil(response)
                XCTAssertNotNil(error)
        }
        
        XCTAssertNil(request)
        
        let formattedContents = try! String(contentsOfFile: pathToFile, encoding: NSUTF8StringEncoding)
        let fileContents = "[\(formattedContents)]"
        let logDict  = fileContents.dataUsingEncoding(NSUTF8StringEncoding)!
        let jsonDict = try! NSJSONSerialization.JSONObjectWithData(logDict, options:NSJSONReadingOptions.MutableContainers)
        
        
        let error = jsonDict[0]
        XCTAssertTrue(error[Logger.TAG_MESSAGE] == msg)
        XCTAssertTrue(error[Logger.TAG_PACKAGE] == fakePKG)
        XCTAssertTrue(error[Logger.TAG_TIMESTAMP] != nil)
        XCTAssertTrue(error[Logger.TAG_LEVEL] == "ERROR")
        
    }
    
    func testBuildLogSendRequestGUIDFail(){
        let fakePKG = Logger.MFP_LOGGER_PACKAGE
        let missingValue = "bluemixAppGUID"
        let bmsClient = BMSClient.sharedInstance
        bmsClient.initializeWithBluemixAppRoute("bluemix", bluemixAppGUID: "appID1", bluemixRegionSuffix: BMSClient.REGION_US_SOUTH)
//        bmsClient.uninitalizeBluemixAppGUID()
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
        
        let logs: String! = try! Logger.getLogs(fileName: Logger.FILE_LOGGER_LOGS, overflowFileName: Logger.FILE_LOGGER_OVERFLOW, bufferFileName: Logger.FILE_LOGGER_SEND)
        XCTAssertTrue(NSFileManager().fileExistsAtPath(pathToBuffer))
        
        let request = Logger.buildLogSendRequest(logs) { (response, error) -> Void in
            XCTAssertNil(response)
            XCTAssertNotNil(error)
        }
        
        XCTAssertNil(request)
        
        let formattedContents = try! String(contentsOfFile: pathToFile, encoding: NSUTF8StringEncoding)
        let fileContents = "[\(formattedContents)]"
        let logDict  = fileContents.dataUsingEncoding(NSUTF8StringEncoding)!
        let jsonDict = try! NSJSONSerialization.JSONObjectWithData(logDict, options:NSJSONReadingOptions.MutableContainers)
        
        
        let error = jsonDict[0]
        XCTAssertTrue(error[Logger.TAG_MESSAGE] == msg)
        XCTAssertTrue(error[Logger.TAG_PACKAGE] == fakePKG)
        XCTAssertTrue(error[Logger.TAG_TIMESTAMP] != nil)
        XCTAssertTrue(error[Logger.TAG_LEVEL] == "ERROR")
        
    }
    
    func testReturnInitializationError(){
        // BMSClient initialization
        Logger.returnInitializationError("BMSClient", missingValue:"test") { (response, error) -> Void in
            XCTAssertNil(response)
            XCTAssertNotNil(error)
            XCTAssertEqual(error!.code, MFPErrorCode.ClientNotInitialized.rawValue)
            XCTAssertEqual(error!.domain, MFPRequest.MFP_CORE_ERROR_DOMAIN)
        }
        
        // Analytics initialization
        Logger.returnInitializationError("Analytics", missingValue:"test") { (response, error) -> Void in
            XCTAssertNil(response)
            XCTAssertNotNil(error)
            XCTAssertEqual(error!.code, AnalyticsErrorCode.AnalyticsNotInitialized.rawValue)
            XCTAssertEqual(error!.domain, MFPRequest.MFP_CORE_ERROR_DOMAIN)
        }
        
        // Unknown initialization
        Logger.returnInitializationError("Unknown class", missingValue:"test") { (response, error) -> Void in
            XCTAssertNil(response)
            XCTAssertNotNil(error)
            XCTAssertEqual(error!.code, -1)
            XCTAssertEqual(error!.domain, MFPRequest.MFP_CORE_ERROR_DOMAIN)
        }
    }
    
    func testDeleteBufferFileFail(){
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
    
        let logs: String! =  try! Logger.getLogs(fileName: Logger.FILE_LOGGER_LOGS, overflowFileName: Logger.FILE_LOGGER_OVERFLOW, bufferFileName: Logger.FILE_LOGGER_SEND)
        
        XCTAssertTrue(NSFileManager().fileExistsAtPath(pathToBuffer))
        
        XCTAssertNotNil(logs)
        
        do {
            try NSFileManager().removeItemAtPath(pathToBuffer)
        } catch {
            
        }
        
        Logger.deleteBufferFile(pathToBuffer)
        
        let formattedContents = try! String(contentsOfFile: pathToFile, encoding: NSUTF8StringEncoding)
        let fileContents = "[\(formattedContents)]"
        let logDict : NSData = fileContents.dataUsingEncoding(NSUTF8StringEncoding)!
        let jsonDict: AnyObject? = try! NSJSONSerialization.JSONObjectWithData(logDict, options:NSJSONReadingOptions.MutableContainers)
        
    
        let error = jsonDict![0]
        XCTAssertNotNil(error[Logger.TAG_MESSAGE])
        XCTAssertTrue(error[Logger.TAG_PACKAGE] == fakePKG)
        XCTAssertTrue(error[Logger.TAG_TIMESTAMP] != nil)
        XCTAssertTrue(error[Logger.TAG_LEVEL] == "ERROR")
        
    }
    
    func testDeleteBufferFile(){
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
        
        try! Logger.getLogs(fileName: Logger.FILE_LOGGER_LOGS, overflowFileName: Logger.FILE_LOGGER_OVERFLOW, bufferFileName: Logger.FILE_LOGGER_SEND)
        
        XCTAssertTrue(NSFileManager().fileExistsAtPath(pathToBuffer))
        
        Logger.deleteBufferFile(pathToBuffer)
        
        XCTAssertFalse(NSFileManager().fileExistsAtPath(pathToBuffer))
    }
    
    func testExtractFileNameFromPath() {
        
        let logFile1 = "some/path/to/file.txt"
        let logFile2 = "path//with///extra///slashes.log.txt"
        let logFile3 = "/////"
        let logFile4 = ""
        let logFile5 = "sdajfasldkfjalksfdj"
        
        
        XCTAssertEqual(Logger.extractFileNameFromPath(logFile1), "file.txt")
        XCTAssertEqual(Logger.extractFileNameFromPath(logFile2), "slashes.log.txt")
        XCTAssertEqual(Logger.extractFileNameFromPath(logFile3), "[Unknown]")
        XCTAssertEqual(Logger.extractFileNameFromPath(logFile4), "[Unknown]")
        XCTAssertEqual(Logger.extractFileNameFromPath(logFile5), "[Unknown]")
    }
    
}
