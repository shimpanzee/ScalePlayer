//
//  Logger+ScaleEdit.swift
//  ScalePlayer
//
//  Created by John Shimmin on 1/8/23.
//  Copyright © 2023 shimmin. All rights reserved.
//

import Foundation
import OSLog

extension Logger {
    private static var subsystem = Bundle.main.bundleIdentifier!

    /// Logs the view cycles like viewDidLoad.
    static let audio = Logger(subsystem: subsystem, category: "audio")
    static let app = Logger(subsystem: subsystem, category: "app")
    static let gestures = Logger(subsystem: subsystem, category: "gestures")
    static let persistence = Logger(subsystem: subsystem, category: "persistence")
}
