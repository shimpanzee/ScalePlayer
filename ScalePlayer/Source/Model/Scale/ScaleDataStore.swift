//
//  ScaleDataStore.swift
//  ScalePlayer
//
//  Created by John Shimmin on 12/1/22.
//  Copyright © 2022 shimmin. All rights reserved.
//

import Foundation

protocol ScaleDataStore {
    func save(scale: PracticeScale) throws
    func delete(scale: PracticeScale)
    func fetchScales() throws -> [PracticeScale]
    func fetchScalesBySearchText(_ text: String) throws -> [PracticeScale]
    func isDuplicate(name: String, scale: PracticeScale?) -> Bool
}
