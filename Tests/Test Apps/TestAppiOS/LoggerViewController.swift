//
//  ViewController.swift
//  TestAppiOS
//
//  Created by Anthony Oliveri on 1/19/16.
//  Copyright © 2016 IBM. All rights reserved.
//

import UIKit
import BMSCore
import BMSAnalytics

class LoggerViewController: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource {
    
    
    var currentLogLevel = ""
    var currentLogLevelFilter = ""
    
    
    
    // MARK: UIViewController protocol
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        BMSClient.sharedInstance.initializeWithBluemixAppRoute(nil, bluemixAppGUID: nil, bluemixRegionSuffix: BluemixRegion.US_SOUTH)
        
        Analytics.initializeWithAppName("TestAppiOS", apiKey: "1234", deviceEvents: DeviceEvent.LIFECYCLE)
        Analytics.enabled = true
        
        self.logLevelPicker.dataSource = self
        self.logLevelPicker.delegate = self
        
        self.logLevelFilterPicker.dataSource = self
        self.logLevelFilterPicker.delegate = self
        
        // Should print true if the "Trigger Uncaught Exception" button was pressed in the last app session
        print("Uncaught Exception Detected: \(Logger.isUncaughtExceptionDetected)")
    }
    
    
    
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
        
        let logger = Logger.getLoggerForName(loggerNameField.text ?? "TestAppiOS")
        
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
        
        Logger.send { (response: Response?, error: NSError?) -> Void in
            if let response = response {
                print("\nSENDING LOGS")
                print("Logs send successfully: " + String(response.isSuccessful))
                print("Status code: " + String(response.statusCode))
                if let responseText = response.responseText {
                    print("Response text: " + responseText)
                }
                print("\n")
            }
        }
        
        Analytics.send { (response: Response?, error: NSError?) -> Void in
            if let response = response {
                print("\nSENDING ANALYTICS")
                print("Logs send successfully: " + String(response.isSuccessful))
                print("Status code: " + String(response.statusCode))
                if let responseText = response.responseText {
                    print("Response text: " + responseText)
                }
                print("\n")
            }
        }
    }
    
    @IBAction func showLogs(sender: UIButton) {
    }
    
    @IBAction func deleteLogs(sender: UIButton) {
    }
    
    @IBAction func triggerUncaughtException(sender: UIButton) {
    }
    
    
    
    // MARK: UIPickerViewDelegate protocol
    
    let logLevels = ["None", "Analytics", "Fatal", "Error", "Warn", "Info", "Debug"]
    
    
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
}
