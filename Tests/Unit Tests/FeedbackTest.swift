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

class FeedbackTest: XCTestCase {

    override func tearDown() {
        super.tearDown()
        BMSAnalytics.lifecycleEvents = [:]
        BMSAnalytics.startTime = 0
        BMSAnalytics.uninitialize()

        Request.requestAnalyticsData = nil
    }

    func testCurrentlySendingFeedbackdataInitial() {

        let bmsClient = BMSClient.sharedInstance
        bmsClient.initialize(bluemixAppRoute: "bluemix", bluemixAppGUID: "appID1", bluemixRegion: BMSClient.Region.usSouth)
        Analytics.initialize(appName: "testAppName", apiKey: "1234")

        XCTAssertFalse(Logger.currentlySendingFeedbackdata)
    }

    func testCurrentlySendingFeedbackdataAfterSend() {

        let bmsClient = BMSClient.sharedInstance
        bmsClient.initialize(bluemixAppRoute: "bluemix", bluemixAppGUID: "appID1", bluemixRegion: BMSClient.Region.usSouth)
        Analytics.initialize(appName: "testAppName", apiKey: "1234")

        XCTAssertFalse(Logger.currentlySendingFeedbackdata)

        Feedback.send(fromSentButton: false)
        XCTAssertFalse(Logger.currentlySendingFeedbackdata)
    }

    func testFeedbackSendWithoutBMSInitialisation() {
        let newFeedbackExpectation = expectation(description: "Failed to send feedback data because the client was not yet initialized. Make sure that the BMSClient class has been initialized.")

        let timeDelay = DispatchTime.now() + 1
        DispatchQueue.main.asyncAfter(deadline: timeDelay) {
            newFeedbackExpectation.fulfill()
        }
        Feedback.send(fromSentButton: false)
        waitForExpectations(timeout: 10.0) { (error: Error?) -> Void in
            if error != nil {
                XCTFail("Expectation failed with error: \(error)")
            }
        }
    }

    func testFeedbackSendAfterBMSInitialisation() {
        let bmsClient = BMSClient.sharedInstance
        bmsClient.initialize(bluemixAppRoute: "bluemix", bluemixAppGUID: "appID1", bluemixRegion: BMSClient.Region.usSouth)
        Analytics.initialize(appName: "testAppName", apiKey: "1234")

        let newFeedbackExpectation = expectation(description: "")
        let timeDelay = DispatchTime.now() + 1
        DispatchQueue.main.asyncAfter(deadline: timeDelay) {
            newFeedbackExpectation.fulfill()
        }

        Feedback.send(fromSentButton: false)
        waitForExpectations(timeout: 10.0) { (error: Error?) -> Void in
            if error != nil {
                XCTFail("Expectation failed with error: \(error)")
            }
        }
    }

    func testWrite() {
        do {
            let fileWithPath = BMSLogger.feedbackDocumentPath+"/testfeedback.json"
            createDirectory(atPath: BMSLogger.feedbackDocumentPath)
            let jsonString = String("{\"key\":\"value\"}")!
            Feedback.write(toFile: fileWithPath, feedbackdata: jsonString, append: false)
            let fileContent = Feedback.convertFileToString(filepath: fileWithPath)
            print(fileContent)
            XCTAssertTrue(BMSLogger.fileManager.fileExists(atPath: fileWithPath))
            XCTAssertEqual(jsonString, fileContent)

            // Test with allow append
            let jsonString1 = String("{\"key1\":\"value1\"}")!
            Feedback.write(toFile: fileWithPath, feedbackdata: jsonString1, append: true)
            let fileContent1 = Feedback.convertFileToString(filepath: fileWithPath)
            print(fileContent1)
            XCTAssertTrue(BMSLogger.fileManager.fileExists(atPath: fileWithPath))
            XCTAssertEqual(jsonString+jsonString1, fileContent1)

            let dataContent = Feedback.convertFileToData(filepath: fileWithPath)
            XCTAssertNotNil(dataContent)

            if BMSLogger.fileManager.fileExists(atPath: fileWithPath) {
                try BMSLogger.fileManager.removeItem(atPath: fileWithPath)
            }
            XCTAssertFalse(BMSLogger.fileManager.fileExists(atPath: fileWithPath))
        }catch{
            XCTFail()
        }
    }

    func testConvertToJSON() {
        let jsonObject: [String: Any] = [
            "id": "id",
            "comments": ["Comment1", "Comment2"],
            "screenName": "screenName",
            "screenWidth": 10,
            "screenHeight": 20,
            "sessionID": "asdf-1234-qwe12",
            "username": "Jammy"
        ]

        let feedbackJsonString = Feedback.convertToJSON(jsonObject)
        XCTAssertNotNil(feedbackJsonString)
        let expectedString = "{\"id\":\"id\",\"screenWidth\":10,\"screenHeight\":20,\"comments\":[\"Comment1\",\"Comment2\"],\"screenName\":\"screenName\",\"username\":\"Jammy\",\"sessionID\":\"asdf-1234-qwe12\"}"
        XCTAssertEqual(expectedString, feedbackJsonString)
    }

    func testCreateZip() {
        let instanceName="TestInstance"
        let directory = BMSLogger.feedbackDocumentPath+instanceName
        createDirectory(atPath: directory)
        let expectedZipPath = BMSLogger.feedbackDocumentPath + "/../"+instanceName + ".zip"

        let jsonString1 = String("Some image data")!  // dummy data
        Feedback.write(toFile: directory+"/image.png", feedbackdata: jsonString1, append: false)
        XCTAssertTrue(BMSLogger.fileManager.fileExists(atPath: directory+"/image.png"))
        Feedback.write(toFile: directory+"/feedback.json", feedbackdata: jsonString1, append: false)
        XCTAssertTrue(BMSLogger.fileManager.fileExists(atPath: directory+"/feedback.json"))
        Feedback.createZip(instanceName: instanceName)
        XCTAssertTrue(BMSLogger.fileManager.fileExists(atPath: expectedZipPath))

        do{
            try BMSLogger.fileManager.removeItem(atPath: directory+"/image.png")
            try BMSLogger.fileManager.removeItem(atPath: directory+"/feedback.json")
            try BMSLogger.fileManager.removeItem(atPath: expectedZipPath)
            try BMSLogger.fileManager.removeItem(atPath: BMSLogger.feedbackDocumentPath+instanceName)
        } catch {
            XCTFail()
        }
    }

    func testGetInstanceName() {
        let creation = String(Int((Date().timeIntervalSince1970 * 1000.0).rounded()))
        Feedback.instanceName = "TestInstance"
        Feedback.creationDate = creation
        XCTAssertEqual("TestInstance_"+creation, Feedback.getInstanceName())
    }

    func testAddAndReturnTimeSent() {
        let instanceName = "TestInstance"
        let directory = BMSLogger.feedbackDocumentPath+instanceName
        createDirectory(atPath: directory)

        let sampleFeedbackJsonObject: [String: Any] = [
            "id": "id",
            "comments": ["Comment1", "Comment2"],
            "screenName": "screenName",
            "screenWidth": 10,
            "screenHeight": 20,
            "sessionID": "asdf-1234-qwe12",
            "username": "Jammy"
        ]
        let feedbackJsonString = Feedback.convertToJSON(sampleFeedbackJsonObject)
        Feedback.write(toFile: directory+"/feedback.json", feedbackdata: feedbackJsonString!, append: false)
        XCTAssertTrue(BMSLogger.fileManager.fileExists(atPath: directory+"/feedback.json"))

        let timeSent1 = String(Int((Date().timeIntervalSince1970 * 1000.0).rounded()))
        let returnValue = Feedback.addAndReturnTimeSent(instanceName: instanceName, timeSent: timeSent1)
        XCTAssertEqual(timeSent1, returnValue)

        let timeSent2 = String(Int((Date().timeIntervalSince1970 * 1000.0).rounded()))
        let returnValue2 = Feedback.addAndReturnTimeSent(instanceName: instanceName, timeSent: timeSent2)
        XCTAssertEqual(timeSent1, returnValue2)

        do{
            try BMSLogger.fileManager.removeItem(atPath: directory+"/feedback.json")
            try BMSLogger.fileManager.removeItem(atPath: BMSLogger.feedbackDocumentPath+instanceName)
        } catch {
            XCTFail()
        }
    }

    func testUpdateSummaryJsonFile() {
        let directory = BMSLogger.feedbackDocumentPath
        createDirectory(atPath: directory)

        Feedback.updateSummaryJsonFile("TestInstance1", timesent: "", remove: false)
        let summary = getSummary()
        XCTAssertEqual(1, summary.saved.count)
        XCTAssertEqual(0, summary.send.count)
        XCTAssertEqual("TestInstance1", summary.saved[0])
        XCTAssertEqual("{\"saved\":[\"TestInstance1\"], \"send\":{}}", summary.jsonRepresentation())

        Feedback.updateSummaryJsonFile("TestInstance2", timesent: "", remove: false)
        let summary1 = getSummary()
        XCTAssertEqual(2, summary1.saved.count)
        XCTAssertEqual(0, summary1.send.count)
        XCTAssertEqual("TestInstance1", summary1.saved[0])
        XCTAssertEqual("TestInstance2", summary1.saved[1])
        XCTAssertEqual("{\"saved\":[\"TestInstance1\",\"TestInstance2\"], \"send\":{}}", summary1.jsonRepresentation())

        let timeSent = String(Int((Date().timeIntervalSince1970 * 1000.0).rounded()))
        Feedback.updateSummaryJsonFile("TestInstance1", timesent: timeSent, remove: true)
        let summary3 = getSummary()
        XCTAssertEqual(1, summary3.saved.count)
        XCTAssertEqual(1, summary3.send.count)
        XCTAssertEqual("TestInstance2", summary3.saved[0])
        XCTAssertEqual(1, summary3.send[0].sendArray.count)
        XCTAssertEqual("TestInstance1", summary3.send[0].sendArray[0])
        XCTAssertEqual(timeSent, summary3.send[0].timeSent)
        XCTAssertEqual("{\"saved\":[\"TestInstance2\"], \"send\":{\""+timeSent+"\":[\"TestInstance1\"]}}", summary3.jsonRepresentation())

        let timeSent1 = String(Int((Date().timeIntervalSince1970 * 1000.0).rounded()))
        Feedback.updateSummaryJsonFile("TestInstance2", timesent: timeSent1, remove: true)
        let summary4 = getSummary()
        XCTAssertEqual(0, summary4.saved.count)
        XCTAssertEqual(2, summary4.send.count)
        XCTAssertEqual(1, summary4.send[0].sendArray.count)
        XCTAssertEqual(1, summary4.send[1].sendArray.count)
        XCTAssertTrue(summary4.send[0].sendArray.contains("TestInstance1") || summary4.send[0].sendArray.contains("TestInstance2"))
        XCTAssertTrue(summary4.send[1].sendArray.contains("TestInstance1") || summary4.send[1].sendArray.contains("TestInstance2"))
        XCTAssertTrue(summary4.send[0].timeSent == timeSent || summary4.send[0].timeSent == timeSent1)
        XCTAssertTrue(summary4.send[1].timeSent == timeSent || summary4.send[1].timeSent == timeSent1)
        let summaryStr = summary4.jsonRepresentation()
        let expected1 = "{\"saved\":[], \"send\":{\""+timeSent+"\":[\"TestInstance1\"],\""+timeSent1+"\":[\"TestInstance2\"]}}"
        let expected2 = "{\"saved\":[], \"send\":{\""+timeSent1+"\":[\"TestInstance2\"],\""+timeSent+"\":[\"TestInstance1\"]}}"
        XCTAssertTrue((expected1 == summaryStr) || (expected2 == summaryStr))

        do{
            try BMSLogger.fileManager.removeItem(atPath: BMSLogger.feedbackDocumentPath+"AppFeedBackSummary.json")
            try BMSLogger.fileManager.removeItem(atPath: BMSLogger.feedbackDocumentPath)
        } catch {
            XCTFail()
        }
    }

    func testBuildLogSendRequestForFeedbackForBluemix() {

        let bmsClient = BMSClient.sharedInstance
        bmsClient.initialize(bluemixAppRoute: "bluemix", bluemixAppGUID: "appID1", bluemixRegion: BMSClient.Region.usSouth)
        Analytics.initialize(appName: "testAppName", apiKey: "1234")

        let bmsRequest = try! BMSLogger.buildLogSendRequestForFeedback() { (response, error) -> Void in }

        XCTAssertNotNil(bmsRequest)
        XCTAssertTrue(bmsRequest is Request)

        let bmsLogUploadUrl = "https://" + Constants.AnalyticsServer.hostName + ".ng.bluemix.net" + Constants.AnalyticsServer.uploadFeedbackPath
        XCTAssertEqual(bmsRequest!.resourceUrl, bmsLogUploadUrl)
    }

    func testBuildLogSendRequestForFeedbackForLocalhost() {

        let bmsClient = BMSClient.sharedInstance
        bmsClient.initialize(bluemixAppRoute: "bluemix", bluemixAppGUID: "appID1", bluemixRegion: "localhost:8000")
        Analytics.initialize(appName: "testAppName", apiKey: "1234")

        let bmsRequest = try! BMSLogger.buildLogSendRequestForFeedback() { (response, error) -> Void in }

        XCTAssertNotNil(bmsRequest)
        XCTAssertTrue(bmsRequest is Request)

        let bmsFeedbackUploadUrl = "http://" + "localhost:8000" + Constants.AnalyticsServer.uploadFeedbackPath
        XCTAssertEqual(bmsRequest!.resourceUrl, bmsFeedbackUploadUrl)
    }

    func testFeedbackSendRequest() {
        let pathToFile = BMSLogger.feedbackDocumentPath
        let bmsClient = BMSClient.sharedInstance
        bmsClient.initialize(bluemixAppRoute: "bluemix", bluemixAppGUID: "appID1", bluemixRegion: BMSClient.Region.usSouth)
        Analytics.initialize(appName: "testAppName", apiKey: "1234")
        let url = "https://" + Constants.AnalyticsServer.hostName + BMSClient.Region.usSouth + Constants.AnalyticsServer.uploadFeedbackPath

        var headers = ["Content-Type": "multipart/form-data", Constants.analyticsApiKey: "1234"]

        do {
            try FileManager().removeItem(atPath: pathToFile)
        } catch {}

        let request = try! BMSLogger.buildLogSendRequestForFeedback() { (response, error) -> Void in }!

        XCTAssertTrue(request.resourceUrl == url)
        XCTAssertTrue(request.headers == headers)
        XCTAssertTrue(request.httpMethod == HttpMethod.POST)
    }

    func testFeedbackSend() {
        let pathToFile = BMSLogger.feedbackDocumentPath
        let bmsClient = BMSClient.sharedInstance
        bmsClient.initialize(bluemixAppRoute: "bluemix", bluemixAppGUID: "appID1", bluemixRegion: BMSClient.Region.usSouth)
        Analytics.initialize(appName: "testAppName", apiKey: "1234")

        do {
            try FileManager().removeItem(atPath: pathToFile)
        } catch {}

        let instanceName="TestInstance"
        let directory = BMSLogger.feedbackDocumentPath+instanceName
        createDirectory(atPath: directory)
        let expectedZipPath = BMSLogger.feedbackDocumentPath + "/../"+instanceName + ".zip"

        func completionHandler() -> BMSCompletionHandler {
            return {
                (response: Response?, error: Error?) -> Void in
                do{
                    try BMSLogger.fileManager.removeItem(atPath: directory+"/image.png")
                    try BMSLogger.fileManager.removeItem(atPath: directory+"/feedback.json")
                    try BMSLogger.fileManager.removeItem(atPath: expectedZipPath)
                    try BMSLogger.fileManager.removeItem(atPath: BMSLogger.feedbackDocumentPath+instanceName)
                }catch{XCTFail()}
            }
        }

        let jsonString1 = String("Some image data")!  // dummy data
        Feedback.write(toFile: directory+"/image.png", feedbackdata: jsonString1, append: false)
        XCTAssertTrue(BMSLogger.fileManager.fileExists(atPath: directory+"/image.png"))
        Feedback.write(toFile: directory+"/feedback.json", feedbackdata: jsonString1, append: false)
        XCTAssertTrue(BMSLogger.fileManager.fileExists(atPath: directory+"/feedback.json"))
        Feedback.createZip(instanceName: instanceName)
        XCTAssertTrue(BMSLogger.fileManager.fileExists(atPath: expectedZipPath))

        let feedbackSendFinished = expectation(description: "Feedback send complete")
        Feedback.sendFeedbackFile(uploadFileName: expectedZipPath) { (response, error) -> Void in
            XCTAssertFalse(Logger.currentlySendingFeedbackdata)
            feedbackSendFinished.fulfill()
        }

        waitForExpectations(timeout: 10.0) { (error1: Error?) -> Void in
            if error1 != nil {
                XCTFail("Expectation failed with error: \(error1)")
            }
        }
    }

    func testFeedbackSendWithNoLog() {
        let pathToFile = BMSLogger.feedbackDocumentPath
        let bmsClient = BMSClient.sharedInstance
        bmsClient.initialize(bluemixAppRoute: "bluemix", bluemixAppGUID: "appID1", bluemixRegion: BMSClient.Region.usSouth)
        Analytics.initialize(appName: "testAppName", apiKey: "1234")

        do {
            try FileManager().removeItem(atPath: pathToFile)
        } catch { }

        let instanceName="TestInstance"
        let directory = BMSLogger.feedbackDocumentPath+instanceName
        createDirectory(atPath: directory)
        let expectedZipPath = BMSLogger.feedbackDocumentPath + "/../"+instanceName + ".zip"

        func completionHandler() -> BMSCompletionHandler {
            return {
                (response: Response?, error: Error?) -> Void in
                do{
                    try BMSLogger.fileManager.removeItem(atPath: expectedZipPath)
                    try BMSLogger.fileManager.removeItem(atPath: BMSLogger.feedbackDocumentPath+instanceName)
                }catch{XCTFail()}
            }
        }

        let feedbackSendFinished = expectation(description: "Feedback send complete")
        Feedback.sendFeedbackFile(uploadFileName: expectedZipPath) { (response, error) -> Void in
            XCTAssertFalse(Logger.currentlySendingFeedbackdata)
            feedbackSendFinished.fulfill()
        }

        waitForExpectations(timeout: 10.0) { (error1: Error?) -> Void in
            if error1 != nil {
                XCTFail("Expectation failed with error: \(error1)")
            }
        }
    }

    func getSummary() -> Feedback.AppFeedBackSummary {
        do {
            let afbsFile = BMSLogger.feedbackDocumentPath+"AppFeedBackSummary.json"
            let afbs = Feedback.convertFileToData(filepath: afbsFile)
            let json = try JSONSerialization.jsonObject(with: afbs!, options: JSONSerialization.ReadingOptions.mutableContainers)
            return Feedback.AppFeedBackSummary(json: json as! [String: Any])
        }catch{}
        return Feedback.AppFeedBackSummary(json: [:])
    }

    func createDirectory(atPath: String) {
        var objcBool: ObjCBool = true
        let isExist = FileManager.default.fileExists(atPath: atPath, isDirectory: &objcBool)

        // If the folder with the given path doesn't exist already, create it
        if isExist == false {
            do{
                try FileManager.default.createDirectory(atPath: atPath, withIntermediateDirectories: true, attributes: nil)
            }catch{
                BMSLogger.internalLogger.error(message: "Something went wrong while creating a new folder")
            }
        }
    }

}

#endif
