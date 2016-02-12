//
//  LogDisplayViewController.swift
//  BMSAnalytics
//
//  Created by Anthony Oliveri on 2/10/16.
//  Copyright © 2016 IBM. All rights reserved.
//

import UIKit
import BMSCore
import BMSAnalytics

class LogDisplayViewController: UIViewController {
    
    
    // MARK: Outlets
    
    @IBOutlet var logsTextView: UITextView!
    
    
    
    // MARK: Button presses
    
    @IBAction func dismissViewController(sender: UIButton) {
        
        self.dismissViewControllerAnimated(true) { () -> Void in }
    }
    
    func populateLogTextView() {
        
        // Populate text view with all stored logs
        let filePath = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0] + "/"
        let fileName = "mfpsdk.logger.log"
        let pathToFile = filePath + fileName
        
        do {
            logsTextView.text = try String(contentsOfFile: pathToFile, encoding: NSUTF8StringEncoding)
        } catch {
            logsTextView.text = "No logs!"
        }
    }
    
    
    
    // MARK: UIViewController protocol
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        logsTextView.layer.borderWidth = 1
        
        populateLogTextView()
    }

    
    
}