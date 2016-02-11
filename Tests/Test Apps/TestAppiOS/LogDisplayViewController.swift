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