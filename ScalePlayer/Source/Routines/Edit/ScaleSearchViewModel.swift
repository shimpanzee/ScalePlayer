//
//  PerformanceSearchViewModel.swift
//  ScalePlayer
//
//  Created by John Shimmin on 12/21/22.
//  Copyright © 2022 shimmin. All rights reserved.
//

import Combine
import Factory
import OSLog

protocol ScaleSearchViewModelResponder {
    func scalesSelected(scales: [PracticeScale])
}

class ScaleSearchViewModel {

    @PublishedOnMain var searchText: String = ""
    @PublishedOnMain private(set) var scales: [PracticeScale] = []
    @PublishedOnMain private(set) var selectedScales = Set<PracticeScale>()

    @Injected(Container.scaleDataStore)
    private(set) var dataStore: ScaleDataStore

    private(set) var page = 0
    private(set) var responder: ScaleSearchViewModelResponder

    private var subscriptions = Set<AnyCancellable>()

    init(responder: ScaleSearchViewModelResponder) {
        self.responder = responder

        $searchText
            .dropFirst()
            .throttle(for: 0.1, scheduler: DispatchQueue.main, latest: true)
            .sink { [weak self] _ in
                self?.loadPage()
            }
            .store(in: &subscriptions)
    }

    var count: Int {
        return scales.count
    }

    func loadPage() {
        do {
            if searchText.count > 0 {
                scales = try dataStore.fetchScalesBySearchText(searchText)
            } else {
                scales = try dataStore.fetchScales()
            }
        } catch {
            Container.errorHandler().report(error, userMessage: "Failed to load scales")
        }
    }

    func scaleAt(row: Int) -> PracticeScale {
        return scales[row]
    }

    func toggleScaleSelection(_ scale: PracticeScale) {
        if selectedScales.remove(scale) == nil {
            selectedScales.insert(scale)
        }
    }

    func addScales() {
        responder.scalesSelected(scales: Array(selectedScales))
    }
}
