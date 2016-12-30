//
//  Alarm.swift
//  Internet of Pi
//
//  Created by Alex Strandberg on 12/26/16.
//  Copyright © 2016 Alex Strandberg. All rights reserved.
//

import UIKit
import Parse

class Alarm: PFObject, PFSubclassing {
    
    // MARK: - Parse Core Properties
    @NSManaged var repeats: Bool
    @NSManaged var when: [Date]
    @NSManaged var enabled: Bool
    @NSManaged var soundAlarm: Bool
    
    
    // MARK: - PFSubclassing
    
    override init() {
        super.init()
    }
    
    init(repeats: Bool, when: [Date], enabled: Bool) {
        super.init()
        
        self.repeats = repeats
        self.when = when
        self.enabled = enabled
        self.soundAlarm = false
    }
    
    class func parseClassName() -> String {
        return "Alarm"
    }
}
