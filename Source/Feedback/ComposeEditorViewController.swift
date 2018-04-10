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



// MARK: - Swift 3

#if swift(>=3.0)

import UIKit

class ComposeEditorViewController: UIViewController {

    var messages: [String] = [String]()

    override func viewDidLoad() {
        super.viewDidLoad()
        //  messageBox.delegate = self as! UITextViewDelegate

        // Do any additional setup after loading the view.
        messageBox.placeholder = "Please enter your comments here"
        messageBox.textColor = UIColor.lightGray

        self.messageBox.textContainer.maximumNumberOfLines = 5
        self.messageBox.textContainer.lineBreakMode = .byTruncatingTail

        messageBox.inputView = UIView()

        messageBox.translatesAutoresizingMaskIntoConstraints = false
        messageBox.isScrollEnabled = false

        func textViewDidChange(_ textView: UITextView) {
            let fixedWidth = messageBox.frame.size.width
            messageBox.sizeThatFits(CGSize(width: fixedWidth, height: CGFloat.greatestFiniteMagnitude))
            let newSize = messageBox.sizeThatFits(CGSize(width: fixedWidth, height: CGFloat.greatestFiniteMagnitude))
            var newFrame = messageBox.frame
            newFrame.size = CGSize(width: max(newSize.width, fixedWidth), height: newSize.height)
            messageBox.frame = newFrame
        }

    }

    @IBOutlet weak var messageBox: UITextView!

    @IBAction func messagePopupOK(_ sender: Any) {

        Feedback.messages.append(messageBox.text)

        dismiss(animated: false, completion: nil)
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }

}

extension UITextView: UITextViewDelegate {

    /// Resize the placeholder when the UITextView bounds change
    override open var bounds: CGRect {
        didSet {
            self.resizePlaceholder()
        }
    }

    /// The UITextView placeholder text
    public var placeholder: String? {
        get {
            var placeholderText: String?

            if let placeholderLabel = self.viewWithTag(100) as? UILabel {
                placeholderText = placeholderLabel.text
            }

            return placeholderText
        }
        set {
            if let placeholderLabel = self.viewWithTag(100) as? UILabel {
                placeholderLabel.text = newValue
                placeholderLabel.sizeToFit()
            } else {
                self.addPlaceholder(newValue!)
            }
        }
    }

    /// When the UITextView did change, show or hide the label based on if the UITextView is empty or not
    ///
    /// - Parameter textView: The UITextView that got updated
    public func textViewDidChange(_ textView: UITextView) {
        if let placeholderLabel = self.viewWithTag(100) as? UILabel {
            placeholderLabel.isHidden = self.text.characters.count > 0
        }
    }

    /// Resize the placeholder UILabel to make sure it's in the same position as the UITextView text
    private func resizePlaceholder() {
        if let placeholderLabel = self.viewWithTag(100) as! UILabel? {
            let labelX = self.textContainer.lineFragmentPadding
            let labelY = self.textContainerInset.top - 2
            let labelWidth = self.frame.width - (labelX * 2)
            let labelHeight = placeholderLabel.frame.height

            placeholderLabel.frame = CGRect(x: labelX, y: labelY, width: labelWidth, height: labelHeight)
        }
    }

    /// Adds a placeholder UILabel to this UITextView
    private func addPlaceholder(_ placeholderText: String) {
        let placeholderLabel = UILabel()

        placeholderLabel.text = placeholderText
        placeholderLabel.sizeToFit()

        placeholderLabel.font = self.font
        placeholderLabel.textColor = UIColor.lightGray
        placeholderLabel.tag = 100

        placeholderLabel.isHidden = self.text.characters.count > 0

        self.addSubview(placeholderLabel)
        self.resizePlaceholder()
        self.delegate = self
    }

}

#endif
