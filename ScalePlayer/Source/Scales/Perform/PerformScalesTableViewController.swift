//
//  PerformScalesTableViewController.swift
//  ScalePlayer
//
//  Created by John Shimmin on 12/2/22.
//  Copyright © 2022 shimmin. All rights reserved.
//

import Combine
import Factory
import UIKit

class PerformScalesTableViewController: UITableViewController {
    var scales: [PracticeScale] = [] {
        didSet {
            DispatchQueue.main.async { [weak self] in
                self?.tableView.reloadData()
            }
        }
    }

    @Injected(Container.viewControllerFactory)
    private var viewControllerFactory: ViewControllerFactory

    private var viewModel: ScalesTableViewModel
    private var previousVC: UIViewController?
    private var subscriptions = Set<AnyCancellable>()
    private let CELL_IDENTIFIER = "scaleCell"

    init(viewModel: ScalesTableViewModel) {
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

        viewModel.$scales
            .assign(to: \.scales, onWeak: self)
            .store(in: &subscriptions)

        viewModel.readScales()
    }
}

extension PerformScalesTableViewController {
    // MARK: - Table view data source

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if scales.count == 0 {
            tableView.setEmptyMessage("No scales")
        } else {
            tableView.restore()
        }
        return scales.count
    }

    override func tableView(_ tableView: UITableView,
                            cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: CELL_IDENTIFIER, for: indexPath)

        // Configure the cell...
        cell.textLabel?.text = scales[indexPath.row].name
        cell.accessoryType = .disclosureIndicator

        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        viewModel.performScale(scales[indexPath.row])
        tableView.deselectRow(at: indexPath, animated: false)
    }
}
