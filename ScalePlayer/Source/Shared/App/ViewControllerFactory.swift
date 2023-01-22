//
//  ViewControllerFactory.swift
//  ScalePlayer
//
//  Created by John Shimmin on 1/12/23.
//  Copyright © 2023 shimmin. All rights reserved.
//

import Factory
import UIKit

class ViewControllerFactory {
    @Injected(Container.rootViewModel)
    private var rootViewModel: RootViewModel

    func createPerformScaleViewController(scale: PracticeScale) -> UIViewController {
        if scale.notes.isEmpty {
            return alertIncompleteScale()
        }
        let vc = PerformScaleViewController(viewModel: PerformScaleViewModel(scale: scale))
        let navController = UINavigationController(rootViewController: vc)
        navController.modalPresentationStyle = .fullScreen
        return navController
    }

    func alertIncompleteScale() -> UIViewController {
        let alert = UIAlertController(
            title: "Warning",
            message: "Scale does not have any notes",
            preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .default))
        return alert
    }

    func makeScalesTableViewController(coordinator: ScalesTableCoordinator) -> UIViewController {
        return ScalesTableViewController(viewModel: ScalesTableViewModel(coordinator: coordinator))
    }

    func makePerformScalesTableViewController(coordinator: ScalesTableCoordinator) -> UIViewController {
        return PerformScalesTableViewController(viewModel: ScalesTableViewModel(coordinator: coordinator))
    }

    func makeRoutinesTableViewController(coordinator: RoutineTableCoordinator) -> UIViewController {
        return RoutinesTableViewController(viewModel: RoutinesTableViewModel(coordinator: coordinator))
    }

    func makePerformRoutinesTableViewController(coordinator: RoutineTableCoordinator) -> UIViewController {
        return PerformRoutinesTableViewController(viewModel: RoutinesTableViewModel(coordinator: coordinator))
    }

    func createScaleSearchViewController(responder: ScaleSearchViewModelResponder)
        -> ScaleSearchViewController {
        return ScaleSearchViewController(viewModel: ScaleSearchViewModel(responder: responder))
    }

    func createRoutineEditViewController(
        routine: PracticeRoutine?,
        coordinator: RoutineEditCoordinator,
        responder: RoutineEditResponder) -> UIViewController {

            let viewModel = RoutineEditViewModel(routine: routine, coordinator: coordinator, responder: responder)
        let viewController = RoutineEditViewController(viewModel: viewModel)

        return UINavigationController(rootViewController: viewController)
    }

    func createPerformScaleViewController(routine: PracticeRoutine) -> UIViewController {
        if (routine.scales?.count ?? nil) == 0 {
            return alertIncompleteRoutine()
        }
        let viewModel = PerformScaleViewModel(routine: routine)
        let vc = PerformScaleViewController(viewModel: viewModel)

        return UINavigationController(rootViewController: vc)
    }

    func alertIncompleteRoutine() -> UIViewController {
        let alert = UIAlertController(
            title: "Warning",
            message: "Routine does not have any scales",
            preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .default))
        return alert
    }

    func createScaleEditViewController(scale: PracticeScale?,
                                       coordinator: ScalesEditCoordinator,
                                       responder: ScaleEditResponder) -> UIViewController {
        let viewModel = ScaleEditViewModel(scale: scale, coordinator: coordinator, responder: responder)
        let viewController = ScaleEditViewController(viewModel: viewModel)

        return UINavigationController(rootViewController: viewController)
    }
}
