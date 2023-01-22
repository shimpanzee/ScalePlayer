//
//  RoutinesTableViewController.swift
//  ScalePlayer
//
//  Created by John Shimmin on 12/17/22.
//  Copyright © 2022 shimmin. All rights reserved.
//

import Combine
import Factory
import UIKit

class RoutinesTableViewController: UITableViewController {

    @Injected(Container.viewControllerFactory)
    private var viewControllerFactory: ViewControllerFactory

    private var viewModel: RoutinesTableViewModel
    private var previousVC: UIViewController?
    private var subscriptions = Set<AnyCancellable>()
    private
    let cellIdentifier = "routineCell"

    var routines: [PracticeRoutine] = [] {
        didSet {
            DispatchQueue.main.async { [weak self] in
                self?.tableView.reloadData()
            }
        }
    }

    init(viewModel: RoutinesTableViewModel) {
        self.viewModel = viewModel

        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.register(UITableViewCell.self, forCellReuseIdentifier: cellIdentifier)

        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .add,
            target: self,
            action: #selector(createRoutine))

        viewModel.$routines
            .assign(to: \.routines, onWeak: self)
            .store(in: &subscriptions)

        viewModel.readRoutines()
    }

    @objc
    func createRoutine() {
        viewModel.editRoutine(nil)
    }
}

extension RoutinesTableViewController {
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if routines.count == 0 {
            tableView.setEmptyMessage("No routines")
        } else {
            tableView.restore()
        }
        return routines.count
    }

    override func tableView(_ tableView: UITableView,
                            cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath)

        // Configure the cell...
        cell.textLabel?.text = routines[indexPath.row].name
        cell.accessoryType = .disclosureIndicator

        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        viewModel.editRoutine(routines[indexPath.row])
        tableView.deselectRow(at: indexPath, animated: false)
    }

    override func tableView(
        _ tableView: UITableView,
        commit editingStyle: UITableViewCell.EditingStyle,
        forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let routine = routines.remove(at: indexPath.row)
            self.tableView.deleteRows(at: [indexPath], with: .automatic)
            viewModel.delete(routine: routine)
        }
    }
}
