//
//  RoutineEditCoordinator.swift
//
//  Copyright © 2023 John Shimmin. All rights reserved.
//

import Factory
import Foundation

protocol RoutineEditCoordinator: AnyObject, Coordinator {
    func showSearchDialog(responder: ScaleSearchViewModelResponder)
    func showNameDialog(viewModel: RoutineEditViewModel, isCreateFlow: Bool, validator: @escaping ((String) -> SingleValueEditor.ValidationResult))
}

class RoutineEditCoordinatorImpl: RoutineEditCoordinator {
    private let presenter: UIViewController
    private var editViewController: UIViewController?
    private var routine: PracticeRoutine?
    private var responder: RoutineEditResponder

    @Injected(Container.viewControllerFactory) private var viewControllerFactory: ViewControllerFactory

    init(routine: PracticeRoutine?, presenter: UIViewController, responder: RoutineEditResponder) {
        self.routine = routine
        self.presenter = presenter
        self.responder = responder

    }

    func start() {
        editViewController = viewControllerFactory.createRoutineEditViewController(routine: routine, coordinator: self, responder: responder)

        presenter.present(editViewController!, animated: true)
    }

    func showSearchDialog(responder: ScaleSearchViewModelResponder) {
        guard let editViewController = editViewController else {
            fatalError("editViewController not set -- was start() called?")
        }
        let vc = viewControllerFactory.createScaleSearchViewController(responder: responder)
        editViewController.present(vc, animated: true)
    }

    func showNameDialog(viewModel: RoutineEditViewModel, isCreateFlow: Bool, validator: @escaping ((String) -> SingleValueEditor.ValidationResult)) {
        guard let editViewController = editViewController else {
            fatalError("editViewController not set -- was start() called?")
        }
        let placeholderText = "Routine name"

        var title = "Edit"
        var message = "Edit Routine Name"
        if isCreateFlow {
            title = "Create"
            message = "Create New Routine"
        }

        let valueEditor = SingleValueEditor(
            title: title,
            message: message,
            placeholderText: placeholderText,
            value: viewModel.name) { [weak viewModel] name in
                viewModel?.updateName(name)
            }
        valueEditor.valueValidator = validator

        editViewController.present(valueEditor, animated: true)
    }
}
