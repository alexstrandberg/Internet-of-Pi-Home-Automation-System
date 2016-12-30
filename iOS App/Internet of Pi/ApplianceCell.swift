//
//  ApplianceTableViewCell.swift
//  Internet of Pi
//
//  Created by Alex Strandberg on 12/21/16.
//  Copyright © 2016 Alex Strandberg. All rights reserved.
//

import UIKit

class ApplianceCell: UITableViewCell {
    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var applianceSwitch: UISwitch!
    @IBOutlet weak var onUntilLabel: UILabel!
    @IBOutlet weak var datePicker: UIDatePicker!
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var enabledSwitch: UISwitch!
    
    let datePickerHeightVisible: CGFloat = 216
    let editViewHeightVisible: CGFloat = 86
    
    var appliance: Appliance!
    
    var schedule: Schedule?

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        nameTextField.delegate = self
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    @IBAction func applianceSwitchChanged(_ sender: UISwitch) {
        appliance.state = appliance.state == 1 ? 0 : 1
        appliance.saveInBackground()
        if appliance.state == 0 {
            onUntilLabel.text = " "
        }
    }
    @IBAction func enableSwitchChanged(_ sender: UISwitch) {
        appliance.enabled = sender.isOn
        if !sender.isOn { // If appliance is disabled
            appliance.state = 0
            schedule = nil
        }
        appliance.saveInBackground()
        updateCell()
    }
    
    func updateCell() {
        if let appliance = appliance {
            self.nameLabel.text = appliance.name
            self.nameTextField.text = appliance.name
            self.applianceSwitch.setOn(appliance.state == 1, animated: true)
            self.enabledSwitch.setOn(appliance.enabled, animated: true)
            self.applianceSwitch.isEnabled = appliance.enabled
            
            if let schedule = schedule, let end = schedule.end.first {
                let formatter = DateFormatter()
                formatter.dateStyle = .none
                formatter.timeStyle = .medium
                onUntilLabel.text = "On Until: " + formatter.string(from: end)
                self.applianceSwitch.setOn(true, animated: true)
            } else {
                onUntilLabel.text = !appliance.enabled ? "Disabled" : " "
            }
        }
    }
}

extension ApplianceCell: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if let text = textField.text {
            textField.resignFirstResponder()
            appliance.name = text
            if text.characters.count > 16 { // Limit appliance names to 16 characters
                appliance.name = text.substring(to: text.index(text.startIndex, offsetBy: 16))
                textField.text = appliance.name
            }
            appliance.saveInBackground()
            updateCell()
        }
        return true
    }
}
