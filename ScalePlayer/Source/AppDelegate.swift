//
//  AppDelegate.swift
//  ScalePlayer
//
//  Copyright © 2022 shimmin. All rights reserved.
//

import Factory
import Peek
import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    var appCoordinator: AppCoordinator!

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        window = UIWindow(frame: UIScreen.main.bounds)
        window?.makeKeyAndVisible()

#if PEEK_ENABLED
        window?.peek.enabled = true
#endif

        appCoordinator = AppCoordinatorImpl(window: window!)
        appCoordinator.start()

        return true
    }
}

#if PEEK_ENABLED
extension UIWindow {
    override open func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        if motion == .motionShake {
            peek.handleShake(motion)
        }
    }
}
#endif
