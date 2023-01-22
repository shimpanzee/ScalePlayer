//
//  ScalesTableViewModel.swift
//  ScalePlayer
//
//  Created by John Shimmin on 12/10/22.
//  Copyright © 2022 shimmin. All rights reserved.
//

import Factory
import Foundation

class ScalesTableViewModel {
    @PublishedOnMain
    private(set) var scales: [PracticeScale] = []

    @Injected(Container.scaleDataStore) private var scaleDataStore: ScaleDataStore

    private weak var coordinator: ScalesTableCoordinator?

    init(coordinator: ScalesTableCoordinator) {
        self.coordinator = coordinator
    }

    func delete(scale: PracticeScale) {
        scaleDataStore.delete(scale: scale)
    }

    func readScales() {
        if let scales = try? scaleDataStore.fetchScales() {
            self.scales = scales
        }
    }

    func performScale(_ scale: PracticeScale) {
        if let coordinator = coordinator {
            coordinator.showScalePerform(for: scale)
        }
    }

    func editScale(_ scale: PracticeScale?) {
        if let coordinator = coordinator {
            coordinator.showScaleEdit(for: scale, responder: self)
        }
    }
}

extension ScalesTableViewModel: ScaleEditResponder {
    func editComplete(scale: PracticeScale) {
        if let idx = scales.firstIndex(of: scale) {
            scales[idx] = scale
        } else {
            readScales()
        }
    }
}
