//
//  ScaleBuilder.swift
//
//  Builder to help quickly construct midi lines. Used for experiments/testing.
//
//  Created by John Shimmin on 12/27/22.
//  Copyright © 2022 shimmin. All rights reserved.
//

import Foundation

class ScaleBuilder {
    private var currentDuration = ScaleNotePosition(bar: 0, beat: 1, subbeat: 0, cent: 0)
    private var offset: ScaleNotePosition = .zero
    private(set) var notes = [ScaleNote]()

    func rest() -> ScaleBuilder {
        offset = currentDuration + offset
        return self
    }

    func play(_ midiNote: UInt8) -> ScaleBuilder {
        let note = ScaleNote(
            midiNote: midiNote,
            velocity: 60,
            position: offset,
            duration: currentDuration)
        notes.append(note)

        offset = currentDuration + offset

        return self
    }

    func duration(beat: Int, subbeat: Int = 0) -> ScaleBuilder {
        currentDuration = ScaleNotePosition(bar: 0, beat: beat, subbeat: subbeat, cent: 0)
        return self
    }
}
