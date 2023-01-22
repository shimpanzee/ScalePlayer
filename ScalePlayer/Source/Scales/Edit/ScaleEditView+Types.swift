//
//  ScaleEditView+Types.swift
//
//  Copyright © 2023 John Shimmin. All rights reserved.
//

import Foundation
import MusicTheorySwift

extension ScaleEditView {

    class GridLayerView: UIView {
        override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
            return false
        }
    }

    /// scale edit grid keys.
    enum Keys {
        /// In a MIDI note range between 0 - 127
        case ranged(ClosedRange<UInt8>)
        /// In a musical scale.
        case scale(scale: Scale, minOctave: Int, maxOctave: Int)
        /// With custom keys.
        case custom([Pitch])

        /// Returns the pitches.
        var pitches: [Pitch] {
            switch self {
            case .ranged(let range):
                return range.map { Pitch(midiNote: Int($0)) }.sorted(by: { $0 > $1 })
            case .scale(let scale, let minOctave, let maxOctave):
                return scale.pitches(octaves: [Int](minOctave ... maxOctave))
                    .sorted(by: { $0 > $1 })
            case .custom(let pitches):
                return pitches.sorted(by: { $0 > $1 })
            }
        }
    }

    /// All grid lines for line with and color customisation.
    struct GridLine {
        /// Width of the line.
        var width: CGFloat
        /// Color of the line.
        var color: UIColor
        /// Color of the line.
        var dashPattern: [NSNumber]?

        /// Initilize grid line with width, color and optional dash pattern.
        ///
        /// - Parameters:
        ///   - width: Line width. Defaults 0.5.
        ///   - color: Line color. Defaults black.
        ///   - dashPattern: Optinoal line dash pattern. Defaults nil.
        init(
            width: CGFloat = 1.0 / UIScreen.main.scale,
            color: UIColor = .black,
            dashPattern: [NSNumber]? = nil) {
            self.width = width
            self.color = color
            self.dashPattern = dashPattern
        }

        /// Initilize the line with scale edit grid position. Useful for initilizing for measure
        /// lines.
        ///
        /// - Parameter notePosition: Line's position on the scale edit grid.
        init?(from notePosition: ScaleNotePosition) {
            switch notePosition.noteValue {
            case .some(let position):
                switch position.type {
                case .whole: self = .bar
                case .half: self = .half
                case .quarter: self = .quarter
                case .eighth: self = .eighth
                case .sixteenth: self = .sixteenth
                case .thirtysecond: self = .thirtysecond
                case .sixtyfourth: self = .sixtyfourth
                default: return nil
                }
            case .none:
                return nil
            }
        }

        /// Default line styling.
        static var `default` = GridLine()
        /// Horizontal line under each row.
        static var rowHorizontal = GridLine()
        /// Vertical line between row keys and the grid.
        static var rowVertical = GridLine()
        /// Vertical line under the measure.
        static var measureBottom = GridLine(width: 1)
        /// Beat text on the measure. Width property represents the font size.
        static var measureText = GridLine(width: 13)
        /// Vertical line for each bar line
        static var bar = GridLine(width: 1)
        /// Vertical line for each half beat line.
        static var half = GridLine(color: .gray)
        /// Vertical line for each quarter beat line.
        static var quarter = GridLine(color: .gray)
        /// Vertical line for each eighth beat line.
        static var eighth = GridLine(color: .gray)
        /// Vertical line for each sixteenth beat line.
        static var sixteenth = GridLine(color: .gray)
        /// Vertical line for each thirtysecond beat line.
        static var thirtysecond = GridLine(color: .gray)
        /// Vertical line for each sixthfourth beat line.
        static var sixtyfourth = GridLine(color: .gray)
    }

    /// Zoom level of the scale edit grid that showing the mininum amount of beat.
    enum ZoomLevel: Int {
        /// A beat represent whole note. See one beat in a bar.
        case wholeNotes = 1
        /// A beat represent sixtyfourth note. See 2 beats in a bar.
        case halfNotes = 2
        /// A beat represent quarter note. See 4 beats in a bar.
        case quarterNotes = 4
        /// A beat represent eighth note. See 8 beats in a bar.
        case eighthNotes = 8
        /// A beat represent sixteenth note. See 16 beats in a bar.
        case sixteenthNotes = 16
        /// A beat represent thirtysecond note. See 32 beats in a bar.
        case thirtysecondNotes = 32
        /// A beat represent sixtyfourth note. See 64 beats in a bar.
        case sixtyfourthNotes = 64

        /// Corresponding note value for the zoom level.
        var noteValue: NoteValue {
            switch self {
            case .wholeNotes: return NoteValue(type: .whole)
            case .halfNotes: return NoteValue(type: .half)
            case .quarterNotes: return NoteValue(type: .quarter)
            case .eighthNotes: return NoteValue(type: .eighth)
            case .sixteenthNotes: return NoteValue(type: .sixteenth)
            case .thirtysecondNotes: return NoteValue(type: .thirtysecond)
            case .sixtyfourthNotes: return NoteValue(type: .sixtyfourth)
            }
        }

        /// Next level after zooming in.
        var zoomedIn: ZoomLevel? {
            switch self {
            case .wholeNotes: return .halfNotes
            case .halfNotes: return .quarterNotes
            case .quarterNotes: return .eighthNotes
            case .eighthNotes: return .sixteenthNotes
            case .sixteenthNotes: return .thirtysecondNotes
            case .thirtysecondNotes: return .sixtyfourthNotes
            case .sixtyfourthNotes: return nil
            }
        }

        /// Previous level after zooming out.
        var zoomedOut: ZoomLevel? {
            switch self {
            case .wholeNotes: return nil
            case .halfNotes: return .wholeNotes
            case .quarterNotes: return .halfNotes
            case .eighthNotes: return .quarterNotes
            case .sixteenthNotes: return .eighthNotes
            case .thirtysecondNotes: return .sixteenthNotes
            case .sixtyfourthNotes: return .thirtysecondNotes
            }
        }

        /// Rendering measure texts for note values in each zoom level.
        var renderingMeasureTexts: [NoteValue] {
            switch self {
            case .wholeNotes:
                return [NoteValue(type: .whole)]
            case .halfNotes:
                return [NoteValue(type: .whole)]
            case .quarterNotes:
                return [NoteValue(type: .whole)]
            case .eighthNotes:
                return [NoteValue(type: .whole), NoteValue(type: .half)]
            case .sixteenthNotes:
                return [NoteValue(type: .whole), NoteValue(type: .half), NoteValue(type: .quarter)]
            case .thirtysecondNotes:
                return [
                    NoteValue(type: .whole),
                    NoteValue(type: .half),
                    NoteValue(type: .quarter),
                    NoteValue(type: .eighth)
                ]
            case .sixtyfourthNotes:
                return [
                    NoteValue(type: .whole),
                    NoteValue(type: .half),
                    NoteValue(type: .quarter),
                    NoteValue(type: .eighth),
                    NoteValue(type: .sixteenth)
                ]
            }
        }
    }
}
