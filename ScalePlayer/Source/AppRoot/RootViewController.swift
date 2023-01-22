//
//  RootViewController.swift
//  ScalePlayer
//
//  Created by John Shimmin on 12/15/22.
//  Copyright © 2022 shimmin. All rights reserved.
//

import Factory
import TinyConstraints
import UIKit

class RootViewController: UITabBarController {
    var segmentedControl: UISegmentedControl

    init(segmentedControl: UISegmentedControl) {
        self.segmentedControl = segmentedControl

        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.addSubview(segmentedControl)

        segmentedControl.centerXToSuperview()
        segmentedControl.widthToSuperview(multiplier: 0.90)
        segmentedControl.bottomToTop(of: tabBar, offset: -10)
    }

}
