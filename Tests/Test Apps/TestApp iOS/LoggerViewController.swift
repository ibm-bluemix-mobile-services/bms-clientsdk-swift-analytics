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


class LoggerViewController: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource {
    
    
    var currentLogLevel = "Debug"
    var currentLogLevelFilter = "Debug"
    
    
    
    // MARK: Outlets
    
    @IBOutlet var logLevelPicker: UIPickerView!
    @IBOutlet var logLevelFilterPicker: UIPickerView!
    
    @IBOutlet var loggerNameField: UITextField!
    @IBOutlet var logMessageField: UITextField!
    @IBOutlet var maxStoreSizeField: UITextField!
    
    @IBOutlet var logStorageEnabledSwitch: UISwitch!
    @IBOutlet var internalSdkLoggingSwitch: UISwitch!
    
    
    
    // MARK: Button presses
    
    @IBAction func recordLog(sender: UIButton) {
        
        Analytics.log(["buttonPressed": "recordLog"])
        
        if let maxStoreSize = maxStoreSizeField.text {
            Logger.maxLogStoreSize = UInt64(maxStoreSize) ?? 100000
        }
        
        Logger.logStoreEnabled = logStorageEnabledSwitch.on
        Logger.sdkDebugLoggingEnabled = internalSdkLoggingSwitch.on
        
        switch currentLogLevelFilter {
        case "None":
            Logger.logLevelFilter = LogLevel.None
        case "Analytics":
            Logger.logLevelFilter = LogLevel.Analytics
        case "Fatal":
            Logger.logLevelFilter = LogLevel.Fatal
        case "Error":
            Logger.logLevelFilter = LogLevel.Error
        case "Warn":
            Logger.logLevelFilter = LogLevel.Warn
        case "Info":
            Logger.logLevelFilter = LogLevel.Info
        case "Debug":
            Logger.logLevelFilter = LogLevel.Debug
        default:
            break
        }
        
        let logger = Logger.logger(forName:loggerNameField.text ?? "TestAppiOS")
        
        switch currentLogLevel {
        case "None":
            print("Cannot log at the 'None' level")
        case "Analytics":
            print("Cannot log at the 'Analytics' level")
        case "Fatal":
            logger.fatal(logMessageField.text ?? "")
        case "Error":
            logger.error(logMessageField.text ?? "")
        case "Warn":
            logger.warn(logMessageField.text ?? "")
        case "Info":
            logger.info(logMessageField.text ?? "")
        case "Debug":
            logger.debug(logMessageField.text ?? "")
        default:
            break
        }
    }
    
    @IBAction func sendLogs(sender: UIButton) {
        
        func completionHandler(sendType: String) -> BmsCompletionHandler {
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
        
        Logger.send(completionHandler: completionHandler("Logs"))
        
        Analytics.send(completionHandler: completionHandler("Analytics"))
    }
    
    @IBAction func deleteLogs(sender: UIButton) {
        
        Analytics.log(["buttonPressed": "deleteLogs"])
        
        let filePath = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0] + "/"
        let fileName = "bmssdk.logger.log"
        do {
            try NSFileManager().removeItemAtPath(filePath + fileName)
            print("Successfully deleted logs!")
        } catch {
            print("Failed to delete logs!")
        }
    }
    
    @IBAction func triggerUncaughtException(sender: UIButton) {
        
        Analytics.log(["buttonPressed": "triggerUncaughtException"])
        
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
    }
}
