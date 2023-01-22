//
//  WeakObjectSet.swift
//  ScalePlayer
//
//  Created by John Shimmin on 12/28/22.
//  Copyright © 2022 shimmin. All rights reserved.
//

import Foundation
import OSLog

class WeakObject<T: AnyObject>: Equatable, Hashable {
    weak var object: T?
    init(object: T) {
        self.object = object
    }

    func hash(into hasher: inout Hasher) {
        if var object = object {
            withUnsafeMutablePointer(to: &object) { hasher.combine($0) }
        } else {
            hasher.combine(0)
        }
    }

    static func == (lhs: WeakObject<T>, rhs: WeakObject<T>) -> Bool {
        return lhs.object === rhs.object
    }
}

class WeakObjectSet<T: AnyObject> {
    private var objects: Set<WeakObject<T>>

    init() {
        objects = Set<WeakObject<T>>([])
    }

    init(objects: [T]) {
        self.objects = Set<WeakObject<T>>(objects.map { WeakObject(object: $0) })
    }

    var allObjects: [T] {
        return objects.compactMap { $0.object }
    }

    func remove(_ object: T) {
        objects.remove(WeakObject(object: object))
    }

    func contains(_ object: T) -> Bool {
        return objects.contains(WeakObject(object: object))
    }

    func addObject(_ object: T) {
        objects.formUnion([WeakObject(object: object)])
    }

    func addObjects(_ objects: [T]) {
        self.objects.formUnion(objects.map { WeakObject(object: $0) })
    }
}
