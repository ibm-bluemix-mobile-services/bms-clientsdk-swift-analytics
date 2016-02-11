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

class LoggerViewController: UIViewController {
    
    
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
    
    
    
    // MARK: UIViewController protocol
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

