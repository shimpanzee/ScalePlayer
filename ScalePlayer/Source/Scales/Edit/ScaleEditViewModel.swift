//
//  ScaleEditViewModel.swift
//  ScalePlayer
//
//  Created by John Shimmin on 11/22/22.
//  Copyright © 2022 shimmin. All rights reserved.
//

import Combine
import CoreData
import Factory
import Foundation
import MusicTheorySwift
import OSLog

enum MidiToolType: String, CaseIterable {
    case paintbrush
    case eraser = "scissors"
}

protocol ScaleEditResponder {
    func editComplete(scale: PracticeScale)
}

class ScaleEditViewModel: TempoViewModelDelegate, MidiPlayerDelegate {
    @PublishedOnMain
    var notes: [ScaleNote] = []

    /// Time signature of the scale. Defaults to 4/4.
    @PublishedOnMain
    var timeSignature = MusicTheorySwift.TimeSignature()

    @PublishedOnMain
    var tempo: Int = 120 {
        didSet {
            player.tempo = Double(tempo)
        }
    }

    @PublishedOnMain
    var tool: MidiToolType = .paintbrush

    @PublishedOnMain
    var isPlaying = false

    @PublishedOnMain
    var title = "<new scale>"

    @PublishedOnMain
    var name: String = "" {
        didSet {
            title = name
        }
    }

    @PublishedOnMain
    var barCount: Int = 8

    @PublishedOnMain
    var currentPlayingNote: ScaleNote?

    @PublishedOnMain
    var currentBeat: Int?

    @PublishedOnMain
    var editSessionComplete = false

    var lastBar: Int {
        return notes
            .map { $0.position + $0.duration }
            .sorted(by: { $1 > $0 })
            .first?.bar ?? 0
    }

    @Injected(Container.scaleDataStore) private var scaleDataStore: ScaleDataStore
    @Injected(Container.midiPlayer) private var player: MidiPlayer
    @Injected(Container.coreDataContext) private var coreDataContext: CoreDataContext

    private var scaleUpdated = false
    private var scale: PracticeScale?
    private var responder: ScaleEditResponder
    private weak var coordinator: ScalesEditCoordinator?

    init(scale: PracticeScale?, coordinator: ScalesEditCoordinator, responder: ScaleEditResponder) {
        self.scale = scale
        self.coordinator = coordinator

        if let name = scale?.name {
            title = name
            self.name = name
        }
        notes = scale?.notes ?? []
        self.responder = responder
        player.addDelegate(self)
    }

    deinit {
        self.player.removeDelegate(self)
        self.player.stop()
    }

    func startSaving() {
        Logger.app.debug("started saving")
    }

    func togglePlay() {
        if isPlaying {
            isPlaying = false
            player.stop()
        } else {
            isPlaying = true
            player.play(notes: notes)
        }
    }

    @objc
    func clearSequence() {
        notes.removeAll()
    }

    func addNote(_ note: ScaleNote) {
        notes.append(note)
    }

    func addMeasure() {
        barCount += 1
    }

    func updateTool(_ tool: MidiToolType) {
        self.tool = tool
    }

    func removeNote(_ note: ScaleNote) {
        notes.removeAll { n in
            n == note
        }
    }

    func save() {
        if name.isEmpty {
            presentNameAlert(isCreateFlow: true)
            return
        }

        if scale == nil {
            scale = Container.practiceScale()
        }
        let scale = scale!
        scale.name = name
        scale.notes = notes
        coreDataContext.save()
        scaleUpdated = true
        editingCompleted()
    }

    func cancel() {
        editingCompleted()
    }

    func presentNameAlert(isCreateFlow: Bool = false) {
        if let coordinator = coordinator {
            coordinator.showNameDialog(viewModel: self, isCreateFlow: isCreateFlow, validator: { [weak self] name in
                self?.validateName(name) ?? .valid
            })
        }
    }

    func validateName(_ name: String) -> SingleValueEditor.ValidationResult {
        if scaleDataStore.isDuplicate(name: name, scale: scale) {
            return .invalid(message: "Name already exists")
        } else {
            return .valid
        }
    }

    func updateName(_ name: String) {
        guard !scaleDataStore.isDuplicate(name: name, scale: scale)
        else {
            return
        }

        self.name = name

        if !name.isEmpty {
            if let scale = scale {
                scale.name = name
                scaleUpdated = true
                coreDataContext.save()
            }
        }
    }

    func editingCompleted() {
        if scaleUpdated {
            responder.editComplete(scale: scale!)
        }
        editSessionComplete = true
    }

    func createTempoView(guide: UILayoutGuide) -> TempoView {
        let tempoView = Container.tempoView((tempo: tempo, guide: guide, delegate: self))
        return tempoView
    }

    // MARK: - TempoViewModelDelegate implementation

    func tempoDidChange(tempo: Int) {
        self.tempo = tempo
    }

    // MARK: - MidiPlayerDelegate implementation

    func noteUpdated(index: Int) {
        if index >= 0 {
            currentPlayingNote = notes[index]
        } else {
            currentPlayingNote = nil
        }
    }

    func beat(num: Int) {
        currentBeat = num
    }

    func playbackStopped(completed: Bool) {
        if completed {
            currentPlayingNote = nil
        }
    }
}
