//
//  PerformScaleViewController.swift
//  ScalePlayer
//
//  Created by John Shimmin on 12/26/22.
//  Copyright © 2022 shimmin. All rights reserved.
//

import Combine
import Factory
import TinyConstraints
import UIKit

class PerformScaleViewController: UIViewController {

    private var beatWedges = [SimonWedgeView]()
    private var playbackSpritesView: PlaybackSpritesView?

    private var currentBeat: Int = 0 {
        didSet {
            configureBeatDisplay()
        }
    }

    private lazy var playbackSpritesLayoutGuide: UILayoutGuide = {
        let guide = UILayoutGuide()

        playbackView.addLayoutGuide(guide)

        guide.edges(to: playbackView, excluding: .bottom)
        guide.bottomToTop(of: noteLabel, offset: -30)

        return guide
    }()

    private lazy var tempoLayoutGuide: UILayoutGuide = {
        let guide = UILayoutGuide()

        playbackView.addLayoutGuide(guide)

        guide.edges(to: playbackView, excluding: [.top, .bottom])
        guide.topToBottom(of: noteLabel)
        guide.bottomToTop(of: toolbar)

        return guide
    }()

    private var toolbar: PerformScaleToolbar!
    // playback view includes a graphic visualization of the notes being performed,
    // the letter representation, as well as a visualizer for the beat.
    private let playbackView = UIView()
    private let nextButton = UIButton()
    private let noteLabel = UILabel()
    private var swipeUp: UISwipeGestureRecognizer!
    private var swipeDown: UISwipeGestureRecognizer!
    private var viewModel: PerformScaleViewModel

    private var subscriptions = Set<AnyCancellable>()

    init(viewModel: PerformScaleViewModel) {
        self.viewModel = viewModel

        super.init(nibName: nil, bundle: nil)

        toolbar = PerformScaleToolbar(viewModel: viewModel) { [weak self] in
            self?.showTempoModal()
        }
    }

    @available(*, unavailable)
    required init(coder: NSCoder) {
        fatalError("init(coder:) not implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .white

        navigationItem.title = viewModel.scale.name
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .done,
            target: self,
            action: #selector(done))
        nextButton.setImage(UIImage(systemName: "arrow.right"), for: .normal)
        nextButton.addTarget(self, action: #selector(nextScale), for: .touchUpInside)
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: nextButton)

        let guide = view.safeAreaLayoutGuide

        // Build toolbar view
        view.addSubview(toolbar)
        toolbar.edges(to: guide, excluding: .top)

        configurePlaybackView()
        configureViewModelSubscribers()

        swipeUp = UISwipeGestureRecognizer(target: self, action: #selector(swipe))
        swipeUp.direction = .up
        view.addGestureRecognizer(swipeUp)
        swipeDown = UISwipeGestureRecognizer(target: self, action: #selector(swipe))
        swipeDown.direction = .down
        view.addGestureRecognizer(swipeDown)
    }

    @objc func nextScale() {
        viewModel.nextScale()
    }

    @objc func swipe(_ sender: UISwipeGestureRecognizer) {
        if sender === swipeUp {
            viewModel.swipe(dir: 1)
        } else {
            viewModel.swipe(dir: -1)
        }
    }

    func configurePlaybackView() {
        let guide = view.safeAreaLayoutGuide

        view.addSubview(playbackView)

        playbackView.edges(to: guide, excluding: .bottom)
        playbackView.bottomToTop(of: toolbar)

        playbackView.layer.borderColor = UIColor.gray.cgColor
        playbackView.layer.borderWidth = 1

        playbackView.addSubview(noteLabel)
        noteLabel.font = .monospacedSystemFont(ofSize: 24, weight: .semibold)
        noteLabel.textColor = .gray
        noteLabel.text = "-"

        noteLabel.center(in: playbackView)

        beatWedges = [
            addWedgeView(color: .app.noteSpritePlaying, angle: 0),
            addWedgeView(color: .app.noteSprite, angle: 0.5 * .pi),
            addWedgeView(color: .app.noteSprite, angle: .pi),
            addWedgeView(color: .app.noteSprite, angle: 1.5 * .pi)
        ]

        for wedge in beatWedges {
            wedge.center(in: noteLabel)
            wedge.width(100)
            wedge.height(100)
        }
    }

    func addWedgeView(color: UIColor, angle: Radians) -> SimonWedgeView {
        let wedgeView = SimonWedgeView(frame: view.bounds)
        wedgeView.color = color
        wedgeView.centerAngle = angle
        view.addSubview(wedgeView)
        return wedgeView
    }

    private func configureBeatDisplay() {
        DispatchQueue.main.async { [weak self] in
            if let self = self {
                for (beat, wedge) in self.beatWedges.enumerated() {
                    wedge.color = beat == (self.currentBeat % 4) ? UIColor.app
                        .noteSpritePlaying : UIColor.app.noteSprite
                }
            }
        }
    }

    private func renderNotes() {
        playbackSpritesView?.removeFromSuperview()

        playbackSpritesView = PlaybackSpritesView(notes: viewModel.scale.notes)

        let playbackSpritesView = playbackSpritesView!
        playbackView.addSubview(playbackSpritesView)

        playbackSpritesView.edges(to: playbackSpritesLayoutGuide)
    }

    func configureViewModelSubscribers() {
        viewModel.$currentNoteIndex
            .sink { [weak self] index in
                self?.playbackSpritesView?.currentNoteIndex = index
            }
            .store(in: &subscriptions)

        viewModel.$shouldShowNextButton
            .sink { [weak self] shouldShowNextButton in
                self?.nextButton.isHidden = !shouldShowNextButton
            }
            .store(in: &subscriptions)

        viewModel.$isShowNextButtonEnabled
            .assign(to: \.nextButton.isEnabled, onWeak: self)
            .store(in: &subscriptions)

        viewModel.$scale
            .sink { [weak self] _ in
                if let self = self {
                    self.renderNotes()
                    self.navigationItem.title = self.viewModel.scale.name
                }
            }
            .store(in: &subscriptions)

        viewModel.$currentBeat
            .assign(to: \.currentBeat, onWeak: self)
            .store(in: &subscriptions)

        viewModel.$currentNoteName
            .sink { [weak self] in self?.noteLabel.text = $0 }
            .store(in: &subscriptions)
    }

    @objc func done() {
        parent?.dismiss(animated: true)
        viewModel.stop()
    }

    func showTempoModal() {
        let tempoView = viewModel.createTempoView(guide: tempoLayoutGuide)
        view.addSubview(tempoView)
    }
}
