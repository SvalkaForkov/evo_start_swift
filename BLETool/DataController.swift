//
//  File.swift
//  BLETool
//
//  Created by Xiaotu Zhang on 2016-06-16.
//  Copyright © 2016 fortin. All rights reserved.
//

import Foundation
import CoreData

class DataController {
    let managedObjectContext: NSManagedObjectContext
    
    init(moc: NSManagedObjectContext) {
        self.managedObjectContext = moc
    }


    convenience init?() {
        print("convenience init")
        guard let modelURL = NSBundle.mainBundle().URLForResource("Model", withExtension: "momd") else {
            return nil
        }
        
        guard let mom = NSManagedObjectModel(contentsOfURL: modelURL) else {
            return nil
        }
        
        let psc = NSPersistentStoreCoordinator(managedObjectModel: mom)
        let moc = NSManagedObjectContext(concurrencyType: .MainQueueConcurrencyType)
        moc.persistentStoreCoordinator = psc
        
        let urls = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)
        let persistantStoreFileURL = urls[0].URLByAppendingPathComponent("Bookmarks.sqlite")
        
        do {
            try psc.addPersistentStoreWithType(NSSQLiteStoreType, configuration: nil, URL: persistantStoreFileURL, options: nil)
        } catch {
            fatalError("Error adding store.")
        }
        
        self.init(moc: moc)
        
    }
    
    func getAllVehicles() -> [Vehicle]{
        print("convenience init")
        let vehicleFetch = NSFetchRequest(entityName: "Vehicle")
        
        var fetchedVehicles: [Vehicle]!
        do {
            fetchedVehicles = try self.managedObjectContext.executeFetchRequest(vehicleFetch) as! [Vehicle]
        } catch {
            fatalError("fetch failed")
        }
        
        return fetchedVehicles
    }

    
}