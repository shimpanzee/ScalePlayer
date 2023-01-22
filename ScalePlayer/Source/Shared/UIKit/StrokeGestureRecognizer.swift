//
//  StrokeGestureRecognizer.swift
//  MidiScratch
//
//  Created by John Shimmin on 11/2/22.
//

import OSLog
import UIKit

class StrokeGestureRecognizerDelegate {}

class StrokeGestureRecognizer: UIGestureRecognizer {
    var noteOffset: Int = 0
    var startLoc: CGPoint = .zero
    var endLoc: CGPoint = .zero

    override init(target: Any?, action: Selector?) {
        super.init(target: target, action: action)
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
        if touches.count > 1 {
            state = .failed
            return
        }
        let touch = touches.first!
        startLoc = touch.preciseLocation(in: view)
        endLoc = startLoc
        state = .began
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent) {
        let touch = touches.first!
        endLoc = touch.preciseLocation(in: view)
        state = .ended
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent) {
        let touch = touches.first!
        endLoc = touch.preciseLocation(in: view)
        state = .changed
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent) {
        Logger.gestures.debug("Called touchesCancelled, \(self.noteOffset)")
    }

    override func touchesEstimatedPropertiesUpdated(_ touches: Set<UITouch>) {
        Logger.gestures.debug("Called touchesEstimatedPropertiesUpdated, \(self.noteOffset)")
    }

    override func reset() {
        Logger.gestures.debug("StrokeGestureRecognizerDelegate.reset() called")
        super.reset()
    }
}
