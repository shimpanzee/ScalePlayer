//
//  CoreDataContext.swift
//  ScalePlayer
//
//  Created by John Shimmin on 12/10/22.
//  Copyright © 2022 shimmin. All rights reserved.
//

import CoreData
import Factory
import Foundation

protocol CoreDataContext {
    func save()
    func create<T: NSManagedObject>() -> T
    func insert(_ obj: NSManagedObject)
    func delete(_ obj: NSManagedObject)
    func fetch<T>(_ request: NSFetchRequest<T>) throws -> [T]
    func count<T>(for request: NSFetchRequest<T>) throws -> Int
}

class CoreDataContextImpl: CoreDataContext {
    private(set) var persistentContainer: NSPersistentContainer

    init() {
        persistentContainer = NSPersistentContainer(name: "ScalesModel")
        persistentContainer.loadPersistentStores(completionHandler: { _, error in
            if let error = error as NSError? {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You
                // should not use this function in a shipping application, although it may be useful
                // during development.

                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
    }

    func create<T: NSManagedObject>() -> T {
        T(context: persistentContainer.viewContext)
    }

    func fetch<T>(_ request: NSFetchRequest<T>) throws -> [T] {
        return try persistentContainer.viewContext.fetch(request)
    }

    func count<T>(for request: NSFetchRequest<T>) throws -> Int {
        return try persistentContainer.viewContext.count(for: request)
    }

    func delete(_ obj: NSManagedObject) {
        persistentContainer.viewContext.delete(obj)
        save()
    }

    func save() {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                Container.errorHandler().report(error, userMessage: "Failed to save data")

                let nserror = error as NSError
                fatalError("Failed to save data: \(nserror), \(nserror.userInfo)")
            }
        }
    }

    func insert(_ obj: NSManagedObject) {
        persistentContainer.viewContext.insert(obj)
    }
}
