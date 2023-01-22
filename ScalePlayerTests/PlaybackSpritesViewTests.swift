//
//  PlaybackSpritesViewTests.swift
//  ScalePlayerTests
//
//  Created by John Shimmin on 1/14/23.
//  Copyright © 2023 shimmin. All rights reserved.
//

@testable import ScalePlayer
import XCTest

class PlaybackSpritesViewTests: XCTestCase {
    func testSpriteColors() throws {
        let notes = ScaleBuilder().play(65).play(66).play(77).notes
        let view = PlaybackSpritesView(notes: notes)

        let nonlitColor = UIColor.app.noteSprite.cgColor
        let litColor = UIColor.app.noteSpritePlaying.cgColor

        let noSpritesPlaying = [nonlitColor, nonlitColor, nonlitColor]
        XCTAssertEqual(view.sprites.map { sprite in sprite.fillColor }, noSpritesPlaying)

        let firstSpritePlaying = [litColor, nonlitColor, nonlitColor]
        view.currentNoteIndex = 0
        XCTAssertEqual(view.sprites.map { sprite in sprite.fillColor }, firstSpritePlaying)
    }
}
