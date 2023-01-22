//
//  ScaleNoteNote.swift
//  ScalePlayer
//
//  Copyright © 2022 shimmin. All rights reserved.
//

import Foundation
import MusicTheorySwift

/// Data structure that represents a MIDI note in the scale grid.
struct ScaleNote: Equatable, Codable, Hashable {
    /// MIDI note number.
    var midiNote: UInt8
    /// MIDI velocity.
    var velocity: UInt8
    /// Starting beat position on the grid.
    var position: ScaleNotePosition
    /// Duration of the note in beats.
    var duration: ScaleNotePosition

    /// Initilizes the data structure.
    ///
    /// - Parameters:
    ///   - midiNote: MIDI note number.
    ///   - velocity: MIDI velocity.
    ///   - position: Starting beat position of the note.
    ///   - duration: Duration of the note in beats
    init(midiNote: UInt8,
         velocity: UInt8,
         position: ScaleNotePosition,
         duration: ScaleNotePosition) {
        self.midiNote = midiNote
        self.velocity = velocity
        self.position = position
        self.duration = duration
    }

    func endPositionInBeats() -> Float32 {
        let endPosition = position + duration
        return endPosition.beats()
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(midiNote)
        hasher.combine(velocity)
        hasher.combine(position)
        hasher.combine(duration)
    }
}
