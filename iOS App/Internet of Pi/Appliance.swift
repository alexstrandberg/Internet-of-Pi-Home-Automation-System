//
//  Appliance.swift
//  Internet of Pi
//
//  Created by Alex Strandberg on 12/21/16.
//  Copyright © 2016 Alex Strandberg. All rights reserved.
//

import UIKit
import Parse

class Appliance: PFObject, PFSubclassing {
    
    // MARK: - Parse Core Properties
    
    @NSManaged var applianceId: Int
    @NSManaged var name: String
    @NSManaged var state: Int
    @NSManaged var enabled: Bool
    
    // MARK: - PFSubclassing
    
    class func parseClassName() -> String {
        return "Appliance"
    }
}
