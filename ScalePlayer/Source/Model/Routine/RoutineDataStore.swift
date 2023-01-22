//
//  RoutineDataStore.swift
//  ScalePlayer
//
//  Created by John Shimmin on 12/1/22.
//  Copyright © 2022 shimmin. All rights reserved.
//

import Foundation

protocol RoutineDataStore {
    func save() throws
    func delete(routine: PracticeRoutine)
    func readRoutines() throws -> [PracticeRoutine]
    func createRoutine() -> PracticeRoutine
    func isDuplicate(name: String, routine: PracticeRoutine?) -> Bool
}
