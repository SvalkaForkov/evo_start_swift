//
//  Vehicle.swift
//  BLETool
//
//  Created by Xiaotu Zhang on 2016-06-16.
//  Copyright © 2016 fortin. All rights reserved.
//

import Foundation
import CoreData


class Vehicle: NSManagedObject {
    let name: String
    
    init (name: String,make: String,model: String,year: String,address: String) {
        self.name = name
        super.init()
    }
    
    func encodeWithCoder(aCoder: NSCoder) {
        aCoder.encodeObject(self.name, forKey: "name")
        aCoder.encodeObject(self.make, forKey: "make")
        aCoder.encodeObject(self.model, forKey: "model")
        aCoder.encodeObject(self.year, forKey: "year")
        aCoder.encodeObject(self.address, forKey: "address")
    }
    
    required convenience init?(coder aDecoder: NSCoder) {
        
        let storedName = aDecoder.decodeObjectForKey("name") as? String
        
        guard storedName != nil else {
            return nil
        }
        self.init(name: storedName!,make: storedName!,model: storedName!,year: storedName!,address: storedName!)
        
        
    }


}
