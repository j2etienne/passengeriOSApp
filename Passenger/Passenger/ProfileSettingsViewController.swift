//
//  ProfileSettingsViewController.swift
//  Passenger
//
//  Created by Connor Myers on 12/16/15.
//  Copyright © 2015 Astral. All rights reserved.
//

import UIKit
import Parse
import Bolts
import FBSDKCoreKit
import ParseFacebookUtilsV4
import Firebase

class ProfileSettingsViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UITextFieldDelegate {
    
    let ref = Firebase(url: "https://passenger-app.firebaseio.com")
    let usersRef = Firebase(url: "https://passenger-app.firebaseio.com/users/")
    let helpRef = Firebase(url: "https://passenger-app.firebaseio.com/help/")
    
    let transitionManager = MenuTransitionManager()
    
    let imagePicker = UIImagePickerController()
    
    private var fullName: String = ""
    private var updatedImage: UIImage?
    
    var senderViewController: String?
    var kbHeight: CGFloat!
    
    var didEditImage: Bool = false
    var userId: String?
    
    var initialFullName: String?
    var initialEmail: String?
    
    var base64String: NSString!
    
    @IBOutlet weak var profileImage: UIImageView!
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var connectToFacebookButton: UIButton!
    @IBOutlet weak var saveButton: UIButton!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var cameraImageView: UIImageView!
    @IBOutlet weak var profileSavedView: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        configureView()
        
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: "dismissKeyboard")
        view.addGestureRecognizer(tap)
        
        let profileImageTap = UITapGestureRecognizer(target:self, action: "imageTapped")
        profileImage.userInteractionEnabled = true
        profileImage.addGestureRecognizer(profileImageTap)
        
        self.transitionManager.sourceViewController = self
        nameTextField.delegate = self
        imagePicker.delegate = self
    }
    
    override func viewWillAppear(animated:Bool) {
        super.viewWillAppear(animated)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("keyboardWillShow:"), name: UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("keyboardWillHide:"), name: UIKeyboardWillHideNotification, object: nil)
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    func keyboardWillShow(notification: NSNotification) {
        if let userInfo = notification.userInfo {
            if let keyboardSize =  (userInfo[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.CGRectValue() {
                kbHeight = 0
                self.animateTextField(true)
            }
        }
    }
    
    func keyboardWillHide(notification: NSNotification) {
        self.animateTextField(false)
    }
    
    func animateTextField(up: Bool) {
        var movement = (up ? -kbHeight : kbHeight)
        
        UIView.animateWithDuration(0.3, animations: {
            self.view.frame = CGRectOffset(self.view.frame, 0, movement)
        })
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        
        return true
    }
    
    func imageTapped() {
            imagePicker.allowsEditing = false
            imagePicker.sourceType = .PhotoLibrary
            
            presentViewController(imagePicker, animated: true, completion: nil)

    }
    
    func dismissKeyboard() {
        //Causes the view (or one of its embedded text fields) to resign the first responder status.
        view.endEditing(true)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if(segue.identifier == "presentMenu") {
            // set transition delegate for our menu view controller
            if (senderViewController == "Profile") {
                let menu = segue.destinationViewController as! HomeNavigationViewController
                let targetController = menu.topViewController as! HomeViewController
                targetController.profile = true
                menu.transitioningDelegate = self.transitionManager
                self.transitionManager.menuViewController = menu
            } else {
                let menu = segue.destinationViewController as! HomeNavigationViewController
                let targetController = menu.topViewController as! HomeViewController
                targetController.helpSupport = true
                menu.transitioningDelegate = self.transitionManager
                self.transitionManager.menuViewController = menu
            }
            
        } else if (segue.identifier == "editProfileToForgotLoggedIn") {
            let menu = segue.destinationViewController as! UINavigationController
            let targetController = menu.topViewController as! ForgotPasswordLoggedInViewController
            targetController.profileSettingsSender = self.senderViewController
            menu.transitioningDelegate = self.transitionManager
            self.transitionManager.menuViewController = menu
        }
    }
    
    func configureView() {
        let font = UIFont.systemFontOfSize(16, weight: UIFontWeightLight)
        
        let navBarAttributesDictionary: [String: AnyObject]? = [
            NSForegroundColorAttributeName: UIColor(red:0.04, green:0.37, blue:0.76, alpha:1.0),
            NSFontAttributeName: font
        ]
        navigationController?.navigationBar.barTintColor = UIColor.whiteColor()
        
        navigationController?.navigationBar.titleTextAttributes = navBarAttributesDictionary
        
        UIApplication.sharedApplication().statusBarStyle = .Default
        
        let prefs = NSUserDefaults.standardUserDefaults()
        
        initialFullName = prefs.stringForKey("name")!
        initialEmail = prefs.stringForKey("email")!
        let profilePictureString = prefs.stringForKey("profilePictureString")!
        
        self.nameTextField.text = initialFullName
        
        let decodedData = NSData(base64EncodedString: profilePictureString, options: NSDataBase64DecodingOptions.IgnoreUnknownCharacters)
        
        let decodedImage = UIImage(data: decodedData!)
        
        self.profileImage?.image = decodedImage
        self.profileImage.layer.masksToBounds = true
        self.profileImage.layer.cornerRadius = 62.5
        self.cameraImageView.hidden = false
        
        userId = ref.authData.uid
        
        self.profileSavedView.layer.cornerRadius = 5

    }
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingImage image: UIImage!, editingInfo: [NSObject : AnyObject]!) {
        didEditImage = true
        let contextSize: CGSize = image.size
        
        let posX: CGFloat
        let posY: CGFloat
        let width: CGFloat
        let height: CGFloat
        
        // Check to see which length is the longest and create the offset based on that length, then set the width and height for our rect
        if contextSize.width > contextSize.height {
            posX = ((contextSize.width - contextSize.height) / 2)
            posY = 0
            width = contextSize.height
            height = contextSize.height
        } else {
            posX = 0
            posY = ((contextSize.height - contextSize.width) / 2)
            width = contextSize.width
            height = contextSize.width
        }
        
        let rect: CGRect = CGRectMake(posX, posY, width, height)
        
        // Create bitmap image from context using the rect
        let imageRef: CGImageRef = CGImageCreateWithImageInRect(image.CGImage, rect)!
        
        // Create a new image based on the imageRef and rotate back to the original orientation
        let imageFinal: UIImage = UIImage(CGImage: imageRef, scale: image.scale, orientation: image.imageOrientation)

        
        profileImage.contentMode = .ScaleAspectFit
        profileImage.image = imageFinal
        updatedImage = resizeImage(imageFinal, newWidth: 300)
        
        self.dismissViewControllerAnimated(true, completion: nil)
    }

    func imagePickerControllerDidCancel(picker: UIImagePickerController) {
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    @IBAction func connectToFacebookButtonTap(sender: AnyObject) {

    }
    
    func resizeImage(image: UIImage, newWidth: CGFloat) -> UIImage {
        
        let scale = newWidth / image.size.width
        let newHeight = image.size.height * scale
        UIGraphicsBeginImageContext(CGSizeMake(newWidth, newHeight))
        image.drawInRect(CGRectMake(0, 0, newWidth, newHeight))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage
    }
    
    @IBAction func saveButtonTap(sender: AnyObject) {
        let reachable = Reachability()
        if !(reachable.isConnectedToNetwork()) {
            let alert = UIAlertController(title: "INTERNET CONNECTION", message: "You are currently not connected to the internet. Make sure you are connected and try again.", preferredStyle: UIAlertControllerStyle.Alert)
            alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.Default, handler: nil))
            self.presentViewController(alert, animated: true, completion: nil)
            activityIndicator.hidden = true
            activityIndicator.stopAnimating()
        } else {
            
            usersRef.queryOrderedByChild("email").queryEqualToValue("\(ref.authData.providerData["email"]!)")
                .observeEventType(.ChildAdded, withBlock: { snapshot in

                    let currentUserId = snapshot.key
                    
                    let fullName: String = self.nameTextField.text!
                    
                    let currentUserRef = self.usersRef.childByAppendingPath(currentUserId!)
                    let prefs = NSUserDefaults.standardUserDefaults()
                    if (self.updatedImage != nil) {
                        print("The image is not nil")
                        let imageData: NSData = UIImagePNGRepresentation(self.updatedImage!)!
                        
                        self.base64String = imageData.base64EncodedStringWithOptions(.Encoding64CharacterLineLength)
                        let nameUpdated = ["name": fullName]
                        let profileImageUpdated = ["profileImage": self.base64String]
                        
                        self.nameTextField.text = fullName
                        
                        currentUserRef.updateChildValues(nameUpdated)
                        currentUserRef.updateChildValues(profileImageUpdated)
                        prefs.setValue(fullName, forKey: "name")
                        prefs.setValue(self.base64String, forKey: "profilePictureString")
                    } else {
                        print("The image is nil \(fullName)")
                        let nameUpdated = ["name": fullName]
                        
                        self.nameTextField.text = fullName
                        
                        currentUserRef.updateChildValues(nameUpdated)
                        prefs.setValue(fullName, forKey: "name")
                    }
                    
                    self.profileSavedView.hidden = false
                    let dispatchTime: dispatch_time_t = dispatch_time(DISPATCH_TIME_NOW, Int64(3.0 * Double(NSEC_PER_SEC)))
                    dispatch_after(dispatchTime, dispatch_get_main_queue(), {
                        // your function here
                        self.profileSavedView.hidden = true
                    })
                })
   
        }
    }

}
