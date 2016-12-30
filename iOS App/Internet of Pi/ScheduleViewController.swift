//
//  ScheduleViewController.swift
//  Internet of Pi
//
//  Created by Alex Strandberg on 12/24/16.
//  Copyright © 2016 Alex Strandberg. All rights reserved.
//

import UIKit
import Parse
import MBProgressHUD
import SpinKit

class ScheduleViewController: UIViewController {
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var newButton: UIButton!
    @IBOutlet weak var closeButton: UIButton!
    
    var schedules: [Schedule] = []
    var appliances: [Appliance] = []
    
    let refreshControl = UIRefreshControl()
    let cellIdentifier = "ScheduleCell"
    
    let scheduleCellExpandedHeight: CGFloat = 623
    let scheduleCellCollapsedHeight: CGFloat = 114
    
    var isFirstLoad = true
    
    var nullStateLabel: UILabel!
    var newCellIndex: IndexPath?

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        newButton.isEnabled = true
        closeButton.isEnabled = false
        
        tableView.delegate = self
        tableView.dataSource = self
        
        // Initialize a UIRefreshControl
        refreshControl.addTarget(self, action: #selector(refreshControlAction), for: .valueChanged)
        
        tableView.insertSubview(refreshControl, at: 0)
        
        nullStateLabel = UILabel(frame: self.view.frame)
        nullStateLabel.center = CGPoint(x: self.view.frame.width / 2, y: self.view.frame.height / 2)
        nullStateLabel.textAlignment = .center
        nullStateLabel.text = "No Schedules To Show"
        nullStateLabel.textColor = UIColor.black
        nullStateLabel.font = UIFont.systemFont(ofSize: 20)
        nullStateLabel.isHidden = false
        tableView.addSubview(nullStateLabel)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        refreshControlAction()
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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
        
        // Need appliances for picker
        let applianceQuery = PFQuery(className: "Appliance")
        applianceQuery.whereKey("enabled", equalTo: true)
        applianceQuery.order(byAscending: "applianceId")
        applianceQuery.findObjectsInBackground { (appliances: [PFObject]?, error: Error?) in
            if let appliances = appliances as? [Appliance] {
                self.appliances = appliances
                
                // Construct PFQuery
                let query = PFQuery(className: "Schedule")
                query.whereKey("recurring", equalTo: true)
                query.includeKey("appliance")
                // Fetch data asynchronously
                query.findObjectsInBackground { (schedules: [PFObject]?, error: Error?) in
                    if let schedules = schedules as? [Schedule] {
                        self.schedules = schedules
                        if schedules.count == 0 {
                            self.nullStateLabel.isHidden = false
                        } else {
                            self.nullStateLabel.isHidden = true
                        }
                        self.newCellIndex = nil
                        self.tableView.reloadData()
                        self.handleCell(selected: false, editing: false)
                    } else if let error = error {
                        print(error.localizedDescription)
                    }
                    if self.isFirstLoad {
                        self.isFirstLoad = false
                        MBProgressHUD.hide(for: self.view, animated: true)
                    }
                    self.refreshControl.endRefreshing()
                }
            } else if let error = error {
                print(error.localizedDescription)
                if self.isFirstLoad {
                    self.isFirstLoad = false
                    MBProgressHUD.hide(for: self.view, animated: true)
                }
                self.refreshControl.endRefreshing()
            }
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
    
    func handleCell(selected: Bool, editing: Bool) {
        tableView.beginUpdates()
        tableView.endUpdates()
        newButton.isEnabled = !selected
        closeButton.isEnabled = selected && !editing
    }

    @IBAction func newTapped(_ sender: UIButton) {
        nullStateLabel.isHidden = true
        schedules.append(Schedule(appliance: Appliance(), recurring: true, start: [], end: [], enabled: true))
        newCellIndex = IndexPath(row: schedules.count-1, section: 0)
        tableView.reloadData()
        tableView.selectRow(at: IndexPath(row: schedules.count-1, section: 0), animated: true, scrollPosition: .top)
        tableViewScrollToSelectedCell(animated: true)
        handleCell(selected: true, editing: false)
    }
    
    @IBAction func closeTapped(_ sender: UIButton) {
        if let selectedIndexPath = self.tableView.indexPathForSelectedRow {
            self.tableView.deselectRow(at: selectedIndexPath, animated: true)
        }
        self.handleCell(selected: false, editing: false)
    }

}

extension ScheduleViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        handleCell(selected: true, editing: false)
        tableViewScrollToSelectedCell(animated: true)
    }
    
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        handleCell(selected: false, editing: false)
    }
    
    func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        if let selectedIndexPath = tableView.indexPathForSelectedRow, selectedIndexPath == indexPath { // Prevent selecting same cell while it is already selected
            return nil
        } else {
            return indexPath
        }
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            schedules[indexPath.row].deleteInBackground()
            schedules.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .automatic)
            handleCell(selected: false, editing: false)
            if schedules.count == 0 {
                nullStateLabel.isHidden = false
            }
        }
    }
    
    func tableView(_ tableView: UITableView, willBeginEditingRowAt indexPath: IndexPath) {
        tableView.selectRow(at: indexPath, animated: true, scrollPosition: .top)
        handleCell(selected: true, editing: true)
        tableViewScrollToSelectedCell(animated: true)
    }
    
    func tableView(_ tableView: UITableView, didEndEditingRowAt indexPath: IndexPath?) {
        closeButton.isEnabled = true
    }
}

extension ScheduleViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return schedules.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier) as! ScheduleCell
        
        if let newCellIndex = newCellIndex, newCellIndex == indexPath {
            cell.isNew = true
        }
        
        cell.appliances = appliances
        cell.schedule = schedules[indexPath.row]
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if let selectedIndexPath = tableView.indexPathForSelectedRow, selectedIndexPath == indexPath {
            return scheduleCellExpandedHeight
        } else {
            return scheduleCellCollapsedHeight
        }
    }
}
