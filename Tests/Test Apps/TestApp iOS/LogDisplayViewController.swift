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


class LogDisplayViewController: UIViewController {
    
    
    // MARK: Outlets
    
    @IBOutlet var logsTextView: UITextView!
    
    
    
    // MARK: Button presses
    
    // Ignore the warning on the extraneous underscore in Swift 2. It is there for Swift 3.
    @IBAction func dismissViewController(_ sender: UIButton) {
        
        #if swift(>=3.0)
            self.dismiss(animated: true) { () -> Void in }
        #else
            self.dismissViewControllerAnimated(true) { () -> Void in }
        #endif
    }
    
    func populateLogTextView() {
        
        // Populate text view with all stored logs
        #if swift(>=3.0)
            let filePath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] + "/"
        #else
            let filePath = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0] + "/"
        #endif
        
        let fileName = "bmssdk.logger.log"
        let pathToFile = filePath + fileName
        
        do {
            #if swift(>=3.0)
                logsTextView.text = try String(contentsOfFile: pathToFile, encoding: .utf8)
            #else
                logsTextView.text = try String(contentsOfFile: pathToFile, encoding: NSUTF8StringEncoding)
            #endif
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
