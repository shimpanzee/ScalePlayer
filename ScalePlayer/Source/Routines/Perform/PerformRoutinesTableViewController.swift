//
//  PerformRoutinesTableViewController.swift
//  ScalePlayer
//
//  Created by John Shimmin on 12/2/22.
//  Copyright © 2022 shimmin. All rights reserved.
//

import Combine
import Factory
import UIKit

class PerformRoutinesTableViewController: UITableViewController {
    private var viewModel: RoutinesTableViewModel
    private var previousVC: UIViewController?
    private let CELL_IDENTIFIER = "routineCell"

    @Injected(Container.viewControllerFactory)
    var viewControllerFactory: ViewControllerFactory

    private var subscriptions = Set<AnyCancellable>()

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

        tableView.register(UITableViewCell.self, forCellReuseIdentifier: CELL_IDENTIFIER)

        viewModel.$routines
            .assign(to: \.routines, onWeak: self)
            .store(in: &subscriptions)

        viewModel.readRoutines()
    }
}

extension PerformRoutinesTableViewController {
    // MARK: - Table view data source

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
        let cell = tableView.dequeueReusableCell(withIdentifier: CELL_IDENTIFIER, for: indexPath)

        // Configure the cell...
        cell.textLabel?.text = routines[indexPath.row].name
        cell.accessoryType = .disclosureIndicator

        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        viewModel.performRoutine(routines[indexPath.row])
        tableView.deselectRow(at: indexPath, animated: false)
    }
}
