//
//  RoutineEditViewController.swift
//  ScalePlayer
//
//  Created by John Shimmin on 12/17/22.
//  Copyright © 2022 shimmin. All rights reserved.
//

import Combine
import Factory
import UIKit

class RoutineEditViewController: UIViewController {
    private var viewModel: RoutineEditViewModel

    private let cellIdentifier = "ScaleCell"
    private let nameEditView = NameEditView()
    private let tableView = UITableView()

    @Injected(Container.viewControllerFactory)
    var viewControllerFactory: ViewControllerFactory

    private var subscriptions = Set<AnyCancellable>()

    init(viewModel: RoutineEditViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("Not implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        viewModel.$name
            .sink { [weak self] name in
                self?.navigationItem.rightBarButtonItem?.isEnabled = !name.isEmpty
            }
            .store(in: &subscriptions)

        viewModel.$title
            .assign(to: \.nameEditView.title, onWeak: self)
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

        viewModel.$scales
            .sink { [weak self] _ in self?.tableView.reloadData() }
            .store(in: &subscriptions)

        viewModel.$editSessionComplete
            .filter { $0 }
            .sink { [weak self] _ in self?.dismiss(animated: true) }
            .store(in: &subscriptions)

        view.backgroundColor = .white
        let guide = view.safeAreaLayoutGuide

        let addButton = UIButton(type: .system)
        addButton.setTitle("Add Scale", for: .normal)
        view.addSubview(addButton)
        addButton.addTarget(self, action: #selector(openSearch), for: .touchUpInside)

        addButton.top(to: guide)
        addButton.height(40)

        configureTableView(afterView: addButton)
    }

    @objc func save() {
        viewModel.save()
    }

    @objc func cancel() {
        viewModel.cancel()
    }

    @objc func openSearch() {
        viewModel.openSearch()
    }
}

extension RoutineEditViewController: UITableViewDataSource {
    func configureTableView(afterView: UIView) {
        let guide = view.safeAreaLayoutGuide

        view.addSubview(tableView)

        tableView.dataSource = self

        let tableCell = UINib(nibName: "RoutineScaleTableViewCell", bundle: nil)
        tableView.register(tableCell, forCellReuseIdentifier: cellIdentifier)

        tableView.edges(to: guide, excluding: .top)
        tableView.topToBottom(of: afterView)

        tableView.dragDelegate = self
        tableView.dragInteractionEnabled = true
    }

    func tableView(
        _ tableView: UITableView,
        commit editingStyle: UITableViewCell.EditingStyle,
        forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            viewModel.removeScaleAtIndex(indexPath.row)
        }
    }

    // MARK: - Table view data source

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.scales.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // swiftlint:disable force_cast
        let cell = tableView.dequeueReusableCell(
            withIdentifier: cellIdentifier,
            for: indexPath) as! RoutineScaleTableViewCell
        // swiftlint:enable force_cast

        // Configure the cell...
        let routineScale: RoutineScale = viewModel.scales[indexPath.row]
        cell.configureWith(scale: routineScale)

        return cell
    }
}

extension RoutineEditViewController: UITableViewDragDelegate {
    func tableView(
        _ tableView: UITableView,
        itemsForBeginning session: UIDragSession,
        at indexPath: IndexPath) -> [UIDragItem] {
        let dragItem = UIDragItem(itemProvider: NSItemProvider())
        dragItem.localObject = viewModel.scales[indexPath.row]
        return [dragItem]
    }

    func tableView(
        _ tableView: UITableView,
        moveRowAt sourceIndexPath: IndexPath,
        to destinationIndexPath: IndexPath) {
        viewModel.moveScaleFromIndex(sourceIndexPath.row, to: destinationIndexPath.row)
    }
}
