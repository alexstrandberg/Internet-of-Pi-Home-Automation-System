//
//  Action.swift
//  Internet of Pi
//
//  Created by Alex Strandberg on 12/27/16.
//  Copyright © 2016 Alex Strandberg. All rights reserved.
//

import UIKit
import Parse

class Action: PFObject, PFSubclassing {
    // MARK: - Parse Core Properties
    @NSManaged var enabled: Bool
    @NSManaged var state: Int
    @NSManaged var appliance: Appliance
    @NSManaged var event: String
    
    // MARK: - PFSubclassing
    
    override init() {
        super.init()
    }
    
    init(enabled: Bool, state: Int, appliance: Appliance, event: String) {
        super.init()
        
        self.enabled = enabled
        self.state = state
        self.appliance = appliance
        self.event = event
    }
    
    class func parseClassName() -> String {
        return "Action"
    }
}
