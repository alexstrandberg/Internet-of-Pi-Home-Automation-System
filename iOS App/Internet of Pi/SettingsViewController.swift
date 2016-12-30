//
//  SettingsViewController.swift
//  Internet of Pi
//
//  Created by Alex Strandberg on 12/26/16.
//  Copyright © 2016 Alex Strandberg. All rights reserved.
//

import UIKit
import Parse
import MBProgressHUD
import SpinKit

class SettingsViewController: UIViewController {
    @IBOutlet weak var useFahrenheitSwitch: UISwitch!
    @IBOutlet weak var use12HourFormatSwitch: UISwitch!
    @IBOutlet weak var lightThresholdField: UITextField!
    @IBOutlet weak var temperatureThresholdField: UITextField!
    @IBOutlet weak var humidityThresholdField: UITextField!
    @IBOutlet weak var temperatureLabel: UILabel!
    
    var settings: Settings?

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        lightThresholdField.delegate = self
        temperatureThresholdField.delegate = self
        humidityThresholdField.delegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        let spinner = RTSpinKitView(style: .styleWordPress)
        let hud = MBProgressHUD.showAdded(to: self.view, animated: true)
        hud.isSquare = true
        hud.mode = .customView
        hud.customView = spinner
        spinner?.startAnimating()
        
        let query = PFQuery(className: "Settings")
        query.getFirstObjectInBackground { (settings: PFObject?, error: Error?) in
            if let settings = settings as? Settings {
                self.settings = settings
                self.updateScreen()
            } else if let error = error {
                print(error.localizedDescription)
            }
            MBProgressHUD.hide(for: self.view, animated: true)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func updateScreen() {
        if let settings = settings {
            useFahrenheitSwitch.isOn = settings.useFahrenheit
            use12HourFormatSwitch.isOn = settings.use12HourFormat
            lightThresholdField.text = String(settings.lightThreshold)
            temperatureThresholdField.text = String(format: "%.2f", settings.useFahrenheit ? ((9/5)*settings.temperatureThreshold+32.0): settings.temperatureThreshold)
            humidityThresholdField.text = String(format: "%.2f", settings.humidityThreshold)
            temperatureLabel.text = settings.useFahrenheit ? "Temperature Threshold °F:" : "Temperature Threshold °C:"
        }
    }
    
    @IBAction func useFahrenheitSwitchChanged(_ sender: UISwitch) {
        if let settings = settings {
            settings.useFahrenheit = sender.isOn
            updateScreen()
            settings.saveInBackground()
        }
    }
    
    @IBAction func use12HourFormatSwitchChanged(_ sender: UISwitch) {
        if let settings = settings {
            settings.use12HourFormat = sender.isOn
            settings.saveInBackground()
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        lightThresholdField.resignFirstResponder()
        temperatureThresholdField.resignFirstResponder()
        humidityThresholdField.resignFirstResponder()
    }
    @IBAction func syncDateTimeTapped(_ sender: UIButton) {
        if let settings = settings {
            settings.systemFlag = "updateDateTime"
            settings.saveInBackground()
        }
    }
    
    @IBAction func rebootPiTapped(_ sender: UIButton) {
        if let settings = settings {
            settings.systemFlag = "rebootPi"
            settings.saveInBackground()
        }
    }

    @IBAction func shutdownPiTapped(_ sender: UIButton) {
        if let settings = settings {
            settings.systemFlag = "shutdownPi"
            settings.saveInBackground()
        }
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

extension SettingsViewController: UITextFieldDelegate {
    func textFieldShouldEndEditing(_ textField: UITextField) -> Bool {
        if let text = textField.text, let settings = settings {
            textField.resignFirstResponder()
            if textField == lightThresholdField, let lightThreshold = Int(text), lightThreshold > 0 {
                settings.lightThreshold = lightThreshold
            } else if textField == temperatureThresholdField, let temperatureThreshold = Double(text), temperatureThreshold > 0.0 {
                settings.temperatureThreshold = settings.useFahrenheit ? (5/9)*(temperatureThreshold - 32.0) : temperatureThreshold
            } else if textField == humidityThresholdField, let humidityThreshold = Double(text), humidityThreshold > 0.0 {
                settings.humidityThreshold = humidityThreshold
            } else {
                return false
            }
            updateScreen()
            settings.saveInBackground()
            
            return true
        }
        return false
    }
    
    
}
