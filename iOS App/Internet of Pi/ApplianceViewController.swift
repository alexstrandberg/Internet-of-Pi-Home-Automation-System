//
//  ApplianceViewController.swift
//  Internet of Pi
//
//  Created by Alex Strandberg on 12/20/16.
//  Copyright © 2016 Alex Strandberg. All rights reserved.
//

import UIKit
import Parse
import MBProgressHUD
import SpinKit

class ApplianceViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var sensorDataLabel: UILabel!
    @IBOutlet weak var bottomButtonsStackView: UIStackView!
    @IBOutlet weak var applyButton: UIButton!
    @IBOutlet weak var closeButton: UIButton!
    
    var timer: Timer?
    
    var appliances: [Appliance] = []
    
    var oneTimeSchedules: [Schedule?] = []
    
    var sensorData: SensorData?
    
    let refreshControl = UIRefreshControl()
    let cellIdentifier = "ApplianceCell"
    
    let applianceCellExpandedHeight: CGFloat = 439
    let applianceCellCollapsedHeight: CGFloat = 83
    
    var isFirstLoad = true
    
    var settings: Settings?

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        applyButton.isEnabled = false
        closeButton.isEnabled = false
        
        tableView.delegate = self
        tableView.dataSource = self
        
        // Initialize a UIRefreshControl
        refreshControl.addTarget(self, action: #selector(refreshControlAction), for: .valueChanged)
        
        tableView.insertSubview(refreshControl, at: 0)
        
        let recognizer = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        recognizer.cancelsTouchesInView = false
        view.addGestureRecognizer(recognizer)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        let settingsQuery = PFQuery(className: "Settings")
        settingsQuery.getFirstObjectInBackground(block: { (settings: PFObject?, error: Error?) in
            if let settings = settings as? Settings {
                self.settings = settings
                self.displaySensorData()
            } else if let error = error {
                print(error.localizedDescription)
            }
        })
        
        refreshControlAction()
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if let timer = timer {
            timer.invalidate()
            self.timer = nil
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func displaySensorData() {
        guard let sensorData = sensorData else { return }
        var displayFahrenheit = true
        if let settings = self.settings, !settings.useFahrenheit {
            displayFahrenheit = false
        }
        let tempString = String(format: "%.2f", displayFahrenheit ? ((9/5)*sensorData.temperature+32.0): sensorData.temperature) + (displayFahrenheit ? " °F" : " °C")
        self.sensorDataLabel.text = String(tempString + "\n" + String(format: "%.2f", sensorData.humidity) + "%\n" + String(sensorData.light) + "\n" + sensorData.reedSwitch + "\n" + sensorData.footSwitch)
    }
    
    func refreshControlAction() {
        if isFirstLoad {
            let spinner = RTSpinKitView(style: .styleWordPress)
            let hud = MBProgressHUD.showAdded(to: self.view, animated: true)
            hud.isSquare = true
            hud.mode = .customView
            hud.customView = spinner
            spinner?.startAnimating()
        }
        
        // Construct PFQuery
        let query = PFQuery(className: "SensorData")
        query.order(byDescending: "createdAt")
        query.limit = 1
        // Fetch data asynchronously
        query.getFirstObjectInBackground { (sensorData: PFObject?, error: Error?) in
            if let sensorData = sensorData as? SensorData {
                self.sensorData = sensorData
                if self.settings != nil { // Make sure settings are loaded before displaying sensor data
                    self.displaySensorData()
                }
            } else if let error = error {
                print(error.localizedDescription)
            }
        }
        if tableView.indexPathForSelectedRow == nil { // Refresh if no cell is selected
        
            // Construct PFQuery
            let query = PFQuery(className: "Appliance")
            query.order(byAscending: "applianceId")
            // Fetch data asynchronously
            query.findObjectsInBackground { (appliances: [PFObject]?, error: Error?) in
                if let appliances = appliances as? [Appliance] {
                    self.appliances = appliances
                    let scheduleQuery = PFQuery(className: "Schedule")
                    scheduleQuery.whereKey("recurring", equalTo: false)
                    scheduleQuery.includeKey("appliance")
                    scheduleQuery.findObjectsInBackground(block: { (schedules: [PFObject]?, error: Error?) in
                        if let schedules = schedules as? [Schedule] {
                            self.oneTimeSchedules = [Schedule?](repeating: nil, count:self.appliances.count)
                            for schedule in schedules {
                                self.oneTimeSchedules[schedule.appliance.applianceId] = schedule
                            }
                        } else if let error = error {
                            print(error.localizedDescription)
                        }
                        self.tableView.reloadData()
                        if self.isFirstLoad {
                            self.isFirstLoad = false
                            MBProgressHUD.hide(for: self.view, animated: true)
                            
                        }
                        if self.timer == nil {
                            self.timer = Timer.scheduledTimer(timeInterval: 5.0, target: self, selector: #selector(self.refreshControlAction), userInfo: nil, repeats: true)
                        }
                    })
                } else if let error = error {
                    print(error.localizedDescription)
                    if self.isFirstLoad {
                        self.isFirstLoad = false
                        MBProgressHUD.hide(for: self.view, animated: true)
                        if self.timer == nil {
                            self.timer = Timer.scheduledTimer(timeInterval: 5.0, target: self, selector: #selector(self.refreshControlAction), userInfo: nil, repeats: true)
                        }
                    }
                }
                self.refreshControl.endRefreshing()
            }
        } else {
            self.refreshControl.endRefreshing()
        }
    }
    
    func handleTap(recognizer: UITapGestureRecognizer) {
        if recognizer.location(in: view).y < tableView.frame.minY, let selectedIndexPath = tableView.indexPathForSelectedRow {
            tableView.deselectRow(at: selectedIndexPath, animated: true)
            handleCell(selected: false, at: selectedIndexPath)
        }
    }
    
    func tableViewScrollToSelectedCell(animated: Bool) {
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            let numberOfRows = self.tableView.numberOfRows(inSection: 0)
            
            if numberOfRows > 0, let selectedIndexPath = self.tableView.indexPathForSelectedRow {
                let indexPath = IndexPath(row: selectedIndexPath.row, section: 0)
                self.tableView.scrollToRow(at: indexPath, at: UITableViewScrollPosition.top, animated: animated)
            }
        }
    }
    
    @IBAction func applyTapped(_ sender: UIButton) {
        if let selectedIndexPath = tableView.indexPathForSelectedRow {
            let appliance = appliances[selectedIndexPath.row]
            let cell = tableView.cellForRow(at: selectedIndexPath) as! ApplianceCell
            
            let endDate = Date(timeInterval: cell.datePicker.countDownDuration, since: Date())
            if let schedule = cell.schedule { // Update existing one-time schedule if it exists
                schedule.end = [endDate]
                schedule.saveInBackground()
            } else {
                oneTimeSchedules[appliance.applianceId] = Schedule(appliance: appliance, recurring: false, start: [Date()], end: [endDate], enabled: true)
                oneTimeSchedules[appliance.applianceId]!.saveInBackground()
                cell.schedule = oneTimeSchedules[appliance.applianceId]
            }
            appliance.state = 1
            appliance.enabled = true
            cell.appliance = appliance
            cell.updateCell()
            
            tableView.deselectRow(at: selectedIndexPath, animated: true)
            handleCell(selected: false, at: selectedIndexPath)
        }
    }
    
    @IBAction func closeTapped(_ sender: UIButton) {
        if let selectedIndexPath = tableView.indexPathForSelectedRow {
            tableView.deselectRow(at: selectedIndexPath, animated: true)
            handleCell(selected: false, at: selectedIndexPath)
        }
    }
    
    func handleCell(selected: Bool, at indexPath: IndexPath) {
        tableView.beginUpdates()
        tableView.endUpdates()
        applyButton.isEnabled = selected
        closeButton.isEnabled = selected
    }
}

extension ApplianceViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        handleCell(selected: true, at: indexPath)
        tableViewScrollToSelectedCell(animated: true)
    }
    
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        handleCell(selected: false, at: indexPath)
    }
    
    func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        if let selectedIndexPath = tableView.indexPathForSelectedRow, selectedIndexPath == indexPath { // Prevent selecting same cell while it is already selected
            return nil
        } else {
            return indexPath
        }
    }
}

extension ApplianceViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier) as! ApplianceCell
        
        cell.appliance = appliances[indexPath.row]
        cell.schedule = oneTimeSchedules[indexPath.row]
        cell.updateCell()
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return appliances.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if let selectedIndexPath = tableView.indexPathForSelectedRow, selectedIndexPath == indexPath {
            return applianceCellExpandedHeight
        } else {
            return applianceCellCollapsedHeight
        }
    }
}
