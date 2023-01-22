//
//  ScaleEditMeasureLineLayer.swift
//  ScalePlayer
//
//  Copyright © 2022 shimmin. All rights reserved.
//

import MusicTheorySwift
import UIKit

/// Vertical line layer with measure beat text for each beat of the measure on the `ScalePlayer`.
class ScaleEditMeasureLineLayer: CALayer {
    /// Text on measure.
    let textLayer = CATextLayer()
    /// Line on measure.
    let lineLayer = CAShapeLayer()
    /// Position on scale edit grid.
    var linePosition: ScaleNotePosition = .zero

    /// Property for controlling beat text rendering.
    var showsBeatText: Bool = true {
        didSet {
            textLayer.isHidden = !showsBeatText
        }
    }

    /// Initilizes the line with the default zero values.
    override init() {
        super.init()
        commonInit()
    }

    /// Initilizes with a layer.
    ///
    /// - Parameter layer: Layer.
    override init(layer: Any) {
        super.init(layer: layer)
        commonInit()
    }

    /// Initilizes with a coder.
    ///
    /// - Parameter aDecoder: Coder.
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }

    /// Default initilizer.
    private func commonInit() {
        textLayer.contentsScale = UIScreen.main.scale
        addSublayer(lineLayer)
        addSublayer(textLayer)
    }
}
