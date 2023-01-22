//
//  UIBezierPath+Lines.swift
//
//  Copyright © 2023 John Shimmin. All rights reserved.
//

import UIKit

extension UIBezierPath {

    static func horizontalLine(x: CGFloat, y: CGFloat, length: CGFloat) -> CGPath {
        let path: UIBezierPath = horizontalLine(x: x, y: y, length: length)
        return path.cgPath
    }

    static func horizontalLine(x: CGFloat, y: CGFloat, length: CGFloat) -> UIBezierPath {
        let path = UIBezierPath()
        path.move(to: CGPoint(x: x, y: y))
        path.addLine(to: CGPoint(x: x+length, y: y))
        path.close()
        return path
    }

    static func verticalLine(x: CGFloat, y: CGFloat, length: CGFloat) -> CGPath {
        let path: UIBezierPath = verticalLine(x: x, y: y, length: length)
        return path.cgPath

    }

    static func verticalLine(x: CGFloat, y: CGFloat, length: CGFloat) -> UIBezierPath {
        let path = UIBezierPath()
        path.move(to: CGPoint(x: x, y: y))
        path.addLine(to: CGPoint(x: x, y: y+length))
        path.close()
        return path
    }

}
