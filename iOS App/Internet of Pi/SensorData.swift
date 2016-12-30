//
//  SensorData.swift
//  Internet of Pi
//
//  Created by Alex Strandberg on 12/21/16.
//  Copyright © 2016 Alex Strandberg. All rights reserved.
//

import Foundation
import Parse

class SensorData: PFObject, PFSubclassing {
    
    // MARK: - Parse Core Properties
    
    @NSManaged var temperature: Float
    @NSManaged var humidity: Float
    @NSManaged var light: Int
    @NSManaged var reedSwitch: String
    @NSManaged var footSwitch: String
    
    // MARK: - PFSubclassing
    
    class func parseClassName() -> String {
        return "SensorData"
    }
}
