//
//  ScaleSearchViewController.swift
//  ScalePlayer
//
//  Created by John Shimmin on 12/21/22.
//  Copyright © 2022 shimmin. All rights reserved.
//

import Combine
import TinyConstraints
import UIKit

class ScaleSearchViewController: UIViewController, UITableViewDataSource, UITableViewDelegate,
    UISearchBarDelegate {
    private var viewModel: ScaleSearchViewModel
    private var guide: UILayoutGuide { view.safeAreaLayoutGuide }

    private let searchBar = UISearchBar()
    private let tableView = UITableView()

    private var subscriptions = Set<AnyCancellable>()

    init(viewModel: ScaleSearchViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) not implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .systemBackground

        viewModel.loadPage()

        configureSubscriptions()
        configureSearchBar()
        configureTableView()
        configureButtons()
    }

    func configureTableView() {
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "perfCell")
        view.addSubview(tableView)

        tableView.edges(to: guide, excluding: [.top, .bottom])
        tableView.bottom(to: guide, offset: -50)
        tableView.topToBottom(of: searchBar)
    }

    func configureSearchBar() {
        searchBar.searchTextField.autocapitalizationType = .none
        searchBar.delegate = self
        view.addSubview(searchBar)

        searchBar.edges(to: guide, excluding: [.bottom, .top])
        searchBar.top(to: guide, offset: 5)
        searchBar.height(40)
    }

    func configureButtons() {
        let cancelButton = UIButton(type: .system)
        cancelButton.addTarget(self, action: #selector(cancel), for: .touchUpInside)
        cancelButton.role = .cancel
        cancelButton.setTitle("Cancel", for: .normal)
        view.addSubview(cancelButton)

        cancelButton.trailing(to: guide, offset: -10)
        cancelButton.topToBottom(of: tableView, offset: 5)
        cancelButton.bottom(to: guide, offset: -10)

        let addButton = UIButton(type: .system)
        addButton.addTarget(self, action: #selector(addScales), for: .touchUpInside)
        addButton.role = .primary
        addButton.setTitle("Add", for: .normal)
        view.addSubview(addButton)

        addButton.trailing(to: cancelButton, cancelButton.leadingAnchor, offset: -10)
        addButton.centerY(to: cancelButton)
    }

    func configureSubscriptions() {
        viewModel.$scales
            .sink { [weak self] _ in
                self?.tableView.reloadData()
            }
            .store(in: &subscriptions)

        viewModel.$selectedScales
            .sink { [weak self] _ in
                self?.tableView.reloadData()
            }
            .store(in: &subscriptions)
    }

    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        viewModel.searchText = searchText
    }

    // MARK: - Button actions

    @objc func addScales() {
        dismiss(animated: true)
        viewModel.addScales()
    }

    @objc func cancel() {
        dismiss(animated: true)
    }

    // MARK: - Table view data source

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "perfCell", for: indexPath)

        let scale = viewModel.scaleAt(row: indexPath.row)
        cell.textLabel?.text = scale.name
        cell.accessoryType = viewModel.selectedScales.contains(scale) ? .checkmark : .none

        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let scale = viewModel.scaleAt(row: indexPath.row)
        viewModel.toggleScaleSelection(scale)
    }
}
