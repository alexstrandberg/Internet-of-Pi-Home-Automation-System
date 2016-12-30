//
//  ScheduleCell.swift
//  Internet of Pi
//
//  Created by Alex Strandberg on 12/24/16.
//  Copyright © 2016 Alex Strandberg. All rights reserved.
//

import UIKit
import ATHMultiSelectionSegmentedControl

class ScheduleCell: UITableViewCell {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    @IBOutlet weak var enabledSwitch: UISwitch!
    @IBOutlet weak var saveButton: UIButton!
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var startTimePicker: UIDatePicker!
    @IBOutlet weak var endTimePicker: UIDatePicker!
    @IBOutlet weak var daysMultiSelection: MultiSelectionSegmentedControl!
    @IBOutlet weak var appliancePicker: UIPickerView!
    
    var isNew: Bool = false {
        didSet {
            enabledSwitch.isEnabled = !isNew
        }
    }
    
    var schedule: Schedule! {
        didSet {
            updateCell()
        }
    }
    
    var appliances: [Appliance]! {
        didSet {
            appliancePicker.reloadAllComponents()
        }
    }
    
    let dowLabels = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        daysMultiSelection.insertSegmentsWithTitles(dowLabels)
        daysMultiSelection.delegate = self
        toggleButtons(enabled: false)
        appliancePicker.delegate = self
        appliancePicker.dataSource = self
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
        updateCell()
    }
    
    func toggleButtons(enabled: Bool) {
        saveButton.isEnabled = enabled && daysMultiSelection.selectedSegmentIndices.count != 0 && startTimePicker.date.compare(endTimePicker.date) != .orderedSame
        enabledSwitch.isEnabled = !isNew
        cancelButton.isEnabled = enabled
    }

    @IBAction func enabledSwitchChanged(_ sender: UISwitch) {
        schedule.enabled = sender.isOn
        schedule.saveInBackground()
    }
    
    @IBAction func startTimeChanged(_ sender: UIDatePicker) {
        toggleButtons(enabled: true)
    }
    
    @IBAction func endTimeChanged(_ sender: UIDatePicker) {
        toggleButtons(enabled: true)
    }
    
    @IBAction func saveTapped(_ sender: UIButton) {
        var newStartDates: [Date] = []
        var newEndDates: [Date] = []
        
        let date: Date = Date()
        let cal = Calendar(identifier: .gregorian)
        
        let startDate: Date = cal.date(bySettingHour: cal.component(.hour, from: startTimePicker.date), minute: cal.component(.minute, from: startTimePicker.date), second: 0, of: date)!
        let endDate: Date = cal.date(bySettingHour: cal.component(.hour, from: endTimePicker.date), minute: cal.component(.minute, from: endTimePicker.date), second: 0, of: date)!
        
        for index in daysMultiSelection.selectedSegmentIndices {
            newStartDates.append(getNextDow(startingFrom: startDate, dowIndex: index+1)!)
            if startDate.compare(endDate) == .orderedDescending { // If start date is after end date, make end date for the next day
                // But prevent corner case - ex: It's Sunday, and Schedule is for Saturday night into Sunday - add one day to endDate to prevent turning off appliance today instead of next Sunday
                var dayComponent = DateComponents()
                dayComponent.day = 1
                newEndDates.append(getNextDow(startingFrom: cal.date(byAdding: dayComponent, to: endDate)!, dowIndex: (index+1)%7 + 1)!)
            } else {
                newEndDates.append(getNextDow(startingFrom: endDate, dowIndex: index+1)!)
            }
        }
        
        schedule.start = newStartDates
        schedule.end = newEndDates
        
        schedule.appliance = appliances[appliancePicker.selectedRow(inComponent: 0)]
        
        schedule.saveInBackground()
        
        isNew = false
        
        toggleButtons(enabled: false)
        
        updateCell()
    }
    
    @IBAction func cancelTapped(_ sender: UIButton) {
        updateCell()
        toggleButtons(enabled: false)
    }
    
    func updateCell() {
        if !isNew {
            titleLabel.text = schedule.appliance.name
        } else {
            titleLabel.text = "New Schedule"
        }
        enabledSwitch.isOn = schedule.enabled
        
        if let firstStartDate = schedule.start.first {
            startTimePicker.date = firstStartDate
        }
        if let firstEndDate = schedule.end.first {
            endTimePicker.date = firstEndDate
        }
        
        subtitleLabel.text = "Every "
        var isFirst = true
        
        if !schedule.start.isEmpty {
            daysMultiSelection.selectedSegmentIndices = []
        }
        
        for date in schedule.start {
            if isFirst {
                isFirst = false
            } else {
                subtitleLabel.text = subtitleLabel.text! + ", "
            }
            let gregorianCalendar = NSCalendar(calendarIdentifier: NSCalendar.Identifier.gregorian)!
            let components = gregorianCalendar.components(.weekday, from: date)
            daysMultiSelection.selectedSegmentIndices.append(components.weekday!-1) // Sunday is at position 0 in segmented list
            subtitleLabel.text = subtitleLabel.text! + dowLabels[components.weekday!-1]
        }
        
        if let firstStartDate = schedule.start.first, let firstEndDate = schedule.end.first {
            let formatter = DateFormatter()
            formatter.dateStyle = .none
            formatter.timeStyle = .short
            subtitleLabel.text = subtitleLabel.text! + " From " + formatter.string(from: firstStartDate) + " To " + formatter.string(from: firstEndDate)
        }
        
        var row = 0
        for x in 0..<appliances.count {
            if appliances[x].applianceId == schedule.appliance.applianceId {
                row = x
                break
            }
        }
        
        appliancePicker.selectRow(row, inComponent: 0, animated: true)
        
        // Handle new Schedule - no info yet
        if subtitleLabel.text == "Every " {
            subtitleLabel.text = " "
        }
        
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

extension ScheduleCell: MultiSelectionSegmentedControlDelegate {
    func multiSelectionSegmentedControl(_ control: MultiSelectionSegmentedControl, selectedIndices indices: [Int]) {
        toggleButtons(enabled: true)
    }
}

extension ScheduleCell: UIPickerViewDelegate {
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        toggleButtons(enabled: true)
    }
}

extension ScheduleCell: UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return appliances.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return appliances[row].name
    }
}
