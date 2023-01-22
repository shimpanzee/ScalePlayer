//
//  ScaleEditView.swift
//  ScalePlayer
//
//  Copyright © 2022 shimmin. All rights reserved.
//

import AudioToolbox
import Combine
import MusicTheorySwift
import OSLog
import UIKit

//
// This class needs some refactoring to get to a more manageable/testable
// size.
//
// swiftlint:disable file_length
//

/// scale edit grid with customisable row count, row range, beat count and editable note cells.
class ScaleEditView: UIScrollView {
    private var noteViewMap: [ScaleNote: ScaleEditCellView] = [:]
    private var subscriptions = Set<AnyCancellable>()

    /// Rendering note range of the scale edit grid. Defaults all MIDI notes, from 0 to 127.
    var keys: Keys = .ranged(0 ... 127) { didSet { reload() }}

    private var viewModel: ScaleEditViewModel

    /// Current `ZoomLevel` of the scale edit grid.
    private var zoomLevel: ZoomLevel = .quarterNotes
    /// Current with of a beat on the measure.
    private var beatWidth: CGFloat = 30
    /// Fixed left hand side row width on the scale edit grid.
    private var rowWidth: CGFloat = 60
    /// Current height of a row on the scale edit grid.
    private var rowHeight: CGFloat = 40

    /// Fixed height of the bar on the top.
    let measureHeight: CGFloat = 20
    /// Minimum amount of the zoom level.
    let minZoomLevel: ZoomLevel = .wholeNotes
    /// Maximum amount of the zoom level.
    let maxZoomLevel: ZoomLevel = .thirtysecondNotes
    /// Speed of zooming by pinch gesture.
    let zoomSpeed: CGFloat = 0.4
    /// Maximum width of a beat on the bar, max zoomed in.
    let maxBeatWidth: CGFloat = 40
    /// Minimum width of a beat on the bar, max zoomed out.
    let minBeatWidth: CGFloat = 20
    /// Maximum height of a row on the scale edit grid.
    let maxRowHeight: CGFloat = 80
    /// Minimum height of a row on the scale edit grid.
    let minRowHeight: CGFloat = 30

    /// Label configuration for the measure beat labels.
    private let measureLabelConfig = UILabel()

    /// Layer that cells drawn on. Lowest layer.
    private let cellLayer = UIView()
    /// Reference of the all cell views.
    private var cellViews: [ScaleEditCellView] = []
    private var underConstructionCellView: ScaleEditCellView?

    /// Layer that grid drawn on. Middle low layer.
    private(set) var gridLayer = GridLayerView()
    /// Reference of the all horizontal grid lines.
    private var verticalGridLines: [CAShapeLayer] = []
    /// Reference of the all horizontal grid lines.
    private var horizontalGridLines: [CAShapeLayer] = []

    let beatCursor = BeatCursor()

    /// Layer that rows drawn on. Middle top layer.
    private(set) var rowLabelsView = UIView()
    /// Reference of the all row views.
    private var rowViews: [ScaleEditRowView] = []
    /// Reference of the line drawn on the right side between rows and scale grid.
    private var rowLine = CAShapeLayer()

    /// Layer that measure drawn on. Top most layer.
    var measureHeaderView = UIView()
    /// Line layer that drawn under the measure.
    private var measureBottomLine = CAShapeLayer()
    /// Reference of the all vertical measure beat lines.
    private var measureLines: [ScaleEditMeasureLineLayer] = []

    /// The last bar by notes position and duration. Updates on cells notes array change.
    private var lastBar: Int = 0

    /// Reference for controlling bar line redrawing in layoutSubview function.
    private var needsRedrawBar: Bool = false {
        didSet {
            if needsRedrawBar {
                setNeedsLayout()
            }
        }
    }

    private var zoomGesture = UIPinchGestureRecognizer()
    private var paintGestureRecognizer = StrokeGestureRecognizer()

    // MARK: Init

    /// Initilizes the scale edit grid with a frame.
    ///
    /// - Parameter frame: Frame of the view.
    init(viewModel: ScaleEditViewModel) {
        self.viewModel = viewModel
        super.init(frame: .zero)
        configureViews()
        configureGestures()
        configureSubscriptions()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension ScaleEditView {
    // MARK: Setup

    private func configureSubscriptions() {
        viewModel.$notes
            .dropFirst()
            .sink { [weak self] _ in self?.reload() }
            .store(in: &subscriptions)

        viewModel.$timeSignature
            .dropFirst()
            .sink { [weak self] _ in self?.reload() }
            .store(in: &subscriptions)

        viewModel.$isPlaying
            .combineLatest(viewModel.$tool)
            .map { isPlaying, tool in !isPlaying && tool == .paintbrush }
            .assign(to: \.paintGestureRecognizer.isEnabled, onWeak: self)
            .store(in: &subscriptions)

        viewModel.$barCount
            .sink { [weak self] _ in
                if let self = self {
                    self.needsRedrawBar = true
                    self.layoutIfNeeded()
                }
            }
            .store(in: &subscriptions)

        viewModel.$currentPlayingNote
            .sink { [weak self] note in
                if let self = self {
                    // TODO: optimize this so we don't walk through every note.  This
                    // isn't currently a performance problem, but it doesn't smell right
                    for (n, view) in self.noteViewMap {
                        view.backgroundColor = (n == note) ? .red : .green
                    }
                }
            }
            .store(in: &subscriptions)

        viewModel.$currentBeat
            .sink { [weak self] beat in
                if let self = self {
                    if let beat = beat {
                        self.beatCursor.showAt(x: self.beatWidth * CGFloat(beat))
                    } else {
                        self.beatCursor.isHidden = true
                    }
                }
            }
            .store(in: &subscriptions)
    }

    private func configureViews() {
        ScaleEditView.GridLine.rowVertical.color = .lightGray
        ScaleEditView.GridLine.rowVertical.width = 4
        measureHeaderView.backgroundColor = .white

        // Setup layers
        addSubview(cellLayer)
        addSubview(gridLayer)
        addSubview(rowLabelsView)
        addSubview(measureHeaderView)

        gridLayer.layer.addSublayer(beatCursor)

        gridLayer.isUserInteractionEnabled = true
    }

    private func configureGestures() {
        // Setup pinch gesture
        zoomGesture.addTarget(self, action: #selector(didZoom(pinch:)))
        addGestureRecognizer(zoomGesture)

        panGestureRecognizer.minimumNumberOfTouches = 2
        panGestureRecognizer.maximumNumberOfTouches = 2

        paintGestureRecognizer.addTarget(self, action: #selector(strokeUpdated(_:)))
        addGestureRecognizer(paintGestureRecognizer)
    }

    @IBAction func clearGrid(_ sender: Any) {
        viewModel.clearSequence()
    }
}

extension ScaleEditView: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        Logger.app
            .debug(
                "scrollViewDidScroll  offset:\(scrollView.contentOffset.x)  width:\(scrollView.frame.size.width)")
        if scrollView.contentOffset.x >= scrollView.contentSize.width - scrollView.frame.size.width {
            Logger.app.debug("Reached end of scroll!")
            viewModel.addMeasure()
        }
    }
}

extension ScaleEditView {
    // MARK: Utils

    func noteForGesture(_ strokeGesture: StrokeGestureRecognizer) -> ScaleNote {
        let pitch = pitch(for: strokeGesture.startLoc.y - gridLayer.frame.origin.y)

        var positions = [
            notePosition(for: strokeGesture.startLoc.x - rowWidth),
            notePosition(for: strokeGesture.endLoc.x - rowWidth)
        ]
        positions.sort()
        let s = positions[0]
        let e = positions[1]
        let sPos = ScaleNotePosition(bar: s.bar, beat: s.beat, subbeat: s.subbeat, cent: 0)
        let ePos = ScaleNotePosition(bar: e.bar, beat: e.beat, subbeat: e.subbeat, cent: 0)

        var duration = ePos - sPos
        if duration == .zero {
            duration = ScaleNotePosition(bar: 0, beat: 0, subbeat: 1, cent: 0)
        }

        let note = ScaleNote(
            midiNote: pitch,
            velocity: 90,
            position: sPos,
            duration: duration)

        return note
    }

    /// Returns a `ScaleEditPosition`'s x-position on the screen.
    ///
    /// - Parameters:
    ///   - notePosition: scale edit grid position that you want to get its x-position on the
    /// screen.
    ///   - barWidth: Optional bar width. Pre-calculate it if you are using this in a loop. Defaults
    /// nil.
    ///   - beatWidth: Optional beat width. Pre-calculate it if you are using this in a loop.
    /// Defaults nil.
    ///   - subbeatWidth: Optional subbeat width. Pre-calculate it if you are using this in a loop.
    /// Defaults nil.
    ///   - centWidth: Optional cent width. Pre-calculate it if you are using this in a loop.
    /// Defaults nil.
    /// - Returns: Returns the `ScaleEditPosition`'s x-position on the screen.
    private func gridPosition(
        with notePosition: ScaleNotePosition,
        barWidth: CGFloat? = nil,
        beatWidth: CGFloat? = nil,
        subbeatWidth: CGFloat? = nil,
        centWidth: CGFloat? = nil) -> CGFloat {
        let bars = CGFloat(notePosition.bar) *
            (barWidth ??
                ((self.beatWidth * CGFloat(zoomLevel.rawValue) / 4.0) *
                    CGFloat(viewModel.timeSignature.beats)))
        let beats = CGFloat(notePosition.beat) *
            (beatWidth ?? self.beatWidth * CGFloat(zoomLevel.rawValue) / 4.0)
        let subbeats = CGFloat(notePosition.subbeat) *
            (subbeatWidth ??
                ((self.beatWidth * CGFloat(zoomLevel.rawValue) / 4.0) *
                    CGFloat(zoomLevel.rawValue) /
                    4.0))
        let cents = CGFloat(notePosition.cent) *
            (centWidth ?? (((self.beatWidth * CGFloat(zoomLevel.rawValue) / 4.0) / 4.0) / 240.0))
        return bars + beats + subbeats + cents
    }

    /// Returns the `ScaleEditPosition` of a x-position on the screen.
    ///
    /// - Parameter point: x-position on the screen that you want to get `ScaleEditPosition`.
    /// - Returns: Returns the `ScaleEditPosition` value of a position on the grid.
    private func notePosition(for point: CGFloat) -> ScaleNotePosition {
        // Calculate measure widths
        let normalizedBeatWidth = beatWidth * CGFloat(zoomLevel.rawValue) / 4.0
        let barWidth = normalizedBeatWidth * CGFloat(viewModel.timeSignature.beats)
        let subbeatWidth = normalizedBeatWidth / 4.0
        let centWidth = subbeatWidth / 240.0

        // Calculate new position
        var position = point
        let bars = position / barWidth
        position -= CGFloat(Int(bars)) * barWidth
        let beats = position / normalizedBeatWidth
        position -= CGFloat(Int(beats)) * normalizedBeatWidth
        let subbeats = position / subbeatWidth
        position -= CGFloat(Int(subbeats)) * subbeatWidth
        let cents = position / centWidth

        return ScaleNotePosition(
            bar: Int(bars),
            beat: Int(beats),
            subbeat: Int(subbeats),
            cent: Int(cents))
    }

    /// Returns the start `ScaleEditPosition` of a cell.
    ///
    /// - Parameter cell: The cell that you want to get `ScaleEditPosition`.
    /// - Returns: Returns the `ScaleEditPosition` value of a position on the grid.
    private func notePosition(for cell: ScaleEditCellView) -> ScaleNotePosition {
        let point = cell.frame.origin.x
        return notePosition(for: point)
    }

    /// Calculates the duration of a `ScaleEditCellView` in `ScaleEditPosition` units calculated by
    /// the cell's width.
    ///
    /// - Parameter cell: Cell that you want to calculate its duration.
    /// - Returns: Returns the duration of a cell in `ScaleEditPosition`.
    private func noteDuration(for cell: ScaleEditCellView) -> ScaleNotePosition {
        // Calculate measure widths
        let normalizedBeatWidth = beatWidth * CGFloat(zoomLevel.rawValue) / 4.0
        let barWidth = normalizedBeatWidth * CGFloat(viewModel.timeSignature.beats)
        let subbeatWidth = normalizedBeatWidth / 4.0
        let centWidth = subbeatWidth / 240.0

        // Calculate new position
        var width = cell.frame.size.width
        let bars = width / barWidth
        width -= CGFloat(Int(bars)) * barWidth
        let beats = width / normalizedBeatWidth
        width -= CGFloat(Int(beats)) * normalizedBeatWidth
        let subbeats = width / subbeatWidth
        width -= CGFloat(Int(subbeats)) * subbeatWidth
        let cents = width / centWidth

        return ScaleNotePosition(
            bar: Int(bars),
            beat: Int(beats),
            subbeat: Int(subbeats),
            cent: Int(cents))
    }

    /// Returns the corresponding pitch of a row on a y-position on the screeen.
    ///
    /// - Parameter point: y-position on the screen that you want to get the pitch on that row.
    /// - Returns: Returns the pitch of the row at a y-point.
    private func pitch(for point: CGFloat) -> UInt8 {
        let index = Int(point / rowHeight)
        return rowViews.indices.contains(index) ? UInt8(rowViews[index].pitch.rawValue) : 0
    }

    /// Returns the corresponding pitch of a row that a cell on.
    ///
    /// - Parameter cell: The cell you want to get the pitch of the row which the cell is on.
    /// - Returns: Returns the pitch of the row that the cell on.
    private func pitch(for cell: ScaleEditCellView) -> UInt8 {
        let point = cell.frame.origin.y
        return pitch(for: point)
    }
}

extension ScaleEditView {
    // MARK: Gestures

    @objc
    func strokeUpdated(_ strokeGesture: StrokeGestureRecognizer) {
        switch strokeGesture.state {
        case .changed:
            if let cellView = underConstructionCellView {
                cellView.removeFromSuperview()
                cellViews.removeLast() // fix me
                underConstructionCellView = nil
            }

            let note = noteForGesture(strokeGesture)

            underConstructionCellView = addNoteView(note)
            setNeedsLayout()
            layoutIfNeeded()

        case .ended:
            Logger.gestures.debug("strokeUpdated.ended")
            if let cellView = underConstructionCellView {
                cellView.removeFromSuperview()
                cellViews.removeLast() // fix me
                underConstructionCellView = nil
            }

            let note = noteForGesture(strokeGesture)

            viewModel.addNote(note)

        case .began:
            Logger.gestures.debug("strokeUpdated.began")
            let r = notePosition(for: strokeGesture.startLoc.x - rowWidth)
            let rollPosition = ScaleNotePosition(
                bar: r.bar,
                beat: r.beat,
                subbeat: r.subbeat,
                cent: 0)
            let pitch = pitch(for: strokeGesture.startLoc.y - gridLayer.frame.origin.y)

            let note = ScaleNote(
                midiNote: pitch,
                velocity: 90,
                position: rollPosition,
                duration: ScaleNotePosition(bar: 0, beat: 0, subbeat: 1, cent: 0))
            underConstructionCellView = addNoteView(note)
            setNeedsLayout()
            layoutIfNeeded()
        case .possible, .cancelled, .failed:
            break
        @unknown default:
            fatalError()
        }
    }

    /// Gets called when pinch gesture triggers.
    ///
    /// - Parameter pinch: The pinch gesture.
    @objc private func didZoom(pinch: UIPinchGestureRecognizer) {
        guard [.began, .changed].contains(pinch.state) &&  pinch.numberOfTouches == 2 else {
            return
        }

        // Calculate pinch direction.
        let t1 = pinch.location(ofTouch: 0, in: self)
        let t2 = pinch.location(ofTouch: 1, in: self)
        let xD = abs(t1.x - t2.x)
        let yD = abs(t1.y - t2.y)
        var isVerticalZooming = true
        if yD == 0 {
            isVerticalZooming = false
        } else {
            let ratio = xD / yD
            if ratio > 2 { isVerticalZooming = false }
            if ratio < 0.5 { isVerticalZooming = true }
        }

        var scale = ((pinch.scale - 1) * zoomSpeed) + 1

        if isVerticalZooming {
            scale = min(scale, maxRowHeight / rowHeight)
            scale = max(scale, minRowHeight / rowHeight)
            rowHeight *= scale
            setNeedsLayout()
        } else { // Horizontal zooming
            scale = min(scale, maxBeatWidth / beatWidth)
            scale = max(scale, minBeatWidth / beatWidth)
            beatWidth *= scale
            setNeedsLayout()

            // Get in new zoom level.
            if beatWidth >= maxBeatWidth {
                if let zoom = zoomLevel.zoomedIn, zoom != maxZoomLevel.zoomedIn {
                    zoomLevel = zoom
                    beatWidth = minBeatWidth
                    needsRedrawBar = true
                }
            } else if beatWidth <= minBeatWidth {
                if let zoom = zoomLevel.zoomedOut, zoom != minZoomLevel.zoomedOut {
                    zoomLevel = zoom
                    beatWidth = maxBeatWidth
                    needsRedrawBar = true
                }
            }
        }
        pinch.scale = 1
    }

    // MARK: Multiple Editing

    /// Gets called when pan gesture triggered.
    ///
    /// - Parameter pan: The pan gesture.
    @objc private func didDrag(pan: UIPanGestureRecognizer) {}
}

extension ScaleEditView: ScaleEditCellViewDelegate {
    func scaleEditCellViewDidMove(
        _ scaleEditCellView: ScaleEditCellView,
        pan: UIPanGestureRecognizer) {}

    func scaleEditCellViewDidResize(
        _ scaleEditCellView: ScaleEditCellView,
        pan: UIPanGestureRecognizer) {}

    func scaleEditCellViewDidTap(_ scaleEditCellView: ScaleEditCellView) {
        if viewModel.tool == .eraser {
            viewModel.removeNote(scaleEditCellView.note)
        }
    }

    func scaleEditCellViewDidDelete(_ scaleEditCellView: ScaleEditCellView) {}
}

extension ScaleEditView {
    // MARK: Rendering

    override func layoutSubviews() {
        super.layoutSubviews()
        CATransaction.begin()
        CATransaction.setDisableActions(true)

        layoutMainLayers()
        layoutRowLines()

        // Layout left row line
        rowLine.path = UIBezierPath.verticalLine(
            x: rowWidth,
            y: contentOffset.y - measureHeaderView.frame.height,
            length: rowLabelsView.frame.height)
        rowLine.lineWidth = GridLine.rowVertical.width

        // Check if needs redraw measure lines.
        resetMeasureViewsIfNeeded()

        layoutTimeLines()

        layoutCells()

        beatCursor.updateDimensions(x: 0, y: contentOffset.y, width: beatWidth, height: gridLayer.frame.height)

        CATransaction.commit()
    }

    func layoutTimeLines() {
        // Layout measure and vertical lines.
        var currentX: CGFloat = 0
        for (index, measureLine) in measureLines.enumerated() {
            let gridLine = GridLine(from: measureLine.linePosition) ?? .default
            measureLine.frame = CGRect(
                x: currentX,
                y: 0,
                width: gridLine.width,
                height: measureHeight)

            // Layout measure line
            measureLine.lineLayer.path = UIBezierPath.verticalLine(x: 0, y: 0, length: measureLine.frame.height)
            measureLine.lineLayer.lineWidth = gridLine.width

            // Layout measure text
            let measureTextOffset: CGFloat = 2
            measureLine.textLayer.frame = CGRect(
                x: measureTextOffset,
                y: measureHeight - GridLine.measureText.width - measureTextOffset,
                width: beatWidth - measureTextOffset,
                height: GridLine.measureText.width + measureTextOffset)

            // Layout vertical grid line
            verticalGridLines[index].path = UIBezierPath.verticalLine(x: currentX, y: contentOffset.y, length: gridLayer.frame.height)
            verticalGridLines[index].lineWidth = gridLine.width

            currentX += beatWidth
        }

        // Layout measure bottom line
        measureBottomLine.path = UIBezierPath.horizontalLine(
            x: contentOffset.x - rowWidth,
            y: measureHeaderView.frame.height,
            length: measureHeaderView.frame.width)
        measureBottomLine.lineWidth = GridLine.measureBottom.width

        // Update content size horizontally
        contentSize.width = currentX + rowWidth
    }

    func layoutMainLayers() {
        let contentFrame = contentSize != .zero ? CGRect(origin: .zero, size: contentSize) : frame

        cellLayer.frame = CGRect(
            x: rowWidth,
            y: measureHeight,
            width: contentFrame.size.width - rowWidth,
            height: contentFrame.size.height - measureHeight)

        gridLayer.frame = CGRect(
            x: rowWidth,
            y: measureHeight,
            width: contentFrame.size.width - rowWidth,
            height: contentFrame.size.height - measureHeight)

        rowLabelsView.frame = CGRect(
            x: contentOffset.x,
            y: measureHeight,
            width: rowWidth,
            height: contentFrame.size.height)

        measureHeaderView.frame = CGRect(
            x: rowWidth,
            y: contentOffset.y,
            width: contentFrame.size.width - rowWidth,
            height: measureHeight)
    }

    func layoutRowLines() {
        // Layout rows
        var currentY: CGFloat = 0
        for (index, rowView) in rowViews.enumerated() {
            // Layout row
            rowView.frame = CGRect(x: 0, y: currentY, width: rowWidth, height: rowHeight)

            // Layout horizontal line
            horizontalGridLines[index].path = UIBezierPath.horizontalLine(
                x: contentOffset.x, y: currentY, length: gridLayer.frame.width)

            horizontalGridLines[index].lineWidth = GridLine.rowHorizontal.width
            horizontalGridLines[index].strokeColor = UIColor.blue.cgColor

            // Go to next row.
            currentY += rowHeight
        }

        // Layout bottom row horizontal line
        horizontalGridLines.last?.path = UIBezierPath.horizontalLine(
            x: contentOffset.x, y: currentY, length: gridLayer.frame.width)
        horizontalGridLines.last?.lineWidth = GridLine.rowHorizontal.width

        // Update content size vertically
        contentSize.height = currentY + measureHeaderView.frame.height
    }

    func layoutCells() {
        let normalizedBeatWidth = beatWidth * CGFloat(zoomLevel.rawValue) / 4.0
        let barWidth = normalizedBeatWidth * CGFloat(viewModel.timeSignature.beats)
        let subbeatWidth = normalizedBeatWidth / 4.0
        let centWidth = subbeatWidth / 240.0
        for cell in cellViews {
            guard let row = rowViews.filter({ $0.pitch.rawValue == cell.note.midiNote }).first
            else { continue }

            let startPosition = gridPosition(
                with: cell.note.position,
                barWidth: barWidth,
                beatWidth: normalizedBeatWidth,
                subbeatWidth: subbeatWidth,
                centWidth: centWidth)
            let endPosition = gridPosition(
                with: cell.note.position + cell.note.duration,
                barWidth: barWidth,
                beatWidth: normalizedBeatWidth,
                subbeatWidth: subbeatWidth,
                centWidth: centWidth)
            let cellWidth = endPosition - startPosition

            cell.frame = CGRect(
                x: startPosition,
                y: row.frame.origin.y,
                width: cellWidth,
                height: rowHeight)
        }
    }

    func resetMeasureViewsIfNeeded() {
        guard needsRedrawBar else {
            return
        }

        // Reset measure
        measureLines.forEach { $0.removeFromSuperlayer() }
        measureLines = []
        // Reset vertical lines
        verticalGridLines.forEach { $0.removeFromSuperlayer() }
        verticalGridLines = []

        // Reset bottom measure line
        measureBottomLine.removeFromSuperlayer()
        measureHeaderView.layer.addSublayer(measureBottomLine)
        measureBottomLine.strokeColor = GridLine.measureBottom.color.cgColor
        measureBottomLine.lineDashPattern = GridLine.measureBottom.dashPattern
        measureBottomLine.contentsScale = UIScreen.main.scale

        let renderingTexts = zoomLevel.renderingMeasureTexts

        // Create lines
        let lineCount = viewModel.barCount * zoomLevel.rawValue
        var linePosition: ScaleNotePosition = .zero
        for _ in 0 ... lineCount {
            // Create measure line
            let measureLine = ScaleEditMeasureLineLayer()
            let gridLine = GridLine(from: linePosition) ?? .default
            measureLine.linePosition = linePosition
            measureLine.lineLayer.strokeColor = gridLine.color.cgColor
            measureLine.lineLayer.lineDashPattern = gridLine.dashPattern
            measureLine.lineLayer.contentsScale = UIScreen.main.scale
            measureHeaderView.layer.addSublayer(measureLine)
            measureLines.append(measureLine)

            // Decide if render measure text.
            if let lineNoteValue = linePosition.noteValue,
               renderingTexts.contains(where: { $0.type == lineNoteValue.type }) {
                measureLine.showsBeatText = true
                measureLine.textLayer.foregroundColor = GridLine.measureText.color.cgColor
                measureLine.textLayer.fontSize = GridLine.measureText.width
            } else {
                measureLine.showsBeatText = false
            }

            // Draw beat text
            if measureLine.showsBeatText {
                measureLine.textLayer.string = "\(linePosition)"
            }

            // Create vertical grid line under the measure
            let verticalLine = CAShapeLayer()
            verticalLine.strokeColor = gridLine.color.cgColor
            verticalLine.lineDashPattern = gridLine.dashPattern
            verticalLine.contentsScale = UIScreen.main.scale
            verticalGridLines.append(verticalLine)
            gridLayer.layer.addSublayer(verticalLine)

            // Go next line
            // swiftlint:disable shorthand_operator
            linePosition = linePosition + zoomLevel.noteValue.noteDuration
            // swiftlint:enable shorthand_operator
        }

        needsRedrawBar = false
    }

    /// Removes each component and creates them again.
    func reload() {
        self.lastBar = self.viewModel.lastBar

        // Reset row views.
        rowViews.forEach { $0.removeFromSuperview() }
        rowViews = []
        // Reset row line
        rowLine = CAShapeLayer()
        rowLine.lineDashPattern = GridLine.rowVertical.dashPattern
        rowLine.strokeColor = GridLine.rowVertical.color.cgColor
        rowLine.contentsScale = UIScreen.main.scale
        rowLabelsView.layer.addSublayer(rowLine)
        // Reset horizontal lines
        horizontalGridLines.forEach { $0.removeFromSuperlayer() }
        horizontalGridLines = []
        // Reset cell views.
        cellViews.forEach { $0.removeFromSuperview() }
        cellViews = []

        // Setup cell views.
        for note in viewModel.notes {
            noteViewMap[note] = addNoteView(note)
        }

        // Setup row views.
        for pitch in keys.pitches {
            let rowView = ScaleEditRowView(pitch: pitch)
            rowLabelsView.addSubview(rowView)
            rowViews.append(rowView)
            // Setup horizontal lines.
            let line = CAShapeLayer()
            line.strokeColor = GridLine.rowHorizontal.color.cgColor
            line.lineDashPattern = GridLine.rowHorizontal.dashPattern
            line.contentsScale = UIScreen.main.scale
            gridLayer.layer.addSublayer(line)
            horizontalGridLines.append(line)
        }

        // Setup bottom horizontal line.
        let bottomRowLine = CAShapeLayer()
        bottomRowLine.strokeColor = GridLine.rowHorizontal.color.cgColor
        bottomRowLine.lineDashPattern = GridLine.rowHorizontal.dashPattern
        bottomRowLine.contentsScale = UIScreen.main.scale
        gridLayer.layer.addSublayer(bottomRowLine)
        horizontalGridLines.append(bottomRowLine)

        let barWidth = beatWidth * CGFloat(viewModel.timeSignature.beats)
        if CGFloat(lastBar + 1) * barWidth < max(frame.size.width, frame.size.height) {
            lastBar = Int(ceil(Double(frame.size.width / barWidth)) + 1)
        }

        needsRedrawBar = true
        setNeedsLayout()
        layoutIfNeeded()
    }

    func addNoteView(_ note: ScaleNote) -> ScaleEditCellView {
        let cellView = ScaleEditCellView(note: note)
        cellView.delegate = self
        cellLayer.addSubview(cellView)
        cellViews.append(cellView)

        return cellView
    }
}
