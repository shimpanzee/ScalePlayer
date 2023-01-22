//
//  NSMutableAttributedString+Append.swift
//  ScalePlayer
//
//  Created by John Shimmin on 1/11/23.
//  Copyright © 2023 shimmin. All rights reserved.
//

import Foundation

extension NSMutableAttributedString {
    func append(_ value: String,
                attributes: [NSAttributedString.Key: Any] = [:]) -> NSMutableAttributedString {
        append(NSAttributedString(string: value, attributes: attributes))
        return self
    }
}
