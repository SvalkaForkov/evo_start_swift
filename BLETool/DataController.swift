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
        print("init moc")
    }


    convenience init?() {
        print("convenience init")
        guard let modelURL = NSBundle.mainBundle().URLForResource("Vehicle", withExtension: "momd") else {
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
        print("get all vehicles")
        let vehicleFetch = NSFetchRequest(entityName: "Vehicle")
        
        var fetchedVehicles: [Vehicle]! = []
        do {
            fetchedVehicles = try self.managedObjectContext.executeFetchRequest(vehicleFetch) as! [Vehicle]
        } catch {
            fatalError("fetch failed")
        }
        print("fetched \(fetchedVehicles.count)")
        return fetchedVehicles
    }
    
    func saveVehicle(name: String, address: String){
        print("save new vehicle : \(name))")
//        var existVehicle = fetchVehicle(name)
//        if existVehicle != nil {
            let newVehicle = NSEntityDescription.insertNewObjectForEntityForName("Vehicle", inManagedObjectContext: self.managedObjectContext) as! Vehicle
            newVehicle.name = name
            newVehicle.address = address
            do {
                try self.managedObjectContext.save()
            } catch {
                fatalError("couldn't save context")
//            }
        }
    }
    
    func fetchVehicle(name: String)-> Vehicle{
        print("fetch vehicle : \(name))")
        let vehicleFetch = NSFetchRequest(entityName: "Vehicle")
        vehicleFetch.predicate = NSPredicate(format: "name == %@", name)
        
        var fetchedVehicle: [Vehicle]!
        do {
            fetchedVehicle = try self.managedObjectContext.executeFetchRequest(vehicleFetch) as! [Vehicle]
        } catch {
            fatalError("fetch failed")
        }
        if fetchedVehicle.count > 1 {
            print("more than one fetched")
        }else{
            print("fetched one")
        }
        return fetchedVehicle[0]
    }
    
    func updateVehicle(vehicle: Vehicle){
        print("update vehicle : \(vehicle.name))")
        let newVehicle = fetchVehicle(vehicle.name!)
        do {
            try newVehicle.managedObjectContext!.save()
        } catch {
            fatalError("couldn't save context")
        }
        
    }

}