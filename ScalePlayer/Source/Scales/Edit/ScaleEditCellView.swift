//
//  ScaleEditCellView.swift
//  ScalePlayer
//
//  Copyright © 2022 shimmin. All rights reserved.
//

import UIKit

/// Delegate functions to inform about editing or deleting cell.
protocol ScaleEditCellViewDelegate: AnyObject {
    /// Informs about moving the cell with the pan gesture.
    ///
    /// - Parameters:
    ///   - scaleEditCellView: Cell that moving around.
    ///   - pan: Pan gesture that moves the cell.
    func scaleEditCellViewDidMove(
        _ scaleEditCellView: ScaleEditCellView,
        pan: UIPanGestureRecognizer)

    /// Informs about resizing the cell with the pan gesture.
    ///
    /// - Parameters:
    ///   - scaleEditCellView: Cell that resizing.
    ///   - pan: Pan gesture that resizes the cell.
    func scaleEditCellViewDidResize(
        _ scaleEditCellView: ScaleEditCellView,
        pan: UIPanGestureRecognizer)

    /// Informs about the cell has been tapped.
    ///
    /// - Parameter scaleEditCellView: The cell that tapped.
    func scaleEditCellViewDidTap(_ scaleEditCellView: ScaleEditCellView)

    /// Informs about the cell is about to delete.
    ///
    /// - Parameter scaleEditCellView: Cell is going to delete.
    func scaleEditCellViewDidDelete(_ scaleEditCellView: ScaleEditCellView)
}

/// Represents a MIDI note of the `ScalePlayer`.
class ScaleEditCellView: UIView {
    /// The rendering note data.
    var note: ScaleNote
    /// Inset from the rightmost side on the cell to capture resize gesture.
    let resizingViewWidth: CGFloat = 20
    /// View that holds the pan gesture on right most side in the view to use in resizing cell.
    let resizeView = UIView()

    /// Delegate that informs about editing cell.
    weak var delegate: ScaleEditCellViewDelegate?

    var tapGesture: UITapGestureRecognizer!

    /// Is cell selected or not.
    var isSelected: Bool = false {
        didSet {
            layer.borderWidth = isSelected ? 2 : 0
            layer.borderColor = isSelected ? UIColor.blue.cgColor : UIColor.clear.cgColor
        }
    }

    // MARK: Init

    /// Initilizes the cell view with a note data.
    ///
    /// - Parameter note: Rendering note data.
    init(note: ScaleNote) {
        self.note = note
        super.init(frame: .zero)
        commonInit()
    }

    /// Initilizes the cell view with a decoder.
    ///
    /// - Parameter aDecoder: Decoder.
    required init?(coder aDecoder: NSCoder) {
        note = ScaleNote(midiNote: 0, velocity: 0, position: .zero, duration: .zero)
        super.init(coder: aDecoder)
        commonInit()
    }

    /// Default initilization function.
    private func commonInit() {
        backgroundColor = .green

        //        addSubview(resizeView)
        //        let resizeGesture = UIPanGestureRecognizer(target: self, action:
        //        #selector(didResize(pan:)))
        //        resizeView.addGestureRecognizer(resizeGesture)

        let moveGesture = UIPanGestureRecognizer(target: self, action: #selector(didMove(pan:)))
        addGestureRecognizer(moveGesture)

        tapGesture = UITapGestureRecognizer(target: self, action: #selector(didTap(tap:)))
        addGestureRecognizer(tapGesture)

        isUserInteractionEnabled = true
    }

    // MARK: Layout

    override func layoutSubviews() {
        super.layoutSubviews()
        resizeView.frame = CGRect(
            x: frame.size.width - resizingViewWidth,
            y: 0,
            width: resizingViewWidth,
            height: frame.size.height)
    }

    // MARK: Gestures

    @objc func didTap(tap: UITapGestureRecognizer) {
        delegate?.scaleEditCellViewDidTap(self)
    }

    @objc func didMove(pan: UIPanGestureRecognizer) {
        delegate?.scaleEditCellViewDidMove(self, pan: pan)
    }

    @objc func didResize(pan: UIPanGestureRecognizer) {
        delegate?.scaleEditCellViewDidResize(self, pan: pan)
    }
}
