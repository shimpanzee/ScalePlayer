//
//  BeatCursor.swift
//
//  Cursor used to visualize the current beat position in the edit grid
//
//  Copyright © 2023 John Shimmin. All rights reserved.
//

import UIKit

class BeatCursor: CAShapeLayer {

    override init() {
        super.init()
        commonInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    override init(layer: Any) {
        super.init(layer: layer)
        commonInit()
    }

    private func commonInit() {
        fillColor = CGColor(gray: 0.5, alpha: 0.2)
    }

    func updateDimensions(x: CGFloat, y: CGFloat, width: CGFloat, height: CGFloat) {
        let beatCursorPath = UIBezierPath()

        beatCursorPath.move(to: CGPoint(x: x, y: y))
        beatCursorPath.addLine(to: CGPoint(x: x+width, y: y))
        beatCursorPath.addLine(to: CGPoint(x: x+width, y: y+height))
        beatCursorPath.addLine(to: CGPoint(x: x, y: y+height))
        beatCursorPath.close()

        path = beatCursorPath.cgPath
    }

    func showAt(x: CGFloat) {
        isHidden = false
        position.x = x
    }
}
