//
//  ActionCell.swift
//  Internet of Pi
//
//  Created by Alex Strandberg on 12/27/16.
//  Copyright © 2016 Alex Strandberg. All rights reserved.
//

import UIKit

class ActionCell: UITableViewCell {
    @IBOutlet weak var actionLabel: UILabel!
    @IBOutlet weak var eventLabel: UILabel!
    @IBOutlet weak var enabledSwitch: UISwitch!
    @IBOutlet weak var saveButton: UIButton!
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var stateSegmentedControl: UISegmentedControl!
    @IBOutlet weak var appliancePicker: UIPickerView!
    @IBOutlet weak var eventPicker: UIPickerView!
    
    var isNew: Bool = false {
        didSet {
            enabledSwitch.isEnabled = !isNew
        }
    }
    
    var action: Action! {
        didSet {
            updateCell()
        }
    }
    
    var appliances: [Appliance]! {
        didSet {
            appliancePicker.reloadAllComponents()
        }
    }
    
    let eventPickerNames = ["Door Is Opened", "Door Is Closed", "Foot Switch Is Pressed", "Light Exceeds Threshold", "Light Falls Below Threshold", "Temperature Exceeds Threshold", "Temperature Falls Below Threshold", "Humidity Exceeds Threshold", "Humidity Falls Below Threshold"]

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        toggleButtons(enabled: false)
        appliancePicker.delegate = self
        appliancePicker.dataSource = self
        eventPicker.delegate = self
        eventPicker.dataSource = self
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
        updateCell()
    }
    
    func toggleButtons(enabled: Bool) {
        saveButton.isEnabled = enabled
        enabledSwitch.isEnabled = !isNew
        cancelButton.isEnabled = enabled
    }
    
    func updateCell() {
        if !isNew {
            actionLabel.text = "Turn " + action.appliance.name + (action.state == 1 ? " On" : " Off")
            eventLabel.text = "When " + action.event
        } else {
            actionLabel.text = "New Action"
            eventLabel.text = " "
        }
        
        enabledSwitch.isOn = action.enabled
        stateSegmentedControl.selectedSegmentIndex = action.state
        
        var applianceRow = 0
        for x in 0..<appliances.count {
            if appliances[x].applianceId == action.appliance.applianceId {
                applianceRow = x
                break
            }
        }
        
        appliancePicker.selectRow(applianceRow, inComponent: 0, animated: true)
        
        if let eventRow = eventPickerNames.index(of: action.event) {
            eventPicker.selectRow(eventRow, inComponent: 0, animated: true)
        }
    }
    
    @IBAction func enabledSwitchChanged(_ sender: UISwitch) {
        action.enabled = sender.isOn
        action.saveInBackground()
    }
    
    @IBAction func stateSegmentedControlChanged(_ sender: UISegmentedControl) {
        toggleButtons(enabled: true)
    }
    
    @IBAction func saveTapped(_ sender: UIButton) {
        action.state = stateSegmentedControl.selectedSegmentIndex
        action.appliance = appliances[appliancePicker.selectedRow(inComponent: 0)]
        action.event = eventPickerNames[eventPicker.selectedRow(inComponent: 0)]
        action.saveInBackground()
        
        isNew = false
        
        toggleButtons(enabled: false)
        
        updateCell()
    }
    
    @IBAction func cancelTapped(_ sender: UIButton) {
        updateCell()
        toggleButtons(enabled: false)
    }
    
}

extension ActionCell: UIPickerViewDelegate {
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        toggleButtons(enabled: true)
    }
}

extension ActionCell: UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        if pickerView == appliancePicker {
            return appliances.count
        } else { // eventPicker
            return eventPickerNames.count
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        if pickerView == appliancePicker {
            return appliances[row].name
        } else { // eventPicker
            return eventPickerNames[row]
        }
    }
}
