//
//  RoutineTableCoordinator.swift
//
//  Copyright © 2023 John Shimmin. All rights reserved.
//

import Factory
import UIKit

protocol RoutineTableCoordinator: AnyObject, Coordinator {
    func showRoutineEdit(for routine: PracticeRoutine?, responder: RoutineEditResponder)
    func showRoutinePerform(for routine: PracticeRoutine)
}

class RoutineTableCoordinatorImpl: RoutineTableCoordinator {

    @Injected(Container.viewControllerFactory)
    private var viewControllerFactory: ViewControllerFactory

    private var coordinator: RoutineEditCoordinator?
    private let presenter: UIViewController

    init(presenter: UIViewController) {
        self.presenter = presenter
    }

    func showRoutineEdit(for routine: PracticeRoutine?, responder: RoutineEditResponder) {
        let newCoordinator = RoutineEditCoordinatorImpl(routine: routine, presenter: presenter, responder: responder)
        coordinator = newCoordinator
        newCoordinator.start()
    }

    func showRoutinePerform(for routine: PracticeRoutine) {
        let vc = viewControllerFactory.createPerformScaleViewController(routine: routine)
        presenter.present(vc, animated: true)
    }

    func start() {

    }
}
