//
//  TempoViewModel.swift
//  ScalePlayer
//
//  Created by John Shimmin on 12/29/22.
//  Copyright © 2022 shimmin. All rights reserved.
//

import UIKit

protocol TempoViewModelDelegate: AnyObject {
    func tempoDidChange(tempo: Int)
}

class TempoViewModel {
    @PublishedOnMain
    private(set) var tempo: Int {
        didSet {
            delegate?.tempoDidChange(tempo: tempo)
        }
    }

    weak var delegate: TempoViewModelDelegate?

    let tempoRange: (min: Float, max: Float) = (min: 30.0, max: 300.0)

    init(tempo: Int) {
        self.tempo = tempo
    }

    func updateTempo(_ tempo: Int) {
        self.tempo = tempo
    }
}
