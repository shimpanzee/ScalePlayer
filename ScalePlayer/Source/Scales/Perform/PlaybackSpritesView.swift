//
//  PlaybackSpritesView.swift
//  ScalePlayer
//
//  Visualization of the notes being practiced/sung.  Currently playing note is highlighted.
// 
//  Created by John Shimmin on 1/11/23.
//  Copyright © 2023 shimmin. All rights reserved.
//

import UIKit

class PlaybackSpritesView: UIView {
    var currentNoteIndex: Int? {
        didSet {
            updateSpriteColors(oldIndex: oldValue)
        }
    }

    private var sprites: [CAShapeLayer]

    init(notes: [ScaleNote]) {
        let minNote = notes.map {
            $0.midiNote
        }.min()!

        let maxNote = notes.map {
            $0.midiNote
        }.max()!

        let lastNote = notes.last!
        let endBeat = (lastNote.position + lastNote.duration).beats()

        let noteRange = Int(maxNote - minNote)

        let beatWidth = 12.0
        let keyHeight = 5.0

        let yInset = 10.0
        let xInset = 0.0

        let playbackHeight = Double(noteRange) * keyHeight
        let playbackWidth = Double(endBeat) * beatWidth

        let dotColor = UIColor.app.noteSprite.cgColor

        let playbackView =
            UIView(frame: CGRect(x: 0.0, y: 0.0, width: playbackWidth,
                                 height: playbackHeight + (yInset * 2)))

        sprites = notes.map { note -> CAShapeLayer in
            let y = Double(note.midiNote - minNote)
            let beatPos = Double(note.position.beats())
            let dotRect = CGRect(x: xInset + Double(beatPos * beatWidth),
                                 y: CGFloat(yInset + (playbackHeight - y * keyHeight)),
                                 width: beatWidth * Double(note.duration.beats()) - 2,
                                 height: keyHeight - 2)
            let dotPath = UIBezierPath(ovalIn: dotRect)

            let layer = CAShapeLayer()
            layer.path = dotPath.cgPath
            layer.strokeColor = dotColor
            layer.fillColor = dotColor

            playbackView.layer.addSublayer(layer)

            return layer
        }

        super.init(frame: .null)

        backgroundColor = .clear

        addSubview(playbackView)
        playbackView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            playbackView.centerXAnchor.constraint(equalTo: centerXAnchor),
            playbackView.centerYAnchor.constraint(equalTo: centerYAnchor),
            playbackView.widthAnchor.constraint(equalToConstant: playbackWidth),
            playbackView.heightAnchor.constraint(equalToConstant: playbackHeight + (yInset * 2))
        ])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func updateSpriteColors(oldIndex: Int?) {
        if let oldIndex = oldIndex {
            sprites[oldIndex].strokeColor = UIColor.app.noteSprite.cgColor
            sprites[oldIndex].fillColor = UIColor.app.noteSprite.cgColor
        }
        if let newIndex = currentNoteIndex {
            sprites[newIndex].strokeColor = UIColor.app.noteSpritePlaying.cgColor
            sprites[newIndex].fillColor = UIColor.app.noteSpritePlaying.cgColor
        }
    }
}
