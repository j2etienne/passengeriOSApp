//
//  LegalViewController.swift
//  Passenger
//
//  Created by Connor Myers on 12/16/15.
//  Copyright © 2015 Astral. All rights reserved.
//

import UIKit

class LegalViewController: UIViewController {
    
    let transitionManager = MenuTransitionManager()

    @IBOutlet weak var otherButton: UIButton!
    @IBOutlet weak var privacyButton: UIButton!
    @IBOutlet weak var copyrightButton: UIButton!
    @IBOutlet weak var termsButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        configureView()
        self.transitionManager.sourceViewController = self
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if(segue.identifier == "presentMenu") {
            // set transition delegate for our menu view controller
            let menu = segue.destinationViewController as! HomeNavigationViewController
            let targetController = menu.topViewController as! HomeViewController
            targetController.helpSupport = true
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
        UINavigationBar.appearance().tintColor = UIColor.blackColor()
        
    }

    @IBAction func copyrightButtonDown(sender: AnyObject) {
        copyrightButton.backgroundColor = UIColor(red:0.89, green:0.89, blue:0.89, alpha:1.0)
    }
    
    @IBAction func copyrightButtonUp(sender: AnyObject) {
        copyrightButton.backgroundColor = UIColor.whiteColor()
    }
    
    @IBAction func termsButtonDown(sender: AnyObject) {
        termsButton.backgroundColor = UIColor(red:0.89, green:0.89, blue:0.89, alpha:1.0)
    }
    
    @IBAction func termsButtonUp(sender: AnyObject) {
        termsButton.backgroundColor = UIColor.whiteColor()
    }
    
    @IBAction func privacyButtonDown(sender: AnyObject) {
        privacyButton.backgroundColor = UIColor(red:0.89, green:0.89, blue:0.89, alpha:1.0)
    }
    
    @IBAction func privacyButtonUp(sender: AnyObject) {
        privacyButton.backgroundColor = UIColor.whiteColor()
    }
    
    @IBAction func otherButtonDown(sender: AnyObject) {
        otherButton.backgroundColor = UIColor(red:0.89, green:0.89, blue:0.89, alpha:1.0)
    }
    
    @IBAction func otherButtonUp(sender: AnyObject) {
        otherButton.backgroundColor = UIColor.whiteColor()
    }
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
