//
//  AlarmCell.swift
//  Internet of Pi
//
//  Created by Alex Strandberg on 12/26/16.
//  Copyright © 2016 Alex Strandberg. All rights reserved.
//

import UIKit
import ATHMultiSelectionSegmentedControl

class AlarmCell: UITableViewCell {
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var dowLabel: UILabel!
    @IBOutlet weak var enabledSwitch: UISwitch!
    @IBOutlet weak var saveButton: UIButton!
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var repeatsSwitch: UISwitch!
    @IBOutlet weak var timePicker: UIDatePicker!
    @IBOutlet weak var daysMultiSelection: MultiSelectionSegmentedControl!
    
    var isNew: Bool = false {
        didSet {
            enabledSwitch.isEnabled = !isNew
        }
    }
    
    var alarm: Alarm! {
        didSet {
            updateCell()
        }
    }
    
    let dowLabels = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        daysMultiSelection.insertSegmentsWithTitles(dowLabels)
        daysMultiSelection.delegate = self
        toggleButtons(enabled: false)
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
        updateCell()
    }
    
    func toggleButtons(enabled: Bool) {
        saveButton.isEnabled = enabled && daysMultiSelection.selectedSegmentIndices.count != 0
        enabledSwitch.isEnabled = !isNew
        cancelButton.isEnabled = enabled
    }
    
    func updateCell() {
        enabledSwitch.isOn = alarm.enabled
        
        if let firstDate = alarm.when.first {
            timePicker.date = firstDate
            
            let formatter = DateFormatter()
            formatter.dateStyle = .none
            formatter.timeStyle = .short
            timeLabel.text = formatter.string(from: firstDate)
        }
        
        repeatsSwitch.isOn = alarm.repeats
        if alarm.when.count > 1 {
            repeatsSwitch.isEnabled = false
        }
        
        dowLabel.text = repeatsSwitch.isOn ? "Every " : "On "
        var isFirst = true
        if !alarm.when.isEmpty {
            daysMultiSelection.selectedSegmentIndices = []
        }
        for date in alarm.when {
            if isFirst {
                isFirst = false
            } else {
                dowLabel.text = dowLabel.text! + ", "
            }
            let gregorianCalendar = NSCalendar(calendarIdentifier: NSCalendar.Identifier.gregorian)!
            let components = gregorianCalendar.components(.weekday, from: date)
            daysMultiSelection.selectedSegmentIndices.append(components.weekday!-1) // Sunday is at position 0 in segmented list
            dowLabel.text = dowLabel.text! + dowLabels[components.weekday!-1]
        }
        
        // Handle new Alarm - no info yet
        if dowLabel.text == "Every " || dowLabel.text == "On " {
            timeLabel.text = "New Alarm"
            dowLabel.text = " "
        }
    }
    
    @IBAction func enabledSwitchChanged(_ sender: UISwitch) {
        alarm.enabled = sender.isOn
        alarm.saveInBackground()
    }
    
    @IBAction func repeatsSwitchChanged(_ sender: UISwitch) {
        toggleButtons(enabled: true)
    }
    
    @IBAction func saveTapped(_ sender: UIButton) {
        var newDates: [Date] = []
        
        let date: Date = Date()
        let cal = Calendar(identifier: .gregorian)
        
        let whenDate: Date = cal.date(bySettingHour: cal.component(.hour, from: timePicker.date), minute: cal.component(.minute, from: timePicker.date), second: 0, of: date)!
        
        for index in daysMultiSelection.selectedSegmentIndices {
            let nextDow = getNextDow(startingFrom: whenDate, dowIndex: index+1)!
            if Date().compare(nextDow) == .orderedDescending { // Check case if alarm time is set for today's day of week (ex: Monday) at an earlier time - change to next Monday
                var dayComponent = DateComponents()
                dayComponent.day = 1
                newDates.append(getNextDow(startingFrom: cal.date(byAdding: dayComponent, to: whenDate)!, dowIndex: index+1)!)
            } else {
                newDates.append(nextDow)
            }
        }
        
        alarm.when = newDates
        alarm.repeats = repeatsSwitch.isOn
        
        alarm.saveInBackground()
        
        isNew = false
        
        toggleButtons(enabled: false)
        
        updateCell()
    }
    
    @IBAction func cancelTapped(_ sender: UIButton) {
        updateCell()
        toggleButtons(enabled: false)
    }

    @IBAction func timePickerChanged(_ sender: UIDatePicker) {
        toggleButtons(enabled: true)
    }
    
    func getNextDow(startingFrom date: Date, dowIndex: Int) -> Date? {
        let gregorianCalendar = NSCalendar(calendarIdentifier: NSCalendar.Identifier.gregorian)!
        
        //Sunday == 1, Saturday == 7
        let currentWeekday = gregorianCalendar.component(NSCalendar.Unit.weekday, from: date)
        let daysUntilNextDow = (dowIndex + 7 - currentWeekday) % 7
        
        var dayAddComponent = DateComponents()
        dayAddComponent.day = daysUntilNextDow
        return gregorianCalendar.date(byAdding: dayAddComponent, to: date, options: [])
    }
}

extension AlarmCell: MultiSelectionSegmentedControlDelegate {
    func multiSelectionSegmentedControl(_ control: MultiSelectionSegmentedControl, selectedIndices indices: [Int]) {
        if indices.count > 1 { // Can't have non-repeating alarm if multiple days are selected
            repeatsSwitch.isOn = true
            repeatsSwitch.isEnabled = false
        } else {
            repeatsSwitch.isEnabled = true
        }
        toggleButtons(enabled: true)
    }
}
