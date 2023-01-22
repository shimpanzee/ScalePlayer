//
//  RoutineScaleTableViewCell.swift
//  ScalePlayer
//
//  Created by John Shimmin on 1/6/23.
//  Copyright © 2023 shimmin. All rights reserved.
//

import UIKit

class RoutineScaleTableViewCell: UITableViewCell, UITextFieldDelegate {
    @IBOutlet var nameLabel: UILabel!
    @IBOutlet var tempoField: UITextField!

    var scale: RoutineScale?

    override func awakeFromNib() {
        super.awakeFromNib()
    }

    func configureWith(scale: RoutineScale) {
        nameLabel.text = scale.scale!.name
        tempoField.text = String(scale.tempo)
        tempoField.delegate = self
        self.scale = scale
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
        scale!.tempo = Int16(tempoField.text!) ?? 0
    }

    func textField(
        _ textField: UITextField,
        shouldChangeCharactersIn range: NSRange,
        replacementString string: String) -> Bool {
        let newChars = CharacterSet(charactersIn: string)
        return CharacterSet.decimalDigits.isSuperset(of: newChars)
    }
}
