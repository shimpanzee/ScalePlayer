//
//  NameEditView.swift
//  ScalePlayer
//
//  Created by John Shimmin on 1/9/23.
//  Copyright © 2023 shimmin. All rights reserved.
//

import Combine
import CombineCocoa
import UIKit

class NameEditView: UIStackView {
    var editCallback: (() -> Void)?
    var title: String = "" {
        didSet {
            titleLabel.text = title
        }
    }

    private let titleLabel = UILabel()
    private var subscriptions = Set<AnyCancellable>()

    init() {
        let editButton = UIButton()
        editButton.setImage(UIImage(systemName: "pencil"), for: .normal)

        super.init(frame: .zero)

        spacing = 10

        editButton.tapPublisher
            .sink { [weak self] in self?.editCallback?() }
            .store(in: &subscriptions)

        addArrangedSubview(titleLabel)
        addArrangedSubview(editButton)
    }

    @available(*, unavailable)
    required init(coder: NSCoder) {
        fatalError("init with coder not implemented for NameEditView")
    }
}
