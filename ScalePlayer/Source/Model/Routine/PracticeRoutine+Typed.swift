//
//  PracticeRoutine+Typed.swift
//  ScalePlayer
//
//  Created by John Shimmin on 1/14/23.
//  Copyright © 2023 shimmin. All rights reserved.
//

import Foundation

// swiftlint:disable force_cast

extension PracticeRoutine {
    func scalesAsArray() -> [RoutineScale] {
        return scales!.array as! [RoutineScale]
    }

    func scale(atIndex: Int) -> RoutineScale {
        return scales![atIndex] as! RoutineScale
    }
}
