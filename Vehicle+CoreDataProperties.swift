//
//  Vehicle+CoreDataProperties.swift
//  BLETool
//
//  Created by Xiaotu Zhang on 2016-06-16.
//  Copyright © 2016 fortin. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension Vehicle {

    @NSManaged var module: String?
    @NSManaged var make: String?
    @NSManaged var model: String?
    @NSManaged var name: String?
    @NSManaged var year: String?
    
}
