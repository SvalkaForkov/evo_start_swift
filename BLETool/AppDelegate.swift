//
//  AppDelegate.swift
//  BLETool
//
//  Created by Xiaotu Zhang on 2016-02-18.
//  Copyright © 2016 fortin. All rights reserved.
//

import UIKit
import CoreData
import GoogleMaps
@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    var dataController: DataController!

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        // Override point for customization after application launch.
        self.dataController = DataController()
        GMSServices.provideAPIKey("AIzaSyDr_7IWaJcZTOtkm-Sh-AwPIs4EW_NwuDo")
        
        application.registerUserNotificationSettings(UIUserNotificationSettings(forTypes: UIUserNotificationType.Alert , categories: nil))
        
        return true
    }

    func applicationWillResignActive(application: UIApplication) {
                UIApplication.sharedApplication().applicationIconBadgeNumber = 1
    }

    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }

    func application(application: UIApplication, didReceiveLocalNotification notification: UILocalNotification) {
        	application.applicationIconBadgeNumber = 0
    }

}

