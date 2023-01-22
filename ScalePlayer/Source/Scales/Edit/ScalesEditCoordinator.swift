//
//  ScalesEditCoordinator.swift
//
//  Copyright © 2023 John Shimmin. All rights reserved.
//

import Factory
import Foundation

protocol ScalesEditCoordinator: AnyObject, Coordinator {
    func showNameDialog(viewModel: ScaleEditViewModel, isCreateFlow: Bool, validator: @escaping ((String) -> SingleValueEditor.ValidationResult))
}

class ScalesEditCoordinatorImpl: ScalesEditCoordinator {
    @Injected(Container.viewControllerFactory) private var viewControllerFactory: ViewControllerFactory

    private let presenter: UIViewController
    private var editViewController: UIViewController?
    private var scale: PracticeScale?
    private var responder: ScaleEditResponder

    init(scale: PracticeScale?, presenter: UIViewController, responder: ScaleEditResponder) {
        self.scale = scale
        self.presenter = presenter
        self.responder = responder
    }

    func start() {
        editViewController = viewControllerFactory.createScaleEditViewController(scale: scale, coordinator: self, responder: responder)
        presenter.present(editViewController!, animated: true)
    }

    func showNameDialog(viewModel: ScaleEditViewModel, isCreateFlow: Bool, validator: @escaping ((String) -> SingleValueEditor.ValidationResult)) {
        guard let editViewController = editViewController else {
            fatalError("editViewController not set -- was start() called?")
        }
        let placeholderText = "Scale name"

        var title = "Edit"
        var message = "Edit Scale Name"
        if isCreateFlow {
            title = "Create"
            message = "Create New Scale"
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
