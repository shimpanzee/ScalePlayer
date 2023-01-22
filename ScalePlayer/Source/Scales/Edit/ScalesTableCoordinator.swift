//
//  ScalesTableCoordinator.swift
//
//  Copyright © 2023 John Shimmin. All rights reserved.
//

import Factory
import Foundation

protocol ScalesTableCoordinator: AnyObject, Coordinator {
    func showScalePerform(for scale: PracticeScale)
    func showScaleEdit(for scale: PracticeScale?, responder: ScaleEditResponder)
}

class ScalesTableCoordinatorImpl: ScalesTableCoordinator {
    @Injected(Container.viewControllerFactory) private var viewControllerFactory: ViewControllerFactory

    var coordinator: ScalesEditCoordinator?
    let presenter: UIViewController

    init(presenter: UIViewController) {
        self.presenter = presenter
    }

    func showScalePerform(for scale: PracticeScale) {
        let vc = viewControllerFactory.createPerformScaleViewController(scale: scale)
        presenter.present(vc, animated: true)
    }

    func showScaleEdit(for scale: PracticeScale?, responder: ScaleEditResponder) {
        let newCoordinator = ScalesEditCoordinatorImpl(scale: scale, presenter: presenter, responder: responder)
        coordinator = newCoordinator
        newCoordinator.start()
    }

    func start() {

    }
}
