//
//  ScalePlayerTests.swift
//  ScalePlayerTests
//
//  Copyright © 2022 shimmin. All rights reserved.
//

import CoreData
import Factory
import Mockingbird
import XCTest

@testable import ScalePlayer

class ScaleNoteTests: XCTestCase {
    func testPosition() {
        let position = ScaleNotePosition(bar: 0, beat: 0, subbeat: 0, cent: 0)
        XCTAssertEqual(position, .zero)

        let add = ScaleNotePosition(bar: 0, beat: 0, subbeat: 0, cent: 240)
        XCTAssertEqual(position + add, ScaleNotePosition(bar: 0, beat: 0, subbeat: 1, cent: 0))

        let sub1 = ScaleNotePosition(bar: 2, beat: 3, subbeat: 3, cent: 123)
        let sub2 = ScaleNotePosition(bar: 1, beat: 4, subbeat: 2, cent: 232)
        XCTAssertEqual(sub1 - sub2, ScaleNotePosition(bar: 0, beat: 3, subbeat: 0, cent: 131))
        XCTAssertEqual(sub2 - sub1, .zero)

        XCTAssert(sub1 > sub2)
    }
}
