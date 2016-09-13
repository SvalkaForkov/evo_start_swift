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
        print("DataController : init moc")
    }
    
    
    convenience init?() {
        print("DataController : convenience init")
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
        let persistantStoreFileURL = urls[0].URLByAppendingPathComponent("Vehicles.sqlite")
        
        do {
            try psc.addPersistentStoreWithType(NSSQLiteStoreType, configuration: nil, URL: persistantStoreFileURL, options: nil)
        } catch {
            fatalError("Error adding store.")
        }
        
        self.init(moc: moc)
        
    }
    
    func getAllVehicles() -> [Vehicle]{
        print("DataController : getAllVehicles")
        let vehicleFetch = NSFetchRequest(entityName: "Vehicle")
        
        var fetchedVehicles: [Vehicle]! = []
        do {
            fetchedVehicles = try self.managedObjectContext.executeFetchRequest(vehicleFetch) as! [Vehicle]
        } catch {
            fatalError("fetch failed")
        }
        print("DataController : fetched \(fetchedVehicles.count)")
        return fetchedVehicles
    }
    
    func saveVehicle(name: String, module: String){
        print("saveVehicle(\(name))")
        let newVehicle = NSEntityDescription.insertNewObjectForEntityForName("Vehicle", inManagedObjectContext: self.managedObjectContext) as! Vehicle
        newVehicle.name = name
        newVehicle.module = module
        do {
            try self.managedObjectContext.save()
        } catch {
            fatalError("couldn't save context")
        }
    }
    
    func saveVehicle(name: String, model: Model, year: NSDecimalNumber, module: String){
        print("DataController : Save vehicle \(name)")
        let newVehicle = NSEntityDescription.insertNewObjectForEntityForName("Vehicle", inManagedObjectContext: self.managedObjectContext) as! Vehicle
        newVehicle.name = name
        newVehicle.module = module
        newVehicle.v2model = model
        newVehicle.year = year
        do {
            try self.managedObjectContext.save()
        } catch {
            fatalError("couldn't save context")
            
        }
    }
    
    func fetchMakeByModel(model: Model) -> Make{
        let fetchRequest = NSFetchRequest(entityName: "Make")
        fetchRequest.predicate = NSPredicate(format: "make2model == %@", model)
        
        var fetchedMakes: [Make]!
        do {
            fetchedMakes = try self.managedObjectContext.executeFetchRequest(fetchRequest) as! [Make]
        } catch {
            fatalError("fetch make failed")
        }
        if fetchedMakes.count == 0 {
            fatalError("no make matched")
        }
        return fetchedMakes[0]
    }

    func fetchModelsForMake(make: Make) -> [Model]{
        let fetchRequest = NSFetchRequest(entityName: "Model")
        fetchRequest.predicate = NSPredicate(format: "model2make == %@", make)
        
        var fetchedModels: [Model]!
        do {
            fetchedModels = try self.managedObjectContext.executeFetchRequest(fetchRequest) as! [Model]
        } catch {
            fatalError("fetch model failed")
        }
        if fetchedModels.count == 0 {
            fatalError("no model matched")
        }
        return fetchedModels
    }
    
    func fetchMakeByTitle(title: String) -> Make?{
        let fetchRequest = NSFetchRequest(entityName: "Make")
        fetchRequest.predicate = NSPredicate(format: "title == %@", title)
        
        var fetchedMakes: [Make]!
        do {
            fetchedMakes = try self.managedObjectContext.executeFetchRequest(fetchRequest) as! [Make]
        } catch {
            fatalError("fetch make failed")
        }
        if fetchedMakes.count == 0 {
            fatalError("no make matched")
        }
        return fetchedMakes[0]
    }
    
    func fetchVehicleByName(name: String)-> [Vehicle]{
        print("fetchVehicleByName: \(name)")
        
        let fetchRequest = NSFetchRequest()
        let entityDescription = NSEntityDescription.entityForName("Vehicle", inManagedObjectContext: self.managedObjectContext)
        fetchRequest.entity = entityDescription
        var fetchedVehicle: [Vehicle]!
        do {
            fetchedVehicle = try self.managedObjectContext.executeFetchRequest(fetchRequest) as! [Vehicle]
        } catch {
            fatalError("fetch failed")
        }
        
        if fetchedVehicle.count == 0 {
            print("none fetched")
        }else{
            print("\(fetchedVehicle.count) fetched")
        }
        return fetchedVehicle
    }
    
    func updateVehicle(vehicle: Vehicle){
        print("updateVehicle: \(vehicle.name))")
        let result = fetchVehicleByName(vehicle.name!)
        let newVehicle = result[0] as Vehicle
        newVehicle.name = vehicle.name
        newVehicle.module = vehicle.module
        newVehicle.v2model = vehicle.v2model
        newVehicle.year = vehicle.year
        do {
            try newVehicle.managedObjectContext!.save()
        } catch {
            fatalError("couldn't save context")
        }
    }
    
    func deleteVehicleByName(name : String){
        print("deleteVehicle")
        let result = fetchVehicleByName(name)
        let vehicle = result[0]
        self.managedObjectContext.deleteObject(vehicle)
        do {
            try self.managedObjectContext.save()
        } catch {
            let saveError = error as NSError
            print(saveError)
        }
    }
}