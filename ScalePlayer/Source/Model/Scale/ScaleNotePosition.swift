//
//  ScaleNotePosition.swift
//  ScalePlayer
//
//  Copyright © 2022 shimmin. All rights reserved.
//

import Foundation
import MusicTheorySwift

// MARK: - Equatable

/// Adds two `ScaleNotePosition`s together.
///
/// - Parameters:
///   - lhs: Left hand side of the equation.
///   - rhs: Right hand side of the equation.
/// - Returns: Returns the new position.
func + (lhs: ScaleNotePosition, rhs: ScaleNotePosition) -> ScaleNotePosition {
    // Calculate cent
    var newCent = lhs.cent + rhs.cent
    let subbeatCarry = newCent / 240
    newCent -= subbeatCarry * 240
    // Calculate subbeat
    var newSubbeat = lhs.subbeat + rhs.subbeat + subbeatCarry
    let beatCarry = newSubbeat / 4
    newSubbeat -= beatCarry * 4
    // Calculate beat
    var newBeat = lhs.beat + rhs.beat + beatCarry
    let barCarry = newBeat / 4
    newBeat -= barCarry * 4
    // Calculate bar
    let newBar = lhs.bar + rhs.bar + barCarry
    // Return new position
    return ScaleNotePosition(bar: newBar, beat: newBeat, subbeat: newSubbeat, cent: newCent)
}

/// Substracts the right hand side position from left hand side position.
///
/// - Parameters:
///   - lhs: Position to be substracted.
///   - rhs: Substraction amount.
/// - Returns: Returns the new position.
func - (lhs: ScaleNotePosition, rhs: ScaleNotePosition) -> ScaleNotePosition {
    // Calculate cent
    var newCent = lhs.cent - rhs.cent
    var subbeatCarry = 0
    if newCent < 0 {
        subbeatCarry = 1
        subbeatCarry += -newCent / 240
        newCent = 240 + (newCent * subbeatCarry)
    }

    // Calculate subbeat
    var newSubbeat = lhs.subbeat - rhs.subbeat - subbeatCarry
    var beatCarry = 0
    if newSubbeat < 0 {
        beatCarry = 1
        beatCarry += -newSubbeat / 4
        newSubbeat = 4 + (newSubbeat * beatCarry)
    }

    // Calculate beat
    var newBeat = lhs.beat - rhs.beat - beatCarry
    var barCarry = 0
    if newBeat < 0 {
        barCarry = 1
        barCarry += -newBeat / 4
        newBeat = 4 + (newBeat * barCarry)
    }

    // Calculate bar
    let newBar = lhs.bar - rhs.bar - barCarry
    if newBar < 0 {
        return .zero
    } else {
        return ScaleNotePosition(bar: newBar, beat: newBeat, subbeat: newSubbeat, cent: newCent)
    }
}

// MARK: - Comparable

/// Compares if left hand side position is less than right hand side position.
///
/// - Parameters:
///   - lhs: Left hand side of the equation.
///   - rhs: Right hand side of the equation.
/// - Returns: Returns true if left hand side position is less than right hand side position.
func < (lhs: ScaleNotePosition, rhs: ScaleNotePosition) -> Bool {
    if lhs.bar < rhs.bar {
        return true
    } else if lhs.bar == rhs.bar {
        if lhs.beat < rhs.beat {
            return true
        } else if lhs.beat == rhs.beat {
            if lhs.subbeat < rhs.subbeat {
                return true
            } else if lhs.subbeat == rhs.subbeat {
                if lhs.cent < rhs.cent {
                    return true
                }
            }
        }
    }
    return false
}

// MARK: - ScaleNotePosition

/// Represents the position on the scale edit grid by bar, beat, subbeat and cent values.
struct ScaleNotePosition: Equatable, Comparable, Codable, CustomStringConvertible, Hashable {
    /// Bar number.
    let bar: Int
    /// Beat number of a bar, between 0 and 4.
    let beat: Int
    /// Subbeat number of a beat, between 0 and 4.
    let subbeat: Int
    /// Cent value of a subbeat, between 0 and 240
    let cent: Int

    /// Zero position.
    static let zero = ScaleNotePosition(bar: 0, beat: 0, subbeat: 0, cent: 0)

    /// Returns true if beat, subbeat and cent is zero. The position is on the begining of a bar.
    var isBarPosition: Bool {
        return beat == 0 && subbeat == 0 && cent == 0
    }

    /// Initilizes the position.
    ///
    /// - Parameters:
    ///   - bar: Bar number≥
    ///   - beat: Beat number.
    ///   - subbeat: Subbeat number.
    ///   - cent: Cent number.
    init(bar: Int, beat: Int, subbeat: Int, cent: Int) {
        self.bar = bar
        self.beat = beat
        self.subbeat = subbeat
        self.cent = cent
    }

    //  /// Returns the next position.
    //  var next: ScaleNotePosition {
    //    var position = self
    //    position.cent += 1
    //    if position.cent > 240 {
    //      position.subbeat += 1
    //      position.cent = 0
    //    }
    //    if position.subbeat > 4 {
    //      position.beat += 1
    //      position.subbeat = 0
    //    }
    //    if position.beat > 4 {
    //      position.bar += 1
    //      position.beat = 0
    //    }
    //    return position
    //  }
    //
    //  /// Returns the previous position.
    //  var previous: ScaleNotePosition {
    //    var position = self
    //    position.cent -= 1
    //    if position.cent < 0 {
    //      position.subbeat -= 1
    //      position.cent = 240
    //    }
    //    if position.subbeat < 0 {
    //      position.beat -= 1
    //      position.subbeat = 4
    //    }
    //    if position.beat < 0 {
    //      position.bar -= 1
    //      position.beat = position.bar < 0 ? 0 : 4
    //    }
    //    if position.bar < 0 {
    //      position.bar = 0
    //    }
    //    return self
    //  }

    func beats() -> Float32 {
        // TODO: remove hardcodings of 4.  This should be based on time signature
        // and note value
        return Float32(beat) + Float32(bar) * 4.0 + Float32(subbeat) / 4.0
    }

    /// Returns beat text friendly string.
    var description: String {
        if beat == 0 && subbeat == 0 && cent == 0 {
            return "\(bar)"
        } else if subbeat == 0 && cent == 0 {
            return "\(bar).\(beat)"
        } else if cent == 0 {
            return "\(bar).\(beat).\(subbeat)"
        } else {
            return "\(bar).\(beat).\(subbeat).\(cent)"
        }
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(bar)
        hasher.combine(beat)
        hasher.combine(subbeat)
        hasher.combine(cent)
    }
}

// MARK: - NoteValueExtension

extension ScaleNotePosition {
    var noteValue: NoteValue? {
        if beat == 0, subbeat == 0, cent == 0 {
            return NoteValue(type: .whole)
        } else if beat == 2, subbeat == 0, cent == 0 {
            return NoteValue(type: .half)
        } else if subbeat == 0, cent == 0 {
            return NoteValue(type: .quarter)
        } else if subbeat == 2, cent == 0 {
            return NoteValue(type: .eighth)
        } else if cent == 120 {
            return NoteValue(type: .thirtysecond)
        } else if cent == 60 {
            return NoteValue(type: .sixtyfourth)
        }
        return nil
    }
}

extension NoteValue {
    var noteDuration: ScaleNotePosition {
        switch type {
        case .doubleWhole:
            return ScaleNotePosition(bar: 2, beat: 0, subbeat: 0, cent: 0)
        case .whole:
            return ScaleNotePosition(bar: 1, beat: 0, subbeat: 0, cent: 0)
        case .half:
            return ScaleNotePosition(bar: 0, beat: 2, subbeat: 0, cent: 0)
        case .quarter:
            return ScaleNotePosition(bar: 0, beat: 1, subbeat: 0, cent: 0)
        case .eighth:
            return ScaleNotePosition(bar: 0, beat: 0, subbeat: 2, cent: 0)
        case .sixteenth:
            return ScaleNotePosition(bar: 0, beat: 0, subbeat: 1, cent: 0)
        case .thirtysecond:
            return ScaleNotePosition(bar: 0, beat: 0, subbeat: 0, cent: 120)
        case .sixtyfourth:
            return ScaleNotePosition(bar: 0, beat: 0, subbeat: 0, cent: 60)
        }
    }
}
