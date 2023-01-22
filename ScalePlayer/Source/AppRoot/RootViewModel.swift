//
//  RootViewModel.swift
//  ScalePlayer
//
//  Created by John Shimmin on 12/17/22.
//  Copyright © 2022 shimmin. All rights reserved.
//

import Combine
import Factory
import UIKit

class RootViewModel {
    @PublishedOnMain
    var selectedSegmentIndex = 0

    func makeSegmentedControl() -> UISegmentedControl {
        let segmentedControl = UISegmentedControl(items: ["Scales", "Routines"])

        // Add function to handle Value Changed events
        segmentedControl.addTarget(
            self,
            action: #selector(segmentedValueChanged(_:)),
            for: .valueChanged)

        segmentedControl.selectedSegmentIndex = selectedSegmentIndex

        return segmentedControl
    }

    @objc func segmentedValueChanged(_ segmentedControl: UISegmentedControl!) {
        selectedSegmentIndex = segmentedControl.selectedSegmentIndex
    }
}
