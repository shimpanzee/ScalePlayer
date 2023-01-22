//
//  RoutinesTableViewModel.swift
//  ScalePlayer
//
//  Created by John Shimmin on 12/10/22.
//  Copyright © 2022 shimmin. All rights reserved.
//

import Factory
import Foundation
import UIKit

class RoutinesTableViewModel {
    @PublishedOnMain
    var routines: [PracticeRoutine] = []

    @Injected(Container.routineDataStore)
    private var routineDataStore: RoutineDataStore

    private weak var coordinator: RoutineTableCoordinator?

    init(coordinator: RoutineTableCoordinator) {
        self.coordinator = coordinator
    }

    func delete(routine: PracticeRoutine) {
        routineDataStore.delete(routine: routine)
    }

    func readRoutines() {
        if let routines = try? routineDataStore.readRoutines() {
            self.routines = routines
        }
    }

    func editRoutine(_ routine: PracticeRoutine?) {
        if let coordinator = coordinator {
            coordinator.showRoutineEdit(for: routine, responder: self)
        }
    }

    func performRoutine(_ routine: PracticeRoutine) {
        if let coordinator = coordinator {
            coordinator.showRoutinePerform(for: routine)
        }
    }
}

extension RoutinesTableViewModel: RoutineEditResponder {

    func editCompleted(routine: PracticeRoutine) {
        if let idx = routines.firstIndex(of: routine) {
            routines[idx] = routine
        } else {
            readRoutines()
        }
    }
}
