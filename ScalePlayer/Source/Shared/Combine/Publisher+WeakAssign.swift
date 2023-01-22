//
//  Publisher+WeakAssign.swift
//  ScalePlayer
//
//  Created by John Shimmin on 1/5/23.
//  Copyright © 2023 shimmin. All rights reserved.
//

import Combine

extension Publisher where Self.Failure == Never {
    func assign<Root>(to keyPath: ReferenceWritableKeyPath<Root, Self.Output>,
                      onWeak object: Root) -> AnyCancellable where Root: AnyObject {
        sink { [weak object] value in
            object?[keyPath: keyPath] = value
        }
    }
}
