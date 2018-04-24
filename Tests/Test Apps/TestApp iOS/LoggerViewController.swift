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


import UIKit
import BMSCore
import BMSAnalytics
import CoreLocation



#if swift(>=3.0)
    


class LoggerViewController: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource {
    
    
    var currentLogLevel = "Debug"
    var currentLogLevelFilter = "Debug"
    
    let locationManager = CLLocationManager()
    
    
    
    // MARK: Outlets
    
    @IBOutlet var logLevelPicker: UIPickerView!
    @IBOutlet var logLevelFilterPicker: UIPickerView!
    
    @IBOutlet var loggerNameField: UITextField!
    @IBOutlet var logMessageField: UITextField!
    @IBOutlet var maxStoreSizeField: UITextField!
    
    @IBOutlet var logStorageEnabledSwitch: UISwitch!
    @IBOutlet var internalSdkLoggingSwitch: UISwitch!
    
    
    
    // MARK: Button presses
    
    // Ignore the warning on the extraneous underscore in Swift 2. It is there for Swift 3.
    // This logs the message written in the `logMessageField` and separately logs the user's current location.
    @IBAction func recordLog(_ sender: UIButton) {
        
        Analytics.log(metadata: ["buttonPressed": "recordLog"])
        
        if let maxStoreSize = maxStoreSizeField.text {
            Logger.maxLogStoreSize = UInt64(maxStoreSize) ?? 100000
        }
        
        Logger.isLogStorageEnabled = logStorageEnabledSwitch.isOn
        Logger.isInternalDebugLoggingEnabled = internalSdkLoggingSwitch.isOn
        
        switch currentLogLevelFilter {
        case "None":
            Logger.logLevelFilter = LogLevel.none
        case "Analytics":
            Logger.logLevelFilter = LogLevel.analytics
        case "Fatal":
            Logger.logLevelFilter = LogLevel.fatal
        case "Error":
            Logger.logLevelFilter = LogLevel.error
        case "Warn":
            Logger.logLevelFilter = LogLevel.warn
        case "Info":
            Logger.logLevelFilter = LogLevel.info
        case "Debug":
            Logger.logLevelFilter = LogLevel.debug
        default:
            break
        }
        
        let logger = Logger.logger(name:loggerNameField.text ?? "TestAppiOS")
        
        switch currentLogLevel {
        case "None":
            print("Cannot log at the 'None' level")
        case "Analytics":
            print("Cannot log at the 'Analytics' level")
        case "Fatal":
            logger.fatal(message: logMessageField.text ?? "")
        case "Error":
            logger.error(message: logMessageField.text ?? "")
        case "Warn":
            logger.warn(message: logMessageField.text ?? "")
        case "Info":
            logger.info(message: logMessageField.text ?? "")
        case "Debug":
            logger.debug(message: logMessageField.text ?? "")
        default:
            break
        }
        
        Analytics.logLocation()
    }
    
    
    @IBAction func recordLocation(_ sender: UIButton) {
        
        Analytics.logLocation()
    }
    
    
    // Ignore the warning on the extraneous underscore in Swift 2. It is there for Swift 3.
    @IBAction func sendLogs(_ sender: UIButton) {
             
            func completionHandler(sentUsing sendType: String) -> BMSCompletionHandler {
                
                return {
                    (response: Response?, error: Error?) -> Void in
                    if let response = response {
                        print("\n\(sendType) sent successfully: " + String(response.isSuccessful))
                        print("Status code: " + String(describing: response.statusCode))
                        if let responseText = response.responseText {
                            print("Response text: " + responseText)
                        }
                        print("\n")
                    }
                }
            }
        
        Logger.send(completionHandler: completionHandler(sentUsing: "Logs"))
        Analytics.send(completionHandler: completionHandler(sentUsing: "Analytics"))
    }
    
    
    // Ignore the warning on the extraneous underscore in Swift 2. It is there for Swift 3.
    @IBAction func deleteLogs(_ sender: UIButton) {
        
        Analytics.log(metadata: ["buttonPressed": "deleteLogs"])
        
        let filePath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] + "/"
        let fileName = "bmssdk.logger.log"
        do {
            try FileManager().removeItem(atPath: filePath + fileName)
            print("Successfully deleted logs!")
        }
        catch {
            print("Failed to delete logs!")
        }
    }
    
    
    @IBAction func changeUserId(_ sender: UIButton) {
        
        Analytics.userIdentity = String(Date().timeIntervalSince1970)
    }
    
    
    // Ignore the warning on the extraneous underscore in Swift 2. It is there for Swift 3.
    @IBAction func triggerUncaughtException(_ sender: UIButton) {
        
        Analytics.log(metadata: ["buttonPressed": "triggerUncaughtException"])
        
        NSException(name: NSExceptionName("Test crash"), reason: "Ensure that BMSAnalytics framework is catching uncaught exceptions", userInfo: nil).raise()
    }
    
    // Ignore the warning on the extraneous underscore in Swift 2. It is there for Swift 3.
    @IBAction func triggerFeedbackMode(_ sender: UIButton) {
        Analytics.triggerFeedbackMode()
    }
    
    // MARK: UIPickerViewDelegate protocol
    
    let logLevels = ["Debug", "Info", "Warn", "Error", "Fatal", "Analytics", "None"]
    
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
    
        return 1
    }
    
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        
        return logLevels.count
    }
    
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        
        return logLevels[row]
    }
    
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        
        switch pickerView.tag {
        case 0:
            currentLogLevel = logLevels[row]
        case 1:
            currentLogLevelFilter = logLevels[row]
        default:
            break
        }
    }
  
    
    
    // MARK: UIViewController protocol
    
    override func viewDidLoad() {
    
        super.viewDidLoad()
        
        self.logLevelPicker.dataSource = self
        self.logLevelPicker.delegate = self
        
        self.logLevelFilterPicker.dataSource = self
        self.logLevelFilterPicker.delegate = self
        
        // Should print true if the "Trigger Uncaught Exception" button was pressed in the last app session
        print("Uncaught Exception Detected: \(Logger.isUncaughtExceptionDetected)")
        
        // Get user permission to use location services
        if CLLocationManager.locationServicesEnabled() && CLLocationManager.authorizationStatus() == CLAuthorizationStatus.notDetermined {
            self.locationManager.requestWhenInUseAuthorization()
        }
    }
}
    
    
    
    
    
/**************************************************************************************************/
    
    
    
    
    
// MARK: - Swift 2
    
#else
    
    

class LoggerViewController: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource {
    
    
    var currentLogLevel = "Debug"
    var currentLogLevelFilter = "Debug"
    
    let locationManager = CLLocationManager()
    
    
    
    // MARK: Outlets
    
    @IBOutlet var logLevelPicker: UIPickerView!
    @IBOutlet var logLevelFilterPicker: UIPickerView!
    
    @IBOutlet var loggerNameField: UITextField!
    @IBOutlet var logMessageField: UITextField!
    @IBOutlet var maxStoreSizeField: UITextField!
    
    @IBOutlet var logStorageEnabledSwitch: UISwitch!
    @IBOutlet var internalSdkLoggingSwitch: UISwitch!
    
    
    
    // MARK: Button presses
    
    // This logs the message written in the `logMessageField` and separately logs the user's current location.
    @IBAction func recordLog(sender: UIButton) {
        
        Analytics.log(metadata: ["buttonPressed": "recordLog"])
        
        if let maxStoreSize = maxStoreSizeField.text {
            Logger.maxLogStoreSize = UInt64(maxStoreSize) ?? 100000
        }
        
        Logger.isLogStorageEnabled = logStorageEnabledSwitch.on
        Logger.isInternalDebugLoggingEnabled = internalSdkLoggingSwitch.on
    
        switch currentLogLevelFilter {
        case "None":
            Logger.logLevelFilter = LogLevel.none
        case "Analytics":
            Logger.logLevelFilter = LogLevel.analytics
        case "Fatal":
            Logger.logLevelFilter = LogLevel.fatal
        case "Error":
            Logger.logLevelFilter = LogLevel.error
        case "Warn":
            Logger.logLevelFilter = LogLevel.warn
        case "Info":
            Logger.logLevelFilter = LogLevel.info
        case "Debug":
            Logger.logLevelFilter = LogLevel.debug
        default:
            break
        }
        
        let logger = Logger.logger(name:loggerNameField.text ?? "TestAppiOS")
        
        switch currentLogLevel {
        case "None":
            print("Cannot log at the 'None' level")
        case "Analytics":
            print("Cannot log at the 'Analytics' level")
        case "Fatal":
            logger.fatal(message: logMessageField.text ?? "")
        case "Error":
            logger.error(message: logMessageField.text ?? "")
        case "Warn":
            logger.warn(message: logMessageField.text ?? "")
        case "Info":
            logger.info(message: logMessageField.text ?? "")
        case "Debug":
            logger.debug(message: logMessageField.text ?? "")
        default:
            break
        }
        
        Analytics.logLocation()
    }
    
    
    @IBAction func recordLocation(sender: UIButton) {
        
        Analytics.logLocation()
    }
    
    
    @IBAction func sendLogs(sender: UIButton) {
        
        func completionHandler(sentUsing sendType: String) -> BMSCompletionHandler {
            
            return {
                (response: Response?, error: NSError?) -> Void in
                if let response = response {
                    print("\n\(sendType) sent successfully: " + String(response.isSuccessful))
                    print("Status code: " + String(response.statusCode))
                    if let responseText = response.responseText {
                        print("Response text: " + responseText)
                    }
                    print("\n")
                }
            }
            
        }
        
        Logger.send(completionHandler: completionHandler(sentUsing: "Logs"))
        Analytics.send(completionHandler: completionHandler(sentUsing: "Analytics"))
    }
    
    
    @IBAction func deleteLogs(sender: UIButton) {
        
        Analytics.log(metadata: ["buttonPressed": "deleteLogs"])
        
        let filePath = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0] + "/"
        let fileName = "bmssdk.logger.log"
        do {
            try NSFileManager().removeItemAtPath(filePath + fileName)
            print("Successfully deleted logs!")
        } catch {
            print("Failed to delete logs!")
        }
    }
    
    
    @IBAction func changeUserId(sender: UIButton) {
        
        Analytics.userIdentity = String(NSDate().timeIntervalSince1970)
    }
    
    
    @IBAction func triggerUncaughtException(sender: UIButton) {
        
        Analytics.log(metadata: ["buttonPressed": "triggerUncaughtException"])
        
        NSException(name: "Test crash", reason: "Ensure that BMSAnalytics framework is catching uncaught exceptions", userInfo: nil).raise()
    }
    
    
    
    // MARK: UIPickerViewDelegate protocol
    
    let logLevels = ["Debug", "Info", "Warn", "Error", "Fatal", "Analytics", "None"]
    
    
    func numberOfComponentsInPickerView(pickerView: UIPickerView) -> Int {
        
        return 1
    }
    
    
    func pickerView(pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        
        return logLevels.count
    }
    
    
    func pickerView(pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        
        return logLevels[row]
    }
    
    
    func pickerView(pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        
        switch pickerView.tag {
        case 0:
            currentLogLevel = logLevels[row]
        case 1:
            currentLogLevelFilter = logLevels[row]
        default:
            break
        }
    }
    
    
    
    // MARK: UIViewController protocol
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        self.logLevelPicker.dataSource = self
        self.logLevelPicker.delegate = self
        
        self.logLevelFilterPicker.dataSource = self
        self.logLevelFilterPicker.delegate = self
        
        // Should print true if the "Trigger Uncaught Exception" button was pressed in the last app session
        print("Uncaught Exception Detected: \(Logger.isUncaughtExceptionDetected)")
        
        // Get user permission to use location services
        if CLLocationManager.locationServicesEnabled() && CLLocationManager.authorizationStatus() == CLAuthorizationStatus.NotDetermined {
            self.locationManager.requestWhenInUseAuthorization()
        }
    }
}



#endif
