//
//  CoreDataScaleDataStore.swift
//  ScalePlayer
//
//  Created by John Shimmin on 12/6/22.
//  Copyright © 2022 shimmin. All rights reserved.
//

import CoreData
import Factory
import Foundation
import OSLog

class CoreDataScaleDataStore: ScaleDataStore {
    @Injected(Container.coreDataContext) private var coreDataContext: CoreDataContext

    func save(scale: PracticeScale) throws {
        coreDataContext.save()
    }

    func delete(scale: PracticeScale) {
        coreDataContext.delete(scale)
    }

    func fetchScales() throws -> [PracticeScale] {
        let fetchRequest =
            NSFetchRequest<PracticeScale>(entityName: "PracticeScale")

        fetchRequest.propertiesToFetch = ["name"]

        do {
            let scales = try coreDataContext.fetch(fetchRequest)
            return scales
        } catch let error as NSError {
            Logger.persistence.critical("Could not fetch. \(error), \(error.userInfo)")
            return []
        }
    }

    func fetchScalesBySearchText(_ text: String) throws -> [PracticeScale] {
        let fetchRequest =
            NSFetchRequest<PracticeScale>(entityName: "PracticeScale")

        fetchRequest.predicate = NSPredicate(format: "name contains[cd] '\(text)'")
        fetchRequest.propertiesToFetch = ["name"]

        do {
            let scales = try coreDataContext.fetch(fetchRequest)
            return scales
        } catch let error as NSError {
            Container.errorHandler().report(error, userMessage: "Could not fetch scales")
            fatalError("Could not fetch. \(error), \(error.userInfo)")
        }
    }

    func isDuplicate(name: String, scale: PracticeScale?) -> Bool {
        if name == scale?.name {
            return false
        }

        let fetchRequest =
            NSFetchRequest<PracticeScale>(entityName: "PracticeScale")

        if let scale = scale {
            fetchRequest.predicate = NSPredicate(
                format: "name = '\(name)' and not self == %@",
                scale)
        } else {
            fetchRequest.predicate = NSPredicate(format: "name = '\(name)'")
        }

        do {
            let count = try coreDataContext.count(for: fetchRequest)
            return count > 0
        } catch let error as NSError {
            Container.errorHandler().report(error, userMessage: "Could not fetch scales")
            fatalError("Could not fetch scales: \(error), \(error.userInfo)")
        }
    }
}
