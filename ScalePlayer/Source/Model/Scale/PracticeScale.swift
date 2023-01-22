//
//  Scale.swift
//  ScalePlayer
//
//  Created by John Shimmin on 12/1/22.
//  Copyright © 2022 shimmin. All rights reserved.
//

import CoreData
import Foundation
import OSLog

public class PracticeScale: NSManagedObject {
    var notes: [ScaleNote] {
        get {
            if let jsonString = value(forKey: "scaleJson") as? String {
                let jsonDecoder = JSONDecoder()
                return (try? jsonDecoder
                    .decode([ScaleNote].self, from: jsonString.data(using: .utf8)!)) ?? []
            } else {
                return []
            }
        }
        set {
            let notes = newValue.sorted { $0.position.beats() < $1.position.beats() }

            let jsonEncoder = JSONEncoder()
            guard let jsonData = try? jsonEncoder.encode(notes)
            else {
                Logger.app.critical("Failed to encode notes")
                return
            }
            let jsonString = String(data: jsonData, encoding: String.Encoding.utf8)
            setValue(jsonString, forKey: "scaleJson")
        }
    }
}
