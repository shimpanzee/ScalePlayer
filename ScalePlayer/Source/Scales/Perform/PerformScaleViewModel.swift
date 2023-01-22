//
//  PerformScaleViewModel.swift
//  ScalePlayer
//
//  Created by John Shimmin on 12/28/22.
//  Copyright © 2022 shimmin. All rights reserved.
//

import Factory
import Foundation
import MusicTheorySwift

class PerformScaleViewModel: MidiPlayerDelegate, TempoViewModelDelegate {
    let routine: PracticeRoutine?

    @PublishedOnMain
    private(set) var scale: PracticeScale!

    @PublishedOnMain
    private(set) var octaveChangeDirection: Int = 1

    @PublishedOnMain
    private(set) var autoRepeat = true

    @PublishedOnMain
    private(set) var currentNoteIndex: Int?

    @PublishedOnMain
    private(set) var currentNoteName: String = "-"

    @PublishedOnMain
    private(set) var isPlaying = false

    @PublishedOnMain
    var transposition: Int = 0 {
        didSet {
            midiPlayer.transposition = transposition
        }
    }

    @PublishedOnMain
    var tempo: Int {
        didSet {
            midiPlayer.tempo = Float64(tempo)
        }
    }

    @PublishedOnMain
    var shouldShowNextButton = false

    @PublishedOnMain
    var isShowNextButtonEnabled = false

    @PublishedOnMain
    var currentBeat: Int = 0

    let defaultTempo = 120

    @Injected(Container.midiPlayer) var midiPlayer: MidiPlayer

    private(set) var currentScaleIndex: Int? {
        didSet {
            if let currentScaleIndex = currentScaleIndex, let routine = routine {
                isShowNextButtonEnabled = currentScaleIndex < routine.scales!.count - 1

                let scaleLink = routine.scale(atIndex: currentScaleIndex)
                guard let scale = scaleLink.scale else {
                    fatalError("RoutineScale has a null scale -- which should be impossible")
                }
                self.scale = scale
                midiPlayer.tempo = Float64(scaleLink.tempo)
            } else {
                isShowNextButtonEnabled = false
            }
        }
    }

    // swiftlint:disable inert_defer

    init(scale: PracticeScale) {
        routine = nil
        self.scale = scale
        tempo = 0
        midiPlayer.addDelegate(self)
        // Defer assignment to force didSet on tempo property
        defer {
            tempo = defaultTempo
        }
    }

    init(routine: PracticeRoutine) {
        self.routine = routine
        shouldShowNextButton = true
        tempo = 0
        midiPlayer.addDelegate(self)
        // Defer assignment to force didSet on currentScaleIndex property.
        // The didSet method will ensure that the scale property is set
        defer {
            currentScaleIndex = 0
        }
    }

    // swiftlint:enable inert_defer

    deinit {
        midiPlayer.removeDelegate(self)
        midiPlayer.stop()
    }

    func toggleRepeat() {
        autoRepeat = !autoRepeat
    }

    func togglePlay() {
        if isPlaying {
            stop()
        } else {
            play()
        }
    }

    func toggleTransposeDirection() {
        octaveChangeDirection *= -1
    }

    private func play() {
        midiPlayer.play(notes: scale.notes)
    }

    func changeKeyAndPlay() {
        transposition += octaveChangeDirection

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            if let self = self {
                self.play()
            }
        }
    }

    func swipe(dir: Int) {
        if dir != octaveChangeDirection {
            toggleTransposeDirection()
        } else {
            changeKeyAndPlay()
        }
    }

    @objc
    func stop() {
        midiPlayer.stop()
    }

    func close() {
        stop()
    }

    func noteUpdated(index: Int) {
        currentNoteIndex = index >= 0 ? index : nil

        let currentNote: ScaleNote? = index >= 0 ? scale.notes[index] : nil

        if let currentNote = currentNote {
            currentNoteName = Pitch(midiNote: Int(currentNote.midiNote)).key.description
        } else {
            currentNoteName = "-"
        }
    }

    func nextScale() {
        guard let currentScaleIndex = currentScaleIndex else {
            fatalError("nextScale called nil currentScaleIndex")
        }
        self.currentScaleIndex = currentScaleIndex+1
    }

    // MARK: - view creation

    func createTempoView(guide: UILayoutGuide) -> TempoView {
        let tempoView = Container.tempoView((tempo: tempo, guide: guide, delegate: self))
        return tempoView
    }

    // MARK: TempoViewModelDelegate implementation

    func tempoDidChange(tempo: Int) {
        self.tempo = tempo
    }

    // MARK: - MidiPlayerDelegate implementation

    func playbackBegan() {
        isPlaying = true
    }

    func playbackStopped(completed: Bool) {
        if autoRepeat && completed {
            changeKeyAndPlay()
        } else {
            isPlaying = false
        }
    }

    func beat(num: Int) {
        currentBeat = num
    }
}
