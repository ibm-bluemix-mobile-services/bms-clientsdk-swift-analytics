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
    }
    
    @IBAction func sendLogs(sender: UIButton) {
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
    
    
    // MARK: UIViewController protocol
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.logLevelPicker.dataSource = self
        self.logLevelPicker.delegate = self
        
        self.logLevelFilterPicker.dataSource = self
        self.logLevelFilterPicker.delegate = self
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

