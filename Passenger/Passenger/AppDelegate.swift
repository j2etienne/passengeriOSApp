//
//  AppDelegate.swift
//  Passenger
//
//  Created by Connor Myers on 11/2/15.
//  Copyright © 2015 Astral. All rights reserved.
//

import UIKit
import Bolts
import FBSDKCoreKit
import ParseFacebookUtilsV4
import CoreLocation
import HealthKit
import Firebase

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    let ref = Firebase(url: "https://passenger-app.firebaseio.com")
    
    var window: UIWindow?

    var currentUser: PFUser?
    
    var pointsPerMinute = 0.0055
    var pointsPerMile = 0.5
    
    var totalCurrentPoints = 0.0
    var phoneScreenIsOff = true
    var isDrivingSpeedLimit = true
    var everyTenSeconds = 0
    var distanceTraveledInTen = 0.0
    
    var currentSpeedIsZero = 0
    
    var isSittingStillCount = 0
    var isDriving = true
    var stoppedDriving = true
    
    var seconds = 0.0
    var distance = 0.0
    
    var currentSpeed = 0.0
    var averageSpeedOverTen = 0.0
    
    var boolean: Bool?
    
    var currentUserTotalPoints = 0.0
    var currentUserCurrentPoints = 0.0
    var currentUserCurrentDistance = 0.0
    var currentUserTimeSpentDriving = 0.0
    
    var previousLocation: CLLocation?
    var currentLocation: CLLocation?
    
    lazy var locationManager: CLLocationManager = {
        var _locationManager = CLLocationManager()
        _locationManager.delegate = self
        _locationManager.desiredAccuracy = kCLLocationAccuracyBest
        _locationManager.requestAlwaysAuthorization()
        _locationManager.allowsBackgroundLocationUpdates = true
        _locationManager.activityType = .AutomotiveNavigation
        _locationManager.pausesLocationUpdatesAutomatically = false
        
        // Movement threshold for new events
        _locationManager.distanceFilter = 10.0
        return _locationManager
    }()
    
    lazy var locations = [CLLocation]()
    lazy var timer = NSTimer()

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        // Override point for customization after application launch.
        // [Optional] Power your app with Local Datastore. For more info, go to
        // https://parse.com/docs/ios_guide#localdatastore/iOS
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        
        Parse.enableLocalDatastore()
        
        // Initialize Parse.
        Parse.setApplicationId("kGhDAAyw5RwtYNrm70j8cYHlOPj60A9rnJ0UI0o1",
            clientKey: "JeIYcqqk1S8nNaJ1SChjSPemYlyxPbA8Z4p8CB8b")
        
        // [Optional] Track statistics around application opens.
        PFAnalytics.trackAppOpenedWithLaunchOptions(launchOptions)
        
        PFFacebookUtils.initializeFacebookWithApplicationLaunchOptions(launchOptions)
        
        if(NSUserDefaults.standardUserDefaults().boolForKey("HasLaunchedOnce"))
        {
            // app already launched

            UITabBar.appearance().tintColor = UIColor(red:0.04, green:0.37, blue:0.76, alpha:1.0)
            UITabBar.appearance().barTintColor = UIColor.whiteColor()
            
            self.window = UIWindow(frame: UIScreen.mainScreen().bounds)

            if ref.authData != nil {
                // user authenticated
                let initialViewController = storyboard.instantiateViewControllerWithIdentifier("homeViewController")
                
                self.window?.rootViewController = initialViewController
                self.window?.makeKeyAndVisible()
                locationManager.requestAlwaysAuthorization()
                
                print("This is the login data for the user \(ref.authData)")
                
                // Need to comment the below until the database has been completely switched over to parse to get this data
                
//                currentUserTotalPoints = currentUser!["totalPoints"] as! Double
//                currentUserCurrentPoints = currentUser!["currentPoints"] as! Double
//                print("The users current points \(currentUserCurrentPoints)")
                
            } else {
                // No user is signed in
                // Show the first screen
                let initialViewController = storyboard.instantiateViewControllerWithIdentifier("firstViewController")
                
                self.window?.rootViewController = initialViewController
                self.window?.makeKeyAndVisible()
                print("This is the login data for the user \(ref.authData)")
            }
            
//            currentUser = PFUser.currentUser()
//            if currentUser != nil {
//                // Do stuff with the user
//                let initialViewController = storyboard.instantiateViewControllerWithIdentifier("homeViewController")
//                
//                self.window?.rootViewController = initialViewController
//                self.window?.makeKeyAndVisible()
//                locationManager.requestAlwaysAuthorization()
//                currentUserTotalPoints = currentUser!["totalPoints"] as! Double
//                currentUserCurrentPoints = currentUser!["currentPoints"] as! Double
//                print("The users current points \(currentUserCurrentPoints)")
//                
//            } else {
//                // Show the first screen
//                let initialViewController = storyboard.instantiateViewControllerWithIdentifier("firstViewController")
//                
//                self.window?.rootViewController = initialViewController
//                self.window?.makeKeyAndVisible()
//            }
            
            seconds = 0.0
            distance = 0.0
            locations.removeAll(keepCapacity: false)
            timer = NSTimer.scheduledTimerWithTimeInterval(1,
                target: self,
                selector: "eachSecond:",
                userInfo: nil,
                repeats: true)
            startLocationUpdates()

        } else {
            
            // This is the first launch ever
            NSUserDefaults.standardUserDefaults().setBool(true, forKey: "HasLaunchedOnce")
            NSUserDefaults.standardUserDefaults().synchronize()
            
            let initialViewController = storyboard.instantiateViewControllerWithIdentifier("firstLaunchViewController")
            
            self.window?.rootViewController = initialViewController
            self.window?.makeKeyAndVisible()
        }

        return true
    }
    
    func application(application: UIApplication,
        openURL url: NSURL,
        sourceApplication: String?,
        annotation: AnyObject) -> Bool {
            return FBSDKApplicationDelegate.sharedInstance().application(application,
                openURL: url,
                sourceApplication: sourceApplication,
                annotation: annotation)
    }
    
    
    //Make sure it isn't already declared in the app delegate (possible redefinition of func error)
    func applicationDidBecomeActive(application: UIApplication) {
        FBSDKAppEvents.activateApp()
        
    }

    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(application: UIApplication) {

    }

    func applicationWillEnterForeground(application: UIApplication) {

        if (currentUser != nil) {
            self.currentUser?.fetchInBackground()
        }
        
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        
        if (totalCurrentPoints > 0.75) {
            let pointRecord = PFObject(className:"PointsHistory")
            pointRecord["distanceTraveled"] = distance * 0.000189394
            pointRecord["pointsGenerated"] = totalCurrentPoints
            pointRecord["userID"] = currentUser!
            pointRecord.saveInBackgroundWithBlock {
                (success: Bool, error: NSError?) -> Void in
                if (success) {
                    // The object has been saved.
                    print("The record was saved now time to save the users data.")
                } else {
                    // There was a problem, check error.description
                    print("There was an error sabing the object")
                }
            }
            
            // When the user is about to exit the app, we need to save the amount of points that they have gained before the app dies.
            self.currentUserTotalPoints = currentUser!["totalPoints"] as! Double
            self.currentUserCurrentPoints = currentUser!["currentPoints"] as! Double
            self.currentUserCurrentDistance = currentUser!["distanceTraveled"] as! Double
            self.currentUserTimeSpentDriving = currentUser!["timeSpendDriving"] as! Double
            // The user is finished driving. Save the drive in parse and begin to wait till they start moving again.
            self.currentUser?["totalPoints"] = currentUserTotalPoints + totalCurrentPoints
            self.currentUser?["currentPoints"] = currentUserCurrentPoints + totalCurrentPoints
            self.currentUser?["distanceTraveled"] = currentUserCurrentDistance + ((distance * 3.28084) * 0.000189394) // Conversion from feet to miles
            self.currentUser?["timeSpendDriving"] = seconds + currentUserTimeSpentDriving
            currentUser?.saveInBackgroundWithBlock{
                (success: Bool, error: NSError?) -> Void in
                if (success) {
                    // The object has been saved.
                    print("The user was saved before the app was shut down completely")
                } else {
                    // There was a problem, check error.description
                }
            }

        }
        
    }

    func eachSecond(timer: NSTimer) {
        
        let instanceOfCustomObject: Notifier = Notifier()
        instanceOfCustomObject.registerAppforDetectLockState()
        let isLocked = instanceOfCustomObject.isLocked()
        
        if (((everyTenSeconds % 10) == 0 && isLocked) && isDriving && seconds > 1.0) {
        
            self.addScreenOffPoints()
            phoneScreenIsOff = true
            distanceTraveledInTen = 0
            print(totalCurrentPoints)
            
        }

        seconds++
        
        if (distanceTraveledInTen < 50) {
            currentSpeed = 0.0
            isSittingStillCount++
            if (isSittingStillCount > 120 && stoppedDriving) {
                if (totalCurrentPoints > 0.75) {
                    self.isSittingStillCount = 0
                    self.stoppedDriving = true
                    let pointRecord = PFObject(className:"PointsHistory")
                    pointRecord["distanceTraveled"] = (distance * 3.28084) * 0.000189394
                    pointRecord["pointsGenerated"] = totalCurrentPoints
                    pointRecord["userID"] = currentUser!
                    
                    do {
                        try pointRecord.save()
                        print("The record was saved now time to save the users data.")
                    } catch {
                        print("There was an error sabing the object")
                    }
                    pointRecord.saveInBackgroundWithBlock {
                        (success: Bool, error: NSError?) -> Void in
                        if (success) {
                            // The object has been saved.
                            
                        } else {
                            // There was a problem, check error.description
                            
                        }
                    }
                    
                    self.currentUserTotalPoints = currentUser!["totalPoints"] as! Double
                    self.currentUserCurrentPoints = currentUser!["currentPoints"] as! Double
                    self.currentUserCurrentDistance = currentUser!["distanceTraveled"] as! Double
                    self.currentUserTimeSpentDriving = currentUser!["timeSpendDriving"] as! Double
                    // The user is finished driving. Save the drive in parse and begin to wait till they start moving again.
                    self.currentUser?["totalPoints"] = currentUserTotalPoints + totalCurrentPoints
                    self.currentUser?["currentPoints"] = currentUserCurrentPoints + totalCurrentPoints
                    self.currentUser?["distanceTraveled"] = currentUserCurrentDistance + ((distance * 3.28084) * 0.000189394) // Conversion from feet to miles
                    self.currentUser?["timeSpendDriving"] = seconds + currentUserTimeSpentDriving
                    
                    do {
                        try self.currentUser?.save()
                        print("The points have been saved for this user but the location services are still looking out to see if they begin driving")
                        self.totalCurrentPoints = 0
                        self.distance = 0.0
                        self.seconds = 0.0
                    } catch {
                        
                    }
//                    currentUser?.saveInBackgroundWithBlock{
//                        (success: Bool, error: NSError?) -> Void in
//                        if (success) {
//                            // The object has been saved.
//
//                        } else {
//                            // There was a problem, check error.description
//                        }
//                    }
   
                } else {
                    totalCurrentPoints = 0.0
                }
                
            } else {
                // The user may be at a stop light or something.
                self.stoppedDriving = true
            }
            isDriving = false
        } else {
            isDriving = true
            self.stoppedDriving = false
            isSittingStillCount = 0
        }
        
        //print("Current speed: \(currentSpeed)")
        //print("Current Distance: \(distanceTraveledInTen)")
        //print("Is Driving: \(isDriving)")
        //print(isLocked)
        
        everyTenSeconds++
    }
    
    func startLocationUpdates() {
        // Here, the location manager will be lazily instantiated
        locationManager.startUpdatingLocation()
    }
    
    func addScreenOffPoints() {
        
        // Calculate the points for the phone being off
        
        totalCurrentPoints = totalCurrentPoints + (10 * 0.025)

    }
    
    
}
// MARK: - CLLocationManagerDelegate
extension AppDelegate: CLLocationManagerDelegate {
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        for location in locations as [CLLocation] {
            if location.horizontalAccuracy < 20 {
                //update distance
                if self.locations.count > 0 {
                    distance += location.distanceFromLocation(self.locations.last!)
                    let currentDistance = location.distanceFromLocation(self.locations.last!)
                    print(currentDistance)
                        currentSpeed = (location.distanceFromLocation(self.locations.last!)) * 2.23694
                        distanceTraveledInTen = distanceTraveledInTen + currentDistance
                }
                
                //save location
                self.locations.append(location)
            }
        }
    }
}

