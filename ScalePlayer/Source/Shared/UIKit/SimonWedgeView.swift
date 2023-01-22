//
//  SimonWedgeView.swift
//  ScalePlayer
//
//  Created by John Shimmin on 1/8/23.
//  Copyright © 2023 shimmin. All rights reserved.
//

import UIKit

typealias Radians = CGFloat

extension UIBezierPath {
    static func simonWedge(innerRadius: CGFloat, outerRadius: CGFloat,
                           centerAngle: Radians) -> UIBezierPath {
        let innerAngle: Radians = CGFloat.pi / 4
        let outerAngle: Radians = CGFloat.pi / 4
        let path = UIBezierPath()
        path.addArc(
            withCenter: .zero,
            radius: innerRadius,
            startAngle: centerAngle - innerAngle,
            endAngle: centerAngle + innerAngle,
            clockwise: true)
        path.addArc(
            withCenter: .zero,
            radius: outerRadius,
            startAngle: centerAngle + outerAngle,
            endAngle: centerAngle - outerAngle,
            clockwise: false)
        path.close()
        return path
    }
}

class SimonWedgeView: UIView {
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    required init?(coder decoder: NSCoder) {
        super.init(coder: decoder)
        commonInit()
    }

    var centerAngle: Radians = 0 { didSet { setNeedsDisplay() } }
    var color: UIColor = #colorLiteral(red: 0.8549019694, green: 0.250980407, blue: 0.4784313738, alpha: 1) { didSet { setNeedsDisplay() } }

    override func draw(_ rect: CGRect) {
        let path = wedgePath()
        color.setFill()
        path.fill()
    }

    private func commonInit() {
        contentMode = .redraw
        backgroundColor = .clear
        isOpaque = false
    }

    private func wedgePath() -> UIBezierPath {
        let bounds = self.bounds
        let outerRadius = min(bounds.size.width, bounds.size.height) / 2
        let innerRadius = outerRadius / 2
        let path = UIBezierPath.simonWedge(
            innerRadius: innerRadius,
            outerRadius: outerRadius,
            centerAngle: centerAngle)
        path.apply(CGAffineTransform(translationX: bounds.midX, y: bounds.midY))
        return path
    }
}
