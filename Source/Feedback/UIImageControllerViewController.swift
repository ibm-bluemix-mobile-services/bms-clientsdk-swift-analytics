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

class UIImageControllerViewController: UIViewController {

    var path = UIBezierPath()
    var startpoint = CGPoint()
    var touchpoint = CGPoint()
    static var touchEnabled: Bool = false
    static var isMarkerBtnPressed: Bool = false
    static var isComposeBtnPressed: Bool = false
    static var ext: UIImage?
    static var counter: Int = 0
    static var isImageEdited: Bool = false

    @IBOutlet weak var composeBtn: UIBarButtonItem!
    @IBOutlet weak var editBtn: UIBarButtonItem!
    @IBOutlet weak var markerBtn: UIBarButtonItem!

    @IBOutlet weak var compBtn: UIBarButtonItem!

    @IBOutlet weak var imageView: UIImageView!

    @IBOutlet var imageViewGesture: UITapGestureRecognizer!

    @IBAction func editButtonTapped(_ sender: Any) {
        if UIImageControllerViewController.isMarkerBtnPressed == true {
            UIImageControllerViewController.isMarkerBtnPressed = false
            markerBtn.tintColor = UIColor.black
        }
        if UIImageControllerViewController.isComposeBtnPressed == true {
            UIImageControllerViewController.isComposeBtnPressed = false
            compBtn.tintColor = UIColor.black
        }
        if editBtn.tintColor == UIColor.black {
            imageView.isUserInteractionEnabled = true
            editBtn.tintColor = UIColor.orange
            UIImageControllerViewController.touchEnabled = true
        } else {
            editBtn.tintColor = UIColor.black
            UIImageControllerViewController.touchEnabled = false
        }
    }

    @IBAction func markerButtonTapped(_ sender: UIBarButtonItem) {
        if UIImageControllerViewController.touchEnabled == true {
            UIImageControllerViewController.touchEnabled = false
            editBtn.tintColor = UIColor.black
        }
        if UIImageControllerViewController.isComposeBtnPressed == true {
            UIImageControllerViewController.isComposeBtnPressed = false
            compBtn.tintColor = UIColor.black
        }
        if markerBtn.tintColor == UIColor.black {
            UIImageControllerViewController.isMarkerBtnPressed = true
            markerBtn.tintColor = UIColor.orange
            UIImageControllerViewController.touchEnabled = true
        } else {
            markerBtn.tintColor = UIColor.black
            UIImageControllerViewController.isMarkerBtnPressed = false
            UIImageControllerViewController.touchEnabled = false
        }
    }

    @IBAction func composeButtonTapped(_ sender: Any) {
        if UIImageControllerViewController.isComposeBtnPressed {
            UIImageControllerViewController.isComposeBtnPressed = false
        } else {
            UIImageControllerViewController.isComposeBtnPressed = true
        }
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let vc = segue.destination as! ComposeEditorViewController
        vc.modalPresentationStyle = UIModalPresentationStyle.overCurrentContext // All objects and view are transparent
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        imageView.isUserInteractionEnabled = false
        UIImageControllerViewController.touchEnabled = false
        UIImageControllerViewController.isImageEdited = false
        UIImageControllerViewController.counter=0
        // Do any additional setup after loading the view.
        imageView.clipsToBounds = true
        imageView.isMultipleTouchEnabled = false
        markerBtn.tintColor = UIColor.black

        // Tap Gesture Function
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(normalTap(_:)))
        tapGesture.numberOfTapsRequired = 1
        imageView.addGestureRecognizer(tapGesture)
    }

    @objc func normalTap(_ sender: UIGestureRecognizer) {
        // drawImageView(mainImage: #imageLiteral(resourceName: "edit-1"), withBadge:#imageLiteral(resourceName: "eraser") )
    }

    func drawImageView(mainImage: UIImage, withBadge badge: UIImage) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(mainImage.size, false, 0.0)
        mainImage.draw(in: CGRect(x: 0, y: 0, width: mainImage.size.width, height: mainImage.size.height))
        badge.draw(in: CGRect(x: mainImage.size.width - badge.size.width, y: 0, width: badge.size.width, height: badge.size.height))

        let resultImage: UIImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return resultImage
    }

    override func viewWillAppear(_ animated: Bool) {
        imageView.image = Feedback.screenshot
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {

        let touch = touches.first
        if let point = touch?.location(in: imageView) {
            startpoint = point
        }

        if !UIImageControllerViewController.touchEnabled && UIImageControllerViewController.isComposeBtnPressed {
            addComment(touches)
        }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        if UIImageControllerViewController.touchEnabled {
            let touch = touches.first
            if let point = touch?.location(in: imageView) {
                touchpoint = point
            }
            path.move(to: startpoint)
            path.addLine(to: touchpoint)
            startpoint = touchpoint

            // call  draw
            draw()
        }
    }

    func addComment(_ touches: Set<UITouch>) {
        UIImageControllerViewController.isImageEdited = true

        let touch = touches.first
        if let point = touch?.location(in: imageView) {
            touchpoint = point
        }

        path.move(to: startpoint)
        startpoint = touchpoint

        if imageView.point(inside: startpoint, with: nil) {
            // Draw Circle
            path =  UIBezierPath(arcCenter: CGPoint(x: touchpoint.x, y: touchpoint.y), radius: CGFloat(20), startAngle: CGFloat(0), endAngle: CGFloat(Double.pi * 2), clockwise: true)
            let strokeLayer = CAShapeLayer()
            strokeLayer.fillColor = UIColor.orange.cgColor
            strokeLayer.strokeColor = UIColor.orange.cgColor

            let textLayer = CATextLayer()
            textLayer.frame = CGRect(x: touchpoint.x-5, y: touchpoint.y-10, width: 20, height: 20)
            textLayer.font = UIFont(name: "Helvetica-Bold", size: 18)
            textLayer.fontSize = 18
            textLayer.foregroundColor = UIColor.black.cgColor
            textLayer.backgroundColor = UIColor.orange.cgColor
            UIImageControllerViewController.counter = UIImageControllerViewController.counter+1
            textLayer.string = String(UIImageControllerViewController.counter)

            strokeLayer.path = path.cgPath
            strokeLayer.addSublayer(textLayer)
            imageView.layer.addSublayer(strokeLayer)
            imageView.setNeedsDisplay()
            path = UIBezierPath()

            performSegue(withIdentifier: "segueModal", sender: self)
        }
    }

    func draw() {
        UIImageControllerViewController.isImageEdited = true

        let strokeLayer = CAShapeLayer()
        strokeLayer.fillColor = nil
        strokeLayer.lineWidth = 5
        strokeLayer.strokeColor = UIColor.orange.cgColor
        if UIImageControllerViewController.isMarkerBtnPressed {
            strokeLayer.lineWidth = 15
            strokeLayer.strokeColor = UIColor.gray.cgColor
        }
        strokeLayer.path = path.cgPath
        imageView.layer.addSublayer(strokeLayer)
        imageView.setNeedsDisplay()
        path = UIBezierPath()
    }

    @IBAction func composeFeedButton(_ sender: Any) {
        if UIImageControllerViewController.touchEnabled == true {
            UIImageControllerViewController.touchEnabled = false
            editBtn.tintColor = UIColor.black
        }
        if UIImageControllerViewController.isMarkerBtnPressed == true {
            UIImageControllerViewController.isMarkerBtnPressed = false
            markerBtn.tintColor = UIColor.black
        }
        if UIImageControllerViewController.isComposeBtnPressed {
            UIImageControllerViewController.isComposeBtnPressed = false
            compBtn.tintColor = UIColor.black
        } else {
            UIImageControllerViewController.isComposeBtnPressed = true
            compBtn.tintColor = UIColor.orange
        }
    }

    /* To add an erase/undo button
     @IBAction func eraseButton(_ sender: UIBarButtonItem) {
     path.removeAllPoints()
     imageView.layer.sublayers = nil
     imageView.setNeedsDisplay()
     } */

    @IBAction func closeButton(_ sender: Any) {
        if UIImageControllerViewController.isImageEdited {
            let alert = UIAlertController(title: "Close Feedback", message: "Do you want to Send or Discard the Feedback before exit?", preferredStyle: UIAlertControllerStyle.alert)
            alert.addAction(UIAlertAction(title: "Send", style: UIAlertActionStyle.default, handler: { action in self.sendFeedback() }))
            alert.addAction(UIAlertAction(title: "Discard", style: UIAlertActionStyle.cancel, handler: { action in self.dismiss(animated: false, completion: nil) }))
            self.present(alert, animated: true, completion: nil)
        } else {
            self.dismiss(animated: false, completion: nil)
        }
    }

    internal func sendFeedback() -> Void {
        UIGraphicsBeginImageContextWithOptions(imageView.bounds.size, false, UIScreen.main.scale)
        imageView.layer.render(in: UIGraphicsGetCurrentContext()!)
        Feedback.screenshot = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        Feedback.send(fromSentButton: true)

        let toastLabel = UILabel(frame: CGRect(x: 50, y: (self.view.frame.size.height/2) - 100, width: 300, height: 50))
        toastLabel.backgroundColor = UIColor.black.withAlphaComponent(0.8)
        toastLabel.textColor = UIColor.white
        toastLabel.textAlignment = .center
        toastLabel.font = UIFont(name: "Montserrat-Light", size: 12.0)
        toastLabel.text = "THANK YOU FOR THE FEEDBACK!"
        toastLabel.alpha = 1.0
        toastLabel.layer.cornerRadius = 10
        toastLabel.clipsToBounds  =  true
        self.view.addSubview(toastLabel)
        UIView.animate(withDuration: 1.0, delay: 0.1, options: .curveEaseOut, animations: {
            toastLabel.alpha = 0.0
        }, completion: { (isCompleted) in
            toastLabel.removeFromSuperview()
            self.dismiss(animated: false, completion: nil)
        })
    }

    @IBAction func doneButton(_ sender: UIBarButtonItem) {
        if UIImageControllerViewController.isImageEdited {
            self.sendFeedback()
        } else {
            let alert = UIAlertController(title: "Send Feedback", message: "Nothing to send, since no comments added. Do you want to exit?", preferredStyle: UIAlertControllerStyle.alert)
            alert.addAction(UIAlertAction(title: "Yes, Exit", style: UIAlertActionStyle.default, handler: { action in self.dismiss(animated: false, completion: nil) }))
            alert.addAction(UIAlertAction(title: "No, Cancel", style: UIAlertActionStyle.cancel, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
    }

}

#endif
