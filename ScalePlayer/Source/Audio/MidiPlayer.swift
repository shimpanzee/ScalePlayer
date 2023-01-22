//
//  AVPlayer.swift
//  ScalePlayer
//
//  Wrapper for Apple midi facilities.  Supports callbacks for each note
//  and beat.
//
//  Note that we predominantely use AVFoundation for playback, but manual track
//  creation is not supported there.  Luckily, it's possible to mix-and-match
//  and use AudioToolbox for the track creation.
//
//  Note: I originally implemented using pure AudioToolbox APIs, but sound font loading
//  is unacceptably slow there (a couple of seconds for a load).
//
//  Apple doesn't support beat and note callbacks, but it does support callbacks for midi
//  user events.  We take advantage of this and write user events to the midi track for
//  each beat and note.
// 
//  Created by John Shimmin on 12/31/22.
//  Copyright © 2022 shimmin. All rights reserved.
//

import AVFoundation
import Combine
import Factory
import OSLog

@objc protocol MidiPlayerDelegate: AnyObject {
    @objc optional func playbackBegan()
    @objc optional func playbackStopped(completed: Bool)
    @objc optional func noteUpdated(index: Int)
    @objc optional func beat(num: Int)
}

class MidiPlayer {
    @PublishedOnMain
    private(set) var beatPosition: Int?

    var transposition: Int = 0

    var tempo: Float64 = 0 {
        didSet {
            updateTempo()
        }
    }

    private var playTimer: Cancellable?
    private var delegates = WeakObjectSet<MidiPlayerDelegate>()
    private var track: MusicTrack!

    private let defaultTempo: Float64 = 120
    private let engine = AVAudioEngine()
    private let sampler = AVAudioUnitSampler()
    private let sequencer: AVAudioSequencer

    enum MidiSignal: UInt8 {
        case beat = 0xfe
        case eof = 0xff
    }

    init() {
        let output = engine.outputNode
        let outputHWFormat = output.outputFormat(forBus: 0)

        let mainMixer = engine.mainMixerNode
        engine.connect(mainMixer, to: output, format: outputHWFormat)

        engine.attach(sampler)
        engine.connect(sampler, to: mainMixer, format: outputHWFormat)

        sequencer = AVAudioSequencer(audioEngine: engine)
        sequencerSetup()

        do {
            try engine.start()
        } catch {
            Container.errorHandler()
                .report(error, userMessage: "Engined failed to start", level: .fault)
        }

        // Defer assignment to force didSet on tempo property
        // swiftlint:disable inert_defer
        defer {
            tempo = defaultTempo
        }
        // swiftlint:enable inert_defer
    }

    func play(notes: [ScaleNote]) {
        clearTrack()

        // now make some notes and put them on the track
        for (index, note) in notes.enumerated() {
            // TODO: make sure we can't overflow or have weird conversion errors
            let midiNote = transposition < 0 ? note.midiNote - UInt8(-transposition) : note
                .midiNote + UInt8(transposition)
            var mess = MIDINoteMessage(channel: 0,
                                       note: midiNote,
                                       velocity: note.velocity,
                                       releaseVelocity: 0,
                                       duration: note.duration.beats())
            let timeStamp = MusicTimeStamp(note.position.beats())
            let status = MusicTrackNewMIDINoteEvent(track, timeStamp, &mess)
            if status != OSStatus(noErr) {
                checkError(status)
            }
            var eventData = MusicEventUserData(length: 1, data: UInt8(index))
            MusicTrackNewUserEvent(track, timeStamp, &eventData)
        }

        let trackLength = getTrackLength(track)
        var eventData = MusicEventUserData(length: 1, data: MidiSignal.eof.rawValue)
        MusicTrackNewUserEvent(track, trackLength, &eventData)

        for beat in 0 ... Int(trackLength.rounded()) {
            var eventData = MusicEventUserData(length: 1, data: MidiSignal.beat.rawValue)
            MusicTrackNewUserEvent(track, MusicTimeStamp(beat), &eventData)
        }

        sequencer.currentPositionInBeats = 0
        sequencer.prepareToPlay()
        do {
            try sequencer.start()
        } catch {
            Container.errorHandler()
                .report(error, userMessage: "Failed to start sequencer", level: .fault)
        }
    }

    func stop(completed: Bool = false) {
        sequencer.stop()
        playTimer?.cancel()
        playTimer = nil

        for delegate in delegates.allObjects {
            delegate.playbackStopped?(completed: completed)
        }
    }

    func addDelegate(_ delegate: MidiPlayerDelegate) {
        delegates.addObject(delegate)
    }

    func removeDelegate(_ delegate: MidiPlayerDelegate) {
        delegates.remove(delegate)
    }
}

extension MidiPlayer {
    // MARK: Private implementation

    private func updateTempo() {
        guard let sequence = engine.musicSequence
        else {
            fatalError("setTempo: unable to find sequence")
        }
        var tempoTrack: MusicTrack!
        MusicSequenceGetTempoTrack(sequence, &tempoTrack)

        MidiPlayer.removeTempoEvents(tempoTrack)
        MusicTrackNewExtendedTempoEvent(tempoTrack, 0, tempo)
    }

    private func loadSampler() {
        do {
            let bankURL: URL = Bundle.main.url(forResource: "TimGM6mb", withExtension: "sf2")!

            try sampler.loadSoundBankInstrument(at: bankURL,
                                                program: 0,
                                                bankMSB: UInt8(kAUSampler_DefaultMelodicBankMSB),
                                                bankLSB: UInt8(kAUSampler_DefaultBankLSB))
        } catch {
            Container.errorHandler()
                .report(error, userMessage: "Error loading sound bank instrument", level: .fault)
        }
    }

    private func sequencerSetup() {
        loadSampler()

        let musicSequence = engine.musicSequence

        let status = MusicSequenceNewTrack(musicSequence!, &track)
        if status != OSStatus(noErr) {
            Logger.audio.critical("error creating track \(status)")
        }

        // swiftlint:disable function_parameter_count
        func userCallback(inClientData: UnsafeMutableRawPointer?,
                          sequence: MusicSequence,
                          track: MusicTrack,
                          eventTime: MusicTimeStamp,
                          data: UnsafePointer<MusicEventUserData>,
                          startSliceBeat: MusicTimeStamp,
                          endSliceBeat: MusicTimeStamp) {
            let player = unsafeBitCast(inClientData, to: MidiPlayer.self)

            let eventData: MusicEventUserData = data.pointee
            let noteIndex = eventData.data

            switch MidiSignal(rawValue: noteIndex) {
            case .eof: player.signalEndOfTrack()
            case .beat: player.signalBeat()
            default: player.signalNoteUpdated(noteIndex: Int(noteIndex))
            }
        }
        // swiftlint:enable function_parameter_count

        MusicSequenceSetUserCallback(
            musicSequence!,
            userCallback,
            unsafeBitCast(self, to: UnsafeMutableRawPointer.self))
    }

    private func clearTrack() {
        let trackLength = getTrackLength(track!)

        if trackLength > 0 {
            MusicTrackClear(track!, MusicTimeStamp(0), trackLength + 1)
        }
    }

    private func getTrackLength(_ musicTrack: MusicTrack) -> MusicTimeStamp {
        // The time of the last music event in a music track, plus time required for note fade-outs
        // and so on.
        var trackLength = MusicTimeStamp(0)
        var tracklengthSize = UInt32(0)
        let status = MusicTrackGetProperty(musicTrack,
                                           UInt32(kSequenceTrackProperty_TrackLength),
                                           &trackLength,
                                           &tracklengthSize)
        if status != noErr {
            Logger.audio.critical("Error getting track length \(status)")
            checkError(status)
            return 0
        }
        return trackLength
    }

    static func removeTempoEvents(_ tempoTrack: MusicTrack) {
        var tempIter: MusicEventIterator?
        NewMusicEventIterator(tempoTrack, &tempIter)
        guard let tempIter = tempIter
        else {
            fatalError("Unable to create tempIter")
        }

        var hasEvent: DarwinBoolean = false
        MusicEventIteratorHasCurrentEvent(tempIter, &hasEvent)
        while hasEvent.boolValue {
            var stamp: MusicTimeStamp = 0
            var type: MusicEventType = 0
            var data: UnsafeRawPointer?
            var sizeData: UInt32 = 0

            MusicEventIteratorGetEventInfo(tempIter, &stamp, &type, &data, &sizeData)
            if type == kMusicEventType_ExtendedTempo {
                MusicEventIteratorDeleteEvent(tempIter)
                MusicEventIteratorHasCurrentEvent(tempIter, &hasEvent)
            } else {
                MusicEventIteratorNextEvent(tempIter)
                MusicEventIteratorHasCurrentEvent(tempIter, &hasEvent)
            }
        }
        DisposeMusicEventIterator(tempIter)
    }

    private func checkError(_ error: OSStatus) {
        if error == 0 { return }
        let statusToStringMap: [OSStatus: String] = [
            kAUGraphErr_NodeNotFound: "Error:kAUGraphErr_NodeNotFound",
            kAUGraphErr_OutputNodeErr: "Error:kAUGraphErr_OutputNodeErr",
            kAUGraphErr_InvalidConnection: "Error:kAUGraphErr_InvalidConnection",
            kAUGraphErr_CannotDoInCurrentContext: "Error:kAUGraphErr_CannotDoInCurrentContext",
            kAUGraphErr_InvalidAudioUnit: "Error:kAUGraphErr_InvalidAudioUnit",
            kAudioToolboxErr_InvalidSequenceType: "kAudioToolboxErr_InvalidSequenceType",
            kAudioToolboxErr_TrackIndexError: "kAudioToolboxErr_TrackIndexError",
            kAudioToolboxErr_TrackNotFound: "kAudioToolboxErr_TrackNotFound",
            kAudioToolboxErr_EndOfTrack: "kAudioToolboxErr_EndOfTrack",
            kAudioToolboxErr_StartOfTrack: "kAudioToolboxErr_StartOfTrack",
            kAudioToolboxErr_IllegalTrackDestination: "kAudioToolboxErr_IllegalTrackDestination",
            kAudioToolboxErr_NoSequence: "kAudioToolboxErr_NoSequence",
            kAudioToolboxErr_InvalidEventType: "kAudioToolboxErr_InvalidEventType",
            kAudioToolboxErr_InvalidPlayerState: "kAudioToolboxErr_InvalidPlayerState",
            kAudioUnitErr_InvalidProperty: "kAudioUnitErr_InvalidProperty",
            kAudioUnitErr_InvalidParameter: "kAudioUnitErr_InvalidParameter",
            kAudioUnitErr_InvalidElement: "kAudioUnitErr_InvalidElement",
            kAudioUnitErr_NoConnection: "kAudioUnitErr_NoConnection",
            kAudioUnitErr_FailedInitialization: "kAudioUnitErr_FailedInitialization",
            kAudioUnitErr_TooManyFramesToProcess: "kAudioUnitErr_TooManyFramesToProcess",
            kAudioUnitErr_InvalidFile: "kAudioUnitErr_InvalidFile",
            kAudioUnitErr_FormatNotSupported: "kAudioUnitErr_FormatNotSupported",
            kAudioUnitErr_Uninitialized: "kAudioUnitErr_Uninitialized",
            kAudioUnitErr_InvalidScope: "kAudioUnitErr_InvalidScope",
            kAudioUnitErr_PropertyNotWritable: "kAudioUnitErr_PropertyNotWritable",
            kAudioUnitErr_InvalidPropertyValue: "kAudioUnitErr_InvalidPropertyValue",
            kAudioUnitErr_PropertyNotInUse: "kAudioUnitErr_PropertyNotInUse",
            kAudioUnitErr_Initialized: "kAudioUnitErr_Initialized",
            kAudioUnitErr_InvalidOfflineRender: "kAudioUnitErr_InvalidOfflineRender",
            kAudioUnitErr_Unauthorized: "kAudioUnitErr_Unauthorized"
        ]

        let statusString = statusToStringMap[error] ?? "No matching string for code: \(error)"
        Logger.audio.critical("AVFoundation error: \(statusString)")
    }
}

extension MidiPlayer {
    // MARK: - delegate handling

    func signalAllDelegates(_ action: @escaping (MidiPlayerDelegate) -> Void) {
        DispatchQueue.main.async { [weak self] in
            _ = self?.delegates.allObjects.map { action($0) }
        }
    }

    func signalBeat() {
        let currentBeat = Int(sequencer.currentPositionInBeats.rounded())
        signalAllDelegates { delegate in
            delegate.beat?(num: currentBeat)
        }
    }

    func signalEndOfTrack() {
        signalAllDelegates { delegate in
            delegate.playbackStopped?(completed: true)
        }
    }

    func signalNoteUpdated(noteIndex: Int) {
        signalAllDelegates { delegate in
            delegate.noteUpdated?(index: noteIndex)
        }
    }
}
