//
//  ConfirmSignupViewController.swift
//  signin
//
//  Created by Bruce Buckland on 7/23/16.
//  Copyright © 2016 Bruce Buckland. 
//  Permission is hereby granted, free of charge, to any person obtaining a 
//  copy of this software and associated documentation files (the "Software"),
//  to deal in the Software without restriction, including without limitation
//  the rights to use, copy, modify, merge, publish, distribute, sublicense,
//  and/or sell copies of the Software, and to permit persons to whom the
//  Software is furnished to do so, subject to the following conditions:
//  
//  The above copyright notice and this permission notice shall be included in 
//  all copies or substantial portions of the Software.
//  
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR 
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
//  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
//  IN THE SOFTWARE.
//

//

import UIKit
import AWSCore
import AWSCognitoIdentityProvider

class ConfirmSignupViewController: UIViewController {
    
    // properties
    
    var pool: AWSCognitoIdentityUserPool?
    var user: AWSCognitoIdentityUser?
    var sentTo: String?
    
    // Outlets
    
    @IBOutlet weak var confirmButton: FieldSensitiveUIButton!
    @IBOutlet weak var usernameField: UITextField!
    
    @IBOutlet weak var confirmationCodeField: UITextField!
    
    @IBOutlet weak var codeSentToLabel: UILabel!
    
    @IBOutlet weak var imageView: UIImageView!
    
    //MARK: Global Variables for Changing Image Functionality.
    var backgroundImageCycler: BackgroundImageCycle?
    
    
    override func viewWillAppear(_ animated: Bool) {
        self.navigationController?.setToolbarHidden(true, animated: false)
        if backgroundImageCycler == nil {
            backgroundImageCycler = BackgroundImageCycle(self.imageView, speed: 10 )
        }
        backgroundImageCycler?.start()
        
        AppColor.colorizeField(usernameField,confirmationCodeField)
        confirmButton.colorize(enabledBackgroundColor: AppColor.defaultColor)

    
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        backgroundImageCycler?.stop()
        backgroundImageCycler = nil
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        if backgroundImageCycler != nil {
            backgroundImageCycler?.stop()
            backgroundImageCycler = nil  // frees the image array
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.pool = AWSCognitoIdentityUserPool(forKey: "UserPool")
        
        // setup outlets
        usernameField.text = user?.username
        codeSentToLabel.text! += sentTo! // append destination to Label
        
        confirmButton.requiredFields(usernameField,confirmationCodeField)
        confirmButton.disable()
        
    }
    

    
    @IBAction func confirmPressed(_ sender: AnyObject) {
        self.user?.confirmSignUp(confirmationCodeField.text!).continue ({ (task) in
            // needs to be async so we can ALWAYS return nil for AWSTask
            DispatchQueue.main.async {
                
                if task.error != nil {  // some sort of error
                    let alert = UIAlertController(title: "", message: (task.error as? NSError)?.userInfo["message"] as? String, preferredStyle: UIAlertControllerStyle.alert)
                    alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
                    self.present(alert, animated: true, completion: nil)
                    
                    NSLog("\(task.error)")
                } else { // confirmed back to login
                    
// this was a no-no ... depended on a particular view controller calling me
//                    (self.navigationController!.viewControllers[0] as! LoginViewController).usernameText = self.user!.username
                    // this viewcontroller makes the assumption that
                    // it is called in a navigation controller
                    self.navigationController!.popToRootViewController(animated: true)
                    
                }
            }
            return nil
        })
    }
    
    @IBAction func resendConfirmationCodePressed(_ sender: AnyObject) {
        self.user?.resendConfirmationCode().continue({ (task) in
            // needs to be async so we can ALWAYS return nil for AWSTask
            DispatchQueue.main.async {
                
                if task.error != nil {  // some sort of error
                    let alert = UIAlertController(title: "", message: (task.error as? NSError)?.userInfo["message"] as? String, preferredStyle: UIAlertControllerStyle.alert)
                    alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
                    self.present(alert, animated: true, completion: nil)
                    
                    NSLog("\(task.error)")
                } else { // resend successful
                    let response: AWSCognitoIdentityUserResendConfirmationCodeResponse = task.result!
                    
                    let resentTo = response.codeDeliveryDetails?.destination
                    let alert = UIAlertController(title: "Code Resent", message:  "Code resent to: \(resentTo)", preferredStyle: UIAlertControllerStyle.alert)
                    alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
                    self.present(alert, animated: true, completion: nil)
                }
            }
            return nil
        })
    }
}
