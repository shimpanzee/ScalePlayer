//
//  PublishedOnMain.swift
//  ScalePlayer
//
//  Created by John Shimmin on 1/5/23.
//  Copyright © 2023 shimmin. All rights reserved.
//

import Combine
import Foundation

@propertyWrapper
class PublishedOnMain<Value> {
    @Published var value: Value

    var wrappedValue: Value {
        get { value }
        set { value = newValue }
    }

    var projectedValue: AnyPublisher<Value, Never> {
        return $value
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }

    init(wrappedValue initialValue: Value) {
        value = initialValue
    }
}
