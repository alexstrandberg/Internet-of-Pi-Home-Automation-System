//
//  ActionsViewController.swift
//  Internet of Pi
//
//  Created by Alex Strandberg on 12/26/16.
//  Copyright © 2016 Alex Strandberg. All rights reserved.
//

import UIKit
import Parse
import MBProgressHUD
import SpinKit

class ActionsViewController: UIViewController {
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var newButton: UIButton!
    @IBOutlet weak var closeButton: UIButton!
    
    var actions: [Action] = []
    var appliances: [Appliance] = []
    
    let refreshControl = UIRefreshControl()
    let cellIdentifier = "ActionCell"
    
    let actionCellExpandedHeight: CGFloat = 623
    let actionCellCollapsedHeight: CGFloat = 90
    
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
        nullStateLabel.text = "No Actions To Show"
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
                let query = PFQuery(className: "Action")
                query.includeKey("appliance")
                // Fetch data asynchronously
                query.findObjectsInBackground { (actions: [PFObject]?, error: Error?) in
                    if let actions = actions as? [Action] {
                        self.actions = actions
                        if actions.count == 0 {
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
        actions.append(Action(enabled: true, state: 1, appliance: Appliance(), event: ""))
        newCellIndex = IndexPath(row: actions.count-1, section: 0)
        tableView.reloadData()
        tableView.selectRow(at: IndexPath(row: actions.count-1, section: 0), animated: true, scrollPosition: .top)
        tableViewScrollToSelectedCell(animated: true)
        handleCell(selected: true, editing: false)
    }
    
    @IBAction func closeTapped(_ sender: UIButton) {
        if let selectedIndexPath = self.tableView.indexPathForSelectedRow {
            self.tableView.deselectRow(at: selectedIndexPath, animated: true)
        }
        self.handleCell(selected: false, editing: false)
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}

extension ActionsViewController: UITableViewDelegate {
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
            actions[indexPath.row].deleteInBackground()
            actions.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .automatic)
            handleCell(selected: false, editing: false)
            if actions.count == 0 {
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

extension ActionsViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return actions.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier) as! ActionCell
        
        if let newCellIndex = newCellIndex, newCellIndex == indexPath {
            cell.isNew = true
        }
        
        cell.appliances = appliances
        cell.action = actions[indexPath.row]
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if let selectedIndexPath = tableView.indexPathForSelectedRow, selectedIndexPath == indexPath {
            return actionCellExpandedHeight
        } else {
            return actionCellCollapsedHeight
        }
    }
}
