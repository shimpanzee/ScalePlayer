//
//  ScaleEditRowView.swift
//  ScalePlayer
//
//  Copyright © 2022 shimmin. All rights reserved.
//

import MusicTheorySwift
import UIKit

/// Represents a MIDI note row of the `ScalePlayer`.
class ScaleEditRowView: UIView {
    /// Pitch of the row.
    var pitch: Pitch
    /// Label of the pitch.
    let pitchLabel = UILabel()
    /// Line at the bottom.
    let bottomLine = CALayer()

    // MARK: Init

    /// Initilizes the row with an assigned MIDI pitch.
    ///
    /// - Parameter pitch: MIDI pitch of the row.
    init(pitch: Pitch) {
        self.pitch = pitch
        super.init(frame: .zero)
        commonInit()
    }

    /// Initilizes the row from a coder with 0 pitch value.
    ///
    /// - Parameter aDecoder: Decoder.
    required init?(coder aDecoder: NSCoder) {
        pitch = Pitch(midiNote: 0)
        super.init(coder: aDecoder)
        commonInit()
    }

    /// Sets up the row after initilization.
    private func commonInit() {
        // Setup pitch label
        pitchLabel.textAlignment = .center
        addSubview(pitchLabel)
        pitchLabel.text = "\(pitch)"
        // Setup bottom line
        layer.addSublayer(bottomLine)
        bottomLine.backgroundColor = UIColor.black.cgColor
        // Setup default coloring
        backgroundColor = pitch.key.accidental == .natural ? UIColor.white : UIColor.black
        pitchLabel.textColor = pitch.key.accidental == .natural ? UIColor.black : UIColor.white
    }

    // MARK: Lifecycle

    override func layoutSubviews() {
        super.layoutSubviews()
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        pitchLabel.frame = bounds
        bottomLine.frame = CGRect(x: 0, y: frame.size.height, width: frame.size.width, height: 0.5)
        CATransaction.commit()
    }
}
