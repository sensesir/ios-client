//
//  AppDelegate.swift
//  garage-sensor
//
//  Created by Josh Perry on 2018/04/09.
//  Copyright © 2018 IoT South Africa. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        print("APP DELEGATE: Here we go, firing up!");
        
        // Initialize firebase & user data
        let userHasToken = GDoorUser.sharedInstance.userSignedIn()
        assessUILaunchTransition(accessToken: userHasToken)
        
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
        print("APP DELEGATE: App entering background")
        // GDoorUser.sharedInstance.updateLastSeenTime() /* Not currently function - very quick app suspension */
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        GDoorUser.sharedInstance.updateLastSeenTime()
        if (GDoorModel.main.sensorUID != nil) {
            GDoorModel.main.updateModel()
            GDoorModel.main.assessIoTConnection()
        }
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
    func assessUILaunchTransition(accessToken: Bool!) {
        // Looks at the user object and
        if (accessToken) {
            // Go into the main app
            print("APP DELEGATE: Launching main UI")
            let mainStory = UIStoryboard(name: "Main", bundle: nil)
            let mainVC = mainStory.instantiateInitialViewController()
            
            // Present over current VC
            window?.rootViewController = mainVC
        }
        
        else{
            // Go into onboarding
            print("APP DELEGATE: Launching onboarding")
            let onboardStory = UIStoryboard(name: "Onboarding", bundle: nil)
            let signupVC = onboardStory.instantiateInitialViewController()
            
            // Present over current VC
            window?.rootViewController = signupVC
        }
    }


}

