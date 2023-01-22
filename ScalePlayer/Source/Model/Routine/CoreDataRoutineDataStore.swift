//
//  CoreDataRoutnineDataStore.swift
//  ScalePlayer
//
//  Created by John Shimmin on 12/6/22.
//  Copyright © 2022 shimmin. All rights reserved.
//

import CoreData
import Factory
import Foundation
import OSLog

class CoreDataRoutineDataStore: RoutineDataStore {
    @Injected(Container.coreDataContext) private var coreDataContext: CoreDataContext

    init() {}

    func save() throws {
        coreDataContext.save()
    }

    func delete(routine: PracticeRoutine) {
        coreDataContext.delete(routine)
    }

    func readRoutines() throws -> [PracticeRoutine] {
        let fetchRequest =
            NSFetchRequest<PracticeRoutine>(entityName: "PracticeRoutine")

        fetchRequest.propertiesToFetch = ["name"]

        do {
            return try coreDataContext.fetch(fetchRequest)
        } catch let error as NSError {
            Container.errorHandler()
                .report(error, userMessage: "Could not fetch routines", level: .fault)
            fatalError("Could not fetch routines: \(error), \(error.userInfo)")
        }
    }

    func createRoutine() -> PracticeRoutine {
        return coreDataContext.create()
    }

    func isDuplicate(name: String, routine: PracticeRoutine?) -> Bool {
        if let routine = routine, name == routine.name {
            return false
        }

        let fetchRequest =
            NSFetchRequest<PracticeRoutine>(entityName: "PracticeRoutine")

        if let routine = routine {
            fetchRequest.predicate = NSPredicate(
                format: "name = '\(name)' and not self == %@",
                routine)
        } else {
            fetchRequest.predicate = NSPredicate(format: "name = '\(name)'")
        }

        do {
            let count = try coreDataContext.count(for: fetchRequest)
            return count > 0
        } catch let error as NSError {
            fatalError("Could not fetch. \(error), \(error.userInfo)")
        }
    }
}
