//
//  MidiPlayerTests.swift
//  ScalePlayerTests
//
//  Created by John Shimmin on 1/14/23.
//  Copyright © 2023 shimmin. All rights reserved.
//

@testable import ScalePlayer
import XCTest

class MidiPlayerTests: XCTestCase {
    var playbackCompleted: XCTestExpectation?

    override func setUp() {
        playbackCompleted = expectation(description: "playbackCompleted")
    }

    /*
     func testCallback() {

         let player = MidiPlayer()
         player.addDelegate(self)

         let notes = ScaleBuilder().play(65).play(66).play(77).notes
         player.play(notes: notes)

         wait(for: [playbackCompleted!], timeout: 10)
     }
      */
}

extension MidiPlayerTests: MidiPlayerDelegate {
    func playbackStopped(completed: Bool) {
        playbackCompleted!.fulfill()
    }
}
