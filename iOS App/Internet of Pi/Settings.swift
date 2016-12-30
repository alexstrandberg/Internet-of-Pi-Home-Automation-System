//
//  Settings.swift
//  Internet of Pi
//
//  Created by Alex Strandberg on 12/26/16.
//  Copyright © 2016 Alex Strandberg. All rights reserved.
//

import UIKit
import Parse

class Settings: PFObject, PFSubclassing {
    // MARK: - Parse Core Properties
    @NSManaged var useFahrenheit: Bool
    @NSManaged var use12HourFormat: Bool
    @NSManaged var lightThreshold: Int
    @NSManaged var temperatureThreshold: Double
    @NSManaged var humidityThreshold: Double
    @NSManaged var systemFlag: String
    
    // MARK: - PFSubclassing
    
    class func parseClassName() -> String {
        return "Settings"
    }
}
