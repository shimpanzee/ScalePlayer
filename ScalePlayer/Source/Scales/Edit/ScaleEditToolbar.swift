//
//  ScaleEditToolbar.swift
//  ScalePlayer
//
//  Created by John Shimmin on 1/12/23.
//  Copyright © 2023 shimmin. All rights reserved.
//

import Combine
import OSLog
import TinyConstraints
import UIKit

class ScaleEditToolbar: UIToolbar {
    private var viewModel: ScaleEditViewModel

    private let playButton = UIButton(frame: CGRect(x: 0, y: 0, width: 35, height: 35))
    private let toolMenuButtonItem = UIBarButtonItem()
    private var subscriptions = Set<AnyCancellable>()
    private var tempoModalCallback: () -> Void

    init(viewModel: ScaleEditViewModel, tempoModalCallback: @escaping () -> Void) {
        self.viewModel = viewModel
        self.tempoModalCallback = tempoModalCallback

        super.init(frame: .null)

        configureSubscriptions()
        configureToolMenu()
        configureToolbar()
    }

    private func configureToolbar() {
        playButton.addTarget(self, action: #selector(togglePlay), for: .touchUpInside)
        let playItem = UIBarButtonItem(customView: playButton)

        let clearButton = UIButton(frame: CGRect(x: 0, y: 0, width: 35, height: 35))
        clearButton.addTarget(
            viewModel,
            action: #selector(ScaleEditViewModel.clearSequence),
            for: .touchUpInside)
        clearButton.setImage(UIImage(systemName: "trash"), for: .normal)
        let clearItem = UIBarButtonItem(customView: clearButton)

        let tempoButton = UIButton(frame: CGRect(x: 0, y: 0, width: 35, height: 35))
        tempoButton.addTarget(self, action: #selector(showTempoModal), for: .touchUpInside)
        tempoButton.setImage(UIImage(systemName: "clock"), for: .normal)
        let tempoItem = UIBarButtonItem(customView: tempoButton)

        let items = [
            UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil),
            playItem,
            UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil),
            toolMenuButtonItem,
            UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil),
            tempoItem,
            UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil),
            clearItem,
            UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        ]

        setItems(items, animated: false)
    }

    private func configureSubscriptions() {
        viewModel.$isPlaying
            .sink { [weak self] isPlaying in
                let buttonSystemName = isPlaying ? "pause.circle" : "play.circle"
                self?.playButton.setImage(UIImage(systemName: buttonSystemName), for: .normal)
            }
            .store(in: &subscriptions)

        viewModel.$tool
            .sink { [weak self] tool in
                self?.toolMenuButtonItem.image = UIImage(systemName: tool.rawValue)
            }
            .store(in: &subscriptions)
    }

    private func configureToolMenu() {
        let handler: (_ action: UIAction) -> Void = { [weak self] action in
            guard let tool = MidiToolType(rawValue: action.identifier.rawValue)
            else {
                Logger.app.error("Tool not found: \(action.identifier.rawValue)")
                return
            }
            self?.viewModel.updateTool(tool)
        }

        let paintAction = UIAction(
            title: "Paint",
            image: UIImage(systemName: MidiToolType.paintbrush.rawValue),
            identifier: .init(MidiToolType.paintbrush.rawValue),
            handler: handler)
        let eraseAction = UIAction(
            title: "Eraser",
            image: UIImage(systemName: MidiToolType.eraser.rawValue),
            identifier: .init(MidiToolType.eraser.rawValue),
            handler: handler)

        let actions = [
            paintAction,
            eraseAction
        ]

        // Initiale UIMenu with the above array of actions.
        let menu = UIMenu(title: "menu", children: actions)

        // Create UIBarButtonItem with the initiated UIMenu and add it to the navigationItem.
        toolMenuButtonItem.menu = menu
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Actions

    @objc
    func showTempoModal() {
        tempoModalCallback()
    }

    @objc
    func togglePlay() {
        viewModel.togglePlay()
    }
}
