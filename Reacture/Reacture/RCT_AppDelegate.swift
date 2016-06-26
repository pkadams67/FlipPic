//
//  AppDelegate.swift
//  FlipPic
//
//  Created by Andrew Porter on 1/5/16. Amended by Paul Kirk Adams on 5/20/16.
//  Copyright © 2016 BAEPS. All rights reserved.
//

import UIKit
import Fabric
import Crashlytics
import LaunchKit

@UIApplicationMain

class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {

        Fabric.sharedSDK().debug = true
        Fabric.with([Crashlytics.self])
        // TODO: Move this to where you establish a user session
        self.logUser()

        // Initialize LaunchKit
        LaunchKit.launchWithToken("5BVpp5-2e7tKRD1ldaPRZK6gpJcWYaW_oWEEwvcJOqRL")
        LaunchKit.sharedInstance().debugMode = true
        LaunchKit.sharedInstance().verboseLogging = true

        // Uncomment for release build (remembers whether user showed onboarding)
        let defaults = NSUserDefaults.standardUserDefaults()
        let hasShownOnboarding = defaults.boolForKey("shownOnboardingBefore")
        if !hasShownOnboarding {
            let lk = LaunchKit.sharedInstance()
            lk.presentOnboardingUIOnWindow(self.window!) { _ in
                print("Showed onboarding!")
                defaults.setBool(true, forKey: "shownOnboardingBefore")
            }
        }

        // Uncomment for debugging (always show onboarding)
        //        let lk = LaunchKit.sharedInstance()
        //        lk.presentOnboardingUIOnWindow(self.window!) { _ in
        //            print("Showed onboarding!")
        //        }

        return true
    }

    func logUser() {
        // TODO: Use the current user's information
        // You can call any combination of these three methods
        Crashlytics.sharedInstance().setUserEmail("user@fabric.io")
        Crashlytics.sharedInstance().setUserIdentifier("12345")
        Crashlytics.sharedInstance().setUserName("Test User")
    }

    func applicationWillResignActive(application: UIApplication) {
    }

    func applicationDidEnterBackground(application: UIApplication) {
    }

    func applicationWillEnterForeground(application: UIApplication) {
    }

    func applicationDidBecomeActive(application: UIApplication) {
    }

    func applicationWillTerminate(application: UIApplication) {
    }
}