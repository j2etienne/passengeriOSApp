//
//  DiscountCollectionViewController.swift
//  Passenger
//
//  Created by Connor Myers on 1/7/16.
//  Copyright © 2016 Astral. All rights reserved.
//

import UIKit

private let reuseIdentifier = "discountsCell"

class DiscountCollectionViewController: UICollectionViewController {
    
    let transitionManager = MenuTransitionManager()
    
    var companyName: String?
    
    var company: PFObject?
    
    var rowSelected = 0
    var indexPathSelected: NSIndexPath?
    
    var counter = 0
    let sectionInsets = UIEdgeInsets(top: 0.0, left: 0.0, bottom: 0.0, right: 0.0)
    
    var rewardsList = [Reward]()

    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Do any additional setup after loading the view.
        
        self.transitionManager.sourceViewController = self
        
        self.collectionView!.dataSource = self
        
        configureView()
        
        loadDiscounts()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // set transition delegate for our menu view controller
        
        if(segue.identifier == "presentMenu") {
            let menu = segue.destinationViewController as! UINavigationController
            menu.transitioningDelegate = self.transitionManager
            self.transitionManager.menuViewController = menu
            let dest = menu.topViewController as! RewardsDetailTableViewController
            dest.currentTitle = "DISCOUNTS"
            dest.rewardType = "Discounts"
        } else if(segue.identifier == "discountsToRedeem") {
            let nav = segue.destinationViewController as! UINavigationController
            let dest = nav.topViewController as! RedeemViewController
            dest.rewardDescription = rewardsList[rowSelected].getDescription()
            dest.rewardPointCost = rewardsList[rowSelected].pointCost
            dest.rewardImage = rewardsList[rowSelected].getRewardImage()
            dest.companyName = self.companyName
            dest.company = self.company
            dest.rewardName = rewardsList[rowSelected].getRewardName()
        }

        
    }
    
    func configureView() {
        // Change the font and size of nav bar text
        /*
        let swipeGestureRecognizer: UISwipeGestureRecognizer = UISwipeGestureRecognizer(target: self, action: "showRewardsViewController")
        swipeGestureRecognizer.direction = UISwipeGestureRecognizerDirection.Right
        self.view.addGestureRecognizer(swipeGestureRecognizer) */
        // Change the font and size of nav bar text
        
        let font = UIFont.systemFontOfSize(16, weight: UIFontWeightLight)
        
        let navBarAttributesDictionary: [String: AnyObject]? = [
            NSForegroundColorAttributeName: UIColor(red:0.04, green:0.37, blue:0.76, alpha:1.0),
            NSFontAttributeName: font
        ]
        navigationController?.navigationBar.barTintColor = UIColor.whiteColor()
        
        navigationController?.navigationBar.titleTextAttributes = navBarAttributesDictionary
        UINavigationBar.appearance().tintColor = UIColor.blackColor()
        self.title = companyName!.uppercaseString
    }
    
    func loadDiscounts() {
        
        let query = PFQuery(className:"RewardsExpanded")
        query.whereKey("company", equalTo: company!)
        query.findObjectsInBackgroundWithBlock {
            (objects: [PFObject]?, error: NSError?) -> Void in
            if error == nil {
                // The find succeeded.
                print("Successfully retrieved \(objects!.count) rewards.")
                // Do something with the found objects gameScore["playerName"] as String
                var i = 0
                if let objects = objects {
                    for object in objects {
                        let rewardImageFiles = object["rewardImage"] as! PFFile
                        var imageData = NSData()
                        
                        do {
                            imageData = try rewardImageFiles.getData()
                        } catch {
                            print("There was an error getting the data")
                        }
                        
                        let rewardImage = UIImage(data: imageData)!
                        let reward = Reward(companyName: self.companyName!, pointCost: object["pointCost"] as! Int, rewardImage: rewardImage, rewardPrice: object["rewardPrice"] as! Int, rewardDescription: object["rewardDescription"] as! String, rewardName: object["rewardName"] as! String)
                        self.rewardsList.append(reward)
                        self.collectionView!.reloadData()
                        
                        i = i + 1
                    }
                    self.collectionView!.reloadData()
                }
            } else {
                // Log details of the failure
                print("Error: \(error!) \(error!.userInfo)")
            }
        }
        self.collectionView!.reloadData()
        
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using [segue destinationViewController].
        // Pass the selected object to the new view controller.
    }
    */

    // MARK: UICollectionViewDataSource

    override func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }


    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of items
        return rewardsList.count
    }

    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> DiscountsCollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(reuseIdentifier, forIndexPath: indexPath) as! DiscountsCollectionViewCell
        
        // Configure the cell
        let currentReward = rewardsList[indexPath.row]
        
        cell.pointCostLabel.text = String(currentReward.getPointCost())
        cell.rewardDescriptionLabel.text = currentReward.getDescription()
        cell.rewardImageView.image = currentReward.getRewardImage()
        cell.rewardNameLabel.text = currentReward.getRewardName()
    
        return cell
    }
    
    func collectionView(collectionView: UICollectionView!, layout collectionViewLayout: UICollectionViewLayout!, sizeForItemAtIndexPath indexPath: NSIndexPath!) -> CGSize {
        
        let collectionViewWidth = self.collectionView!.bounds.size.width
        return CGSize(width: ((collectionViewWidth/2) - 1.0), height: ((collectionViewWidth/2) - 1.0))
        
    }
    
    func collectionView(collectionView: UICollectionView!,layout collectionViewLayout: UICollectionViewLayout!,insetForSectionAtIndex section: Int) -> UIEdgeInsets {
        
        return sectionInsets
        
    }
    
    override func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        rowSelected = indexPath.row
        indexPathSelected = indexPath
        performSegueWithIdentifier("discountsToRedeem", sender: nil)
    }

    // MARK: UICollectionViewDelegate

    /*
    // Uncomment this method to specify if the specified item should be highlighted during tracking
    override func collectionView(collectionView: UICollectionView, shouldHighlightItemAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    */

    
    // Uncomment this method to specify if the specified item should be selected
    override func collectionView(collectionView: UICollectionView, shouldSelectItemAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    

    /*
    // Uncomment these methods to specify if an action menu should be displayed for the specified item, and react to actions performed on the item
    override func collectionView(collectionView: UICollectionView, shouldShowMenuForItemAtIndexPath indexPath: NSIndexPath) -> Bool {
        return false
    }

    override func collectionView(collectionView: UICollectionView, canPerformAction action: Selector, forItemAtIndexPath indexPath: NSIndexPath, withSender sender: AnyObject?) -> Bool {
        return false
    }

    override func collectionView(collectionView: UICollectionView, performAction action: Selector, forItemAtIndexPath indexPath: NSIndexPath, withSender sender: AnyObject?) {
    
    }
    */

}
