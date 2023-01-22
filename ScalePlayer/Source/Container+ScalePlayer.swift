//
//  ScalePlayer+Injection.swift
//
//  Registry for dependency injection components
//
//  Created by John Shimmin on 12/21/22.
//  Copyright © 2022 shimmin. All rights reserved.
//

import Factory
import UIKit

extension Container {
    static let rootViewModel = Factory<RootViewModel>(scope: .singleton) {
        RootViewModel()
    }
}

extension Container {
    static let coreDataContext = Factory<CoreDataContext>(scope: .singleton) {
        CoreDataContextImpl()
    }

    static let scaleDataStore = Factory<ScaleDataStore>(scope: .singleton) {
        CoreDataScaleDataStore()
    }

    static let routineDataStore = Factory<RoutineDataStore>(scope: .singleton) {
        CoreDataRoutineDataStore()
    }
}

extension Container {
    static let practiceRoutine = Factory<PracticeRoutine> { coreDataContext().create() }
    static let practiceScale = Factory<PracticeScale> { coreDataContext().create() }
    static let routineScale = Factory<RoutineScale> { coreDataContext().create() }
}

extension Container {
    static let viewControllerFactory = Factory<ViewControllerFactory>(scope: .singleton) {
        ViewControllerFactory()
    }
}

extension Container {
    static let errorHandler = Factory<ErrorHandler>(scope: .singleton) { LoggingErrorHandler() }
}

// swiftlint:disable large_tuple
extension Container {
    static var tempoView = ParameterFactory<
        (tempo: Int, guide: UILayoutGuide, delegate: TempoViewModelDelegate),
        TempoView
    > { tempo, guide, delegate in
        let tempoViewModel = TempoViewModel(tempo: tempo)
        let tempoView = TempoView(viewModel: tempoViewModel, guide: guide)
        tempoViewModel.delegate = delegate

        return tempoView
    }
}

extension Container {
    static let midiPlayer = Factory<MidiPlayer>(scope: .singleton) { MidiPlayer() }
}
