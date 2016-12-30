//
//  Schedule.swift
//  Internet of Pi
//
//  Created by Alex Strandberg on 12/21/16.
//  Copyright © 2016 Alex Strandberg. All rights reserved.
//
//  NOTE: Modifying an array of Date objects from Parse Dashboard often causes a crash - if this happens, delete the row, and modify the array with Swift code
//

import Foundation
import Parse

class Schedule: PFObject, PFSubclassing {
    
    // MARK: - Parse Core Properties
    
    @NSManaged var appliance: Appliance
    @NSManaged var recurring: Bool
    @NSManaged var start: [Date]
    @NSManaged var end: [Date]
    @NSManaged var enabled: Bool
    
    // MARK: - PFSubclassing
    
    override init() {
        super.init()
    }
    
    init(appliance: Appliance, recurring: Bool, start: [Date], end: [Date], enabled: Bool) {
        super.init()
        
        self.appliance = appliance
        self.recurring = recurring
        self.start = start
        self.end = end
        self.enabled = enabled
    }
    
    class func parseClassName() -> String {
        return "Schedule"
    }
}
