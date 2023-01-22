//
//  ScalesTableViewController.swift
//  ScalePlayer
//
//  Created by John Shimmin on 12/2/22.
//  Copyright © 2022 shimmin. All rights reserved.
//

import Combine
import Factory
import UIKit

class ScalesTableViewController: UITableViewController {
    @Injected(Container.viewControllerFactory)
    private var viewControllerFactory: ViewControllerFactory

    private var viewModel: ScalesTableViewModel
    private var previousVC: UIViewController?
    private var subscriptions = Set<AnyCancellable>()

    private var scales: [PracticeScale] = [] {
        didSet {
            DispatchQueue.main.async { [weak self] in
                self?.tableView.reloadData()
            }
        }
    }

    private let cellIdentifier = "scaleCell"

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

        tableView.register(UITableViewCell.self, forCellReuseIdentifier: cellIdentifier)

        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .add,
            target: self,
            action: #selector(createScale))

        viewModel.$scales
            .assign(to: \.scales, onWeak: self)
            .store(in: &subscriptions)

        viewModel.readScales()
    }

    @objc
    func createScale() {
        viewModel.editScale(nil)
    }
}

extension ScalesTableViewController {
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

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
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath)

        // Configure the cell...
        cell.textLabel?.text = scales[indexPath.row].name
        cell.accessoryType = .disclosureIndicator

        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        viewModel.editScale(scales[indexPath.row])
        tableView.deselectRow(at: indexPath, animated: false)
    }

    override func tableView(
        _ tableView: UITableView,
        commit editingStyle: UITableViewCell.EditingStyle,
        forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let scale = scales.remove(at: indexPath.row)
            self.tableView.deleteRows(at: [indexPath], with: .automatic)
            viewModel.delete(scale: scale)
        }
    }
}
