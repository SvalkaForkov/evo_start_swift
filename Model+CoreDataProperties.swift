//
//  Model+CoreDataProperties.swift
//  BLETool
//
//  Created by Xiaotu Zhang on 2016-09-13.
//  Copyright © 2016 fortin. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension Model {

    @NSManaged var title: String?
    @NSManaged var model2make: Make?
    @NSManaged var model2vehicle: NSSet?

}
