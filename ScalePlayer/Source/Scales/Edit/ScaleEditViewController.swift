//
//  ScaleEditViewController.swift
//  ScalePlayer
//
//  Copyright © 2022 shimmin. All rights reserved.
//

import Combine
import OSLog
import TinyConstraints
import UIKit

class ScaleEditViewController: UIViewController, UITextFieldDelegate {
    private var viewModel: ScaleEditViewModel
    private var scaleEditView: ScaleEditView
    private var toolbar: ScaleEditToolbar!

    private lazy var tempoLayoutGuide: UILayoutGuide = {
        let guide = UILayoutGuide()

        view.addLayoutGuide(guide)
        guide.centerX(to: view)
        guide.bottom(to: toolbar, toolbar.topAnchor, offset: -100)

        return guide
    }()

    private let nameEditView = NameEditView()

    private var subscriptions = Set<AnyCancellable>()

    init(viewModel: ScaleEditViewModel) {
        self.viewModel = viewModel
        scaleEditView = ScaleEditView(viewModel: viewModel)
        super.init(nibName: nil, bundle: nil)
        toolbar = ScaleEditToolbar(viewModel: viewModel) { [weak self] in
            self?.showTempoModal()
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("You should not instantiate this view controller by invoking init(coder:).")
    }

    // MARK: Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        view.layer.backgroundColor = UIColor.white.cgColor

        let guide = view.safeAreaLayoutGuide
        view.addSubview(toolbar)
        view.addSubview(scaleEditView)

        toolbar.edges(to: guide, excluding: [.top, .bottom])
        toolbar.bottom(to: guide)

        scaleEditView.edges(to: guide, excluding: [.top, .bottom])
        scaleEditView.top(to: guide)
        scaleEditView.bottomToTop(of: toolbar)

        scaleEditView.keys = .ranged(50 ... 70)

        viewModel.$title
            .assign(to: \.nameEditView.title, onWeak: self)
            .store(in: &subscriptions)

        viewModel.$editSessionComplete
            .filter { $0 }
            .sink { [weak self] _ in self?.dismiss(animated: true) }
            .store(in: &subscriptions)

        nameEditView.editCallback = { [weak self] in self?.viewModel.presentNameAlert() }

        navigationItem.titleView = nameEditView
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .save,
            target: self,
            action: #selector(save))
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .cancel,
            target: self,
            action: #selector(cancel))

    }

    func showTempoModal() {
        let tempoView = viewModel.createTempoView(guide: tempoLayoutGuide)
        view.addSubview(tempoView)
    }

    @objc func save() {
        viewModel.save()
    }

    @objc func cancel() {
        viewModel.cancel()
    }
}
