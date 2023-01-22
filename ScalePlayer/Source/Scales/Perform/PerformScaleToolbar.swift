//
//  PerformScaleToolbar.swift
//  ScalePlayer
//
//  Created by John Shimmin on 1/12/23.
//  Copyright © 2023 shimmin. All rights reserved.
//

import Combine
import UIKit

class PerformScaleToolbar: UIToolbar {
    private let viewModel: PerformScaleViewModel
    private let playButton = UIButton()
    private let cycleButton = UIButton()
    private let tempoButton = UIButton()
    private let transposeButton = UIButton()
    private let transposeLabel = UILabel()

    private var tempoModalCallback: () -> Void

    private var subscriptions = Set<AnyCancellable>()

    init(viewModel: PerformScaleViewModel, tempoModalCallback: @escaping () -> Void) {
        self.viewModel = viewModel
        self.tempoModalCallback = tempoModalCallback

        super.init(frame: .null)

        configureToolBar()
        configureViewModelSubscribers()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configureTransposeButton() {
        let directionImageName = viewModel
            .octaveChangeDirection > 0 ? "arrow.up.circle" : "arrow.down.circle"
        transposeButton.setImage(UIImage(systemName: directionImageName), for: .normal)

        if viewModel.transposition == 0 {
            transposeLabel.text = ""
        } else {
            let directionSymbol = viewModel.transposition > 0 ? "+" : ""
            transposeLabel.text = "\(directionSymbol)\(viewModel.transposition)"
        }
    }

    func configureViewModelSubscribers() {
        viewModel.$isPlaying
            .sink { [weak self] isPlaying in
                if let self = self {
                    let buttonSystemName = isPlaying ? "pause.circle" : "play.circle"
                    self.playButton.setImage(UIImage(systemName: buttonSystemName), for: .normal)
                }
            }
            .store(in: &subscriptions)

        viewModel.$autoRepeat
            .sink { [weak self] autoRepeat in
                if let self = self {
                    let imageName = autoRepeat ? "repeat.circle.fill" : "repeat.circle"
                    self.cycleButton.setImage(UIImage(named: imageName), for: .normal)
                }
            }
            .store(in: &subscriptions)

        viewModel.$transposition
            .sink { [weak self] _ in self?.configureTransposeButton() }
            .store(in: &subscriptions)

        viewModel.$octaveChangeDirection
            .sink { [weak self] _ in self?.configureTransposeButton() }
            .store(in: &subscriptions)
    }

    func configureToolBar() {
        playButton.addTarget(self, action: #selector(togglePlay), for: .touchUpInside)
        let playItem = UIBarButtonItem(customView: playButton)

        cycleButton.addTarget(self, action: #selector(toggleRepeat), for: .touchUpInside)
        cycleButton.setImage(UIImage(systemName: "repeat"), for: .normal)
        let cycleItem = UIBarButtonItem(customView: cycleButton)

        tempoButton.addTarget(self, action: #selector(showTempoModal), for: .touchUpInside)
        tempoButton.setImage(UIImage(systemName: "clock"), for: .normal)
        let tempoItem = UIBarButtonItem(customView: tempoButton)

        transposeButton.addTarget(
            self,
            action: #selector(toggleTransposeDirection),
            for: .touchUpInside)
        let transposeView = UIStackView()
        transposeView.axis = .horizontal
        transposeView.addArrangedSubview(transposeButton)
        transposeView.addArrangedSubview(transposeLabel)

        let transposeItem = UIBarButtonItem(customView: transposeView)

        let spacer = {
            UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        }
        let items = [
            spacer(),
            playItem,
            spacer(),
            tempoItem,
            spacer(),
            cycleItem,
            spacer(),
            transposeItem,
            spacer()
        ]

        setItems(items, animated: false)
    }

    // MARK: Actions

    @objc func togglePlay() {
        viewModel.togglePlay()
    }

    @objc func toggleRepeat() {
        viewModel.toggleRepeat()
    }

    @objc func toggleTransposeDirection() {
        viewModel.toggleTransposeDirection()
    }

    @objc func showTempoModal() {
        tempoModalCallback()
    }
}
