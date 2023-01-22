//
//  TempoView.swift
//  ScalePlayer
//
//  Created by John Shimmin on 12/15/22.
//  Copyright © 2022 shimmin. All rights reserved.
//

import Combine
import TinyConstraints
import UIKit

class TempoView: UIView {
    private let viewModel: TempoViewModel
    private let slider = UISlider()
    private let tempoLabel = UILabel()
    private let tempoValue = UILabel()
    private let closeButton = UIButton(type: .close)
    private let guide: UILayoutGuide

    private var subscriptions = Set<AnyCancellable>()

    init(viewModel: TempoViewModel, guide: UILayoutGuide) {
        self.viewModel = viewModel
        self.guide = guide

        super.init(frame: .null)

        layer.borderColor = UIColor.red.cgColor
        layer.borderWidth = 1

        backgroundColor = .white
        layer.borderColor = UIColor.black.cgColor
        layer.borderWidth = 1

        let displayRow = UIStackView(arrangedSubviews: [tempoLabel, tempoValue])
        displayRow.spacing = 20

        addSubview(displayRow)
        addSubview(slider)
        addSubview(closeButton)

        size(CGSize(width: 374, height: 95))

        tempoLabel.text = "Tempo:"

        displayRow.centerXToSuperview()
        displayRow.centerYToSuperview(multiplier: 0.67)

        slider.centerXToSuperview()
        slider.centerYToSuperview(multiplier: 1.33)
        slider.widthToSuperview(multiplier: 0.8)

        slider.minimumValue = viewModel.tempoRange.min
        slider.maximumValue = viewModel.tempoRange.max
        slider.addTarget(self, action: #selector(sliderChanged), for: .valueChanged)

        closeButton.addTarget(self, action: #selector(close), for: .touchUpInside)
        closeButton.topToSuperview(offset: 5.0)
        closeButton.rightToSuperview(offset: -5.0)

        viewModel.$tempo
            .sink { [weak self] in
                if let self = self {
                    self.tempoValue.text = String($0)
                    self.slider.value = Float($0)
                }
            }
            .store(in: &subscriptions)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc func sliderChanged() {
        viewModel.updateTempo(Int(slider.value))
    }

    @objc func close() {
        removeFromSuperview()
    }

    override func didMoveToSuperview() {
        if superview != nil {
            center(in: guide)
        }
    }
}
