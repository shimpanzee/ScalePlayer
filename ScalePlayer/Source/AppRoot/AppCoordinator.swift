//
//  AppCoordinator.swift
//
//  The base display is a UITabBar with two tabs (Practice/Edit) and a segmented
//  controller that chooses between Scales and Routines.  The coordinator
//  swaps between 4 different vcs depending on the selected tab bar item and
//  segement item.
//
//  Copyright © 2023 John Shimmin. All rights reserved.
//

import Factory
import UIKit

protocol AppCoordinator: AnyObject, Coordinator {
    func makeSegmentedControl() -> UISegmentedControl
}

class AppCoordinatorImpl: NSObject, AppCoordinator {

    enum ModeType: Int, RawRepresentable {
        case perform = 0
        case edit = 1
    }

    enum ObjectType: Int, RawRepresentable {
        case scales = 0
        case routines = 1
    }

    private var currentMode: ModeType = .perform
    private var currentObject: ObjectType = .scales

    private var scaleCoordinators = [ModeType: ScalesTableCoordinator]()
    private var routineCoordinators = [ModeType: RoutineTableCoordinator]()

    private let window: UIWindow

    private var rootViewController: RootViewController!
    private var tabItems = [UINavigationController(nibName: nil, bundle: nil), UINavigationController(nibName: nil, bundle: nil)]

    @Injected(Container.viewControllerFactory)
    private var viewControllerFactory: ViewControllerFactory

    init(window: UIWindow) {
        self.window = window

        super.init()

        rootViewController = RootViewController(segmentedControl: makeSegmentedControl())

        Container.errorHandler.register(factory: { [weak rootViewController] in
            if let rootViewController = rootViewController {
                return UserFacingErrorHandler(viewController: rootViewController)
            } else {
                return LoggingErrorHandler()
            }
        })
    }

    func start() {
        window.rootViewController = rootViewController

        let performTabItem = UITabBarItem(
            title: "Practice",
            image: UIImage(systemName: "music.note"),
            selectedImage: nil)

        let editTabItem = UITabBarItem(
            title: "Edit",
            image: UIImage(systemName: "pencil"),
            selectedImage: nil)

        tabItems[ModeType.perform.rawValue].tabBarItem = performTabItem
        tabItems[ModeType.edit.rawValue].tabBarItem = editTabItem

        rootViewController.viewControllers = tabItems
        rootViewController.delegate = self

        updateCurrentViewController()
    }

    func makeSegmentedControl() -> UISegmentedControl {
        let segmentedControl = UISegmentedControl(items: ["Scales", "Routines"])

        // Add function to handle Value Changed events
        segmentedControl.addTarget(
            self,
            action: #selector(segmentedValueChanged(_:)),
            for: .valueChanged)

        segmentedControl.selectedSegmentIndex = currentObject.rawValue

        return segmentedControl
    }

    @objc func segmentedValueChanged(_ segmentedControl: UISegmentedControl!) {
        currentObject = ObjectType(rawValue: segmentedControl.selectedSegmentIndex)!
        updateCurrentViewController()
    }

    private func getScaleViewController() -> UIViewController {
        let presenter = tabItems[currentMode.rawValue]
        var coordinator: ScalesTableCoordinator! = scaleCoordinators[currentMode]

        if coordinator == nil {
            coordinator = ScalesTableCoordinatorImpl(presenter: presenter)
            scaleCoordinators[currentMode] = coordinator
        }

        switch currentMode {
        case .perform:
            return viewControllerFactory.makePerformScalesTableViewController(coordinator: coordinator)
        case .edit:
            return viewControllerFactory.makeScalesTableViewController(coordinator: coordinator)
        }
    }

    private func getRoutineViewController() -> UIViewController {
        let presenter = tabItems[currentMode.rawValue]
        var coordinator: RoutineTableCoordinator! = routineCoordinators[currentMode]

        if coordinator == nil {
            coordinator = RoutineTableCoordinatorImpl(presenter: presenter)
            routineCoordinators[currentMode] = coordinator
        }

        switch currentMode {
        case .perform:
            return viewControllerFactory.makePerformRoutinesTableViewController(coordinator: coordinator)
        case .edit:
            return viewControllerFactory.makeRoutinesTableViewController(coordinator: coordinator)
        }
    }

    private func updateCurrentViewController() {
        var vc: UIViewController!

        switch currentObject {
        case .scales:
            vc = getScaleViewController()
        case .routines:
            vc = getRoutineViewController()
        }

        tabItems[currentMode.rawValue].viewControllers = [vc]
    }
}

extension AppCoordinatorImpl: UITabBarControllerDelegate {
    func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
        currentMode = ModeType(rawValue: tabBarController.selectedIndex)!
        updateCurrentViewController()
    }
}
