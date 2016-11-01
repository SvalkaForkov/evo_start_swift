//
//  File.swift
//  BLETool
//
//  Created by Xiaotu Zhang on 2016-06-16.
//  Copyright © 2016 fortin. All rights reserved.
//

import Foundation
import CoreData
import UIKit

class DataController {
    let managedObjectContext: NSManagedObjectContext
    let DBG = true
    let VDBG = true
    
    init(moc: NSManagedObjectContext) {
        self.managedObjectContext = moc
        printVDBG("DataController : init moc")
    }
    
    func printDBG(string :String){
        if DBG {
            print("\(getTimestamp()) \(string)")
        }
    }
    
    func printVDBG(string :String){
        if VDBG {
            print("\(getTimestamp()) \(string)")
        }
    }
    
    func getTimestamp() -> String{
        let date = NSDate()
        let calender = NSCalendar.currentCalendar()
        let components = calender.components([.Hour,.Minute,.Second], fromDate: date)
        return "[\(components.hour):\(components.minute):\(components.second)] - DataController - "
    }
    
    
    func insertMake(title : String){
        let makeFetch = NSFetchRequest(entityName: "Make")
        makeFetch.predicate = NSPredicate(format: "title == %@", title)
        var fetchedMakes: [Make]!
        do {
            fetchedMakes = try self.managedObjectContext.executeFetchRequest(makeFetch) as! [Make]
        } catch {
            fatalError("Fetch makes failed")
        }
        if fetchedMakes.count == 0{
            let newMake = NSEntityDescription.insertNewObjectForEntityForName("Make", inManagedObjectContext: self.managedObjectContext) as! Make
            newMake.title = title
            do {
                try self.managedObjectContext.save()
            } catch {
                fatalError("Save context failed")
            }
        }
    }
    
    func insertModel(title : String, make: Make){
        let modelFetch = NSFetchRequest(entityName: "Model")
        modelFetch.predicate = NSPredicate(format: "title == %@", title)
        var fetchedModels: [Model]!
        do {
            fetchedModels = try self.managedObjectContext.executeFetchRequest(modelFetch) as! [Model]
        } catch {
            fatalError("Fetch models failed")
        }
        if fetchedModels.count == 0{
            let newModel = NSEntityDescription.insertNewObjectForEntityForName("Model", inManagedObjectContext: self.managedObjectContext) as! Model
            newModel.model2make = make
            newModel.title = title
            do {
                try self.managedObjectContext.save()
            } catch {
                fatalError("Save context failed")
            }
        }
    }
    
    func insertModelAndMake(title: String, makeTitle :String){
        insertMake(makeTitle)
        let make = fetchMakeByTitle(makeTitle)
        if make != nil {
            let modelFetch = NSFetchRequest(entityName: "Model")
            modelFetch.predicate = NSPredicate(format: "title == %@", title)
            var fetchedModels: [Model]!
            do {
                fetchedModels = try self.managedObjectContext.executeFetchRequest(modelFetch) as! [Model]
            } catch {
                fatalError("Fetch models failed")
            }
            if fetchedModels.count == 0{
                let newModel = NSEntityDescription.insertNewObjectForEntityForName("Model", inManagedObjectContext: self.managedObjectContext) as! Model
                newModel.model2make = fetchMakeByTitle(makeTitle)
                newModel.title = title
                if newModel.model2make != nil{
                    do {
                        try self.managedObjectContext.save()
                    } catch {
                        fatalError("Save context failed")
                    }
                }else{
                    printVDBG("Make of this model is nil : \(title)")
                }
            }
        }
    }
    
    func fetchAllMakes() -> [Make]{
        let makeFetch = NSFetchRequest(entityName: "Make")
        
        var fetchedMakes: [Make]?
        do {
            fetchedMakes = try self.managedObjectContext.executeFetchRequest(makeFetch) as? [Make]
        } catch {
            fatalError("fetch failed")
        }
        printVDBG("DataController : fetched \(fetchedMakes!.count)")
        return fetchedMakes!
    }
    
    convenience init?() {
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
        printVDBG("DataController : getAllVehicles")
        let vehicleFetch = NSFetchRequest(entityName: "Vehicle")
        
        var fetchedVehicles: [Vehicle]! = []
        do {
            fetchedVehicles = try self.managedObjectContext.executeFetchRequest(vehicleFetch) as! [Vehicle]
        } catch {
            fatalError("fetch failed")
        }
        printVDBG("DataController : fetched \(fetchedVehicles.count)")
        return fetchedVehicles
    }
    
    func saveVehicle(name: String, model: Model, year: NSDecimalNumber, module: String){
        printVDBG("DataController : Save vehicle \(name)")
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
    
    func fetchModelByTitle(title: String) -> Model?{
        let fetchRequest = NSFetchRequest(entityName: "Model")
        fetchRequest.predicate = NSPredicate(format: "title == %@", title)
        
        var fetchedModels: [Model]!
        do {
            fetchedModels = try self.managedObjectContext.executeFetchRequest(fetchRequest) as! [Model]
        } catch {
            fatalError("fetch Model failed")
        }
        if fetchedModels.count == 0 {
            fatalError("no Model matched")
        }
        return fetchedModels[0]
    }
    
    func fetchVehicleByName(name: String)-> Vehicle?{
        printVDBG("fetchVehicleByName: \(name)")
        
        let fetchRequest = NSFetchRequest()
        let entityDescription = NSEntityDescription.entityForName("Vehicle", inManagedObjectContext: self.managedObjectContext)
        fetchRequest.entity = entityDescription
        var fetchedVehicle: [Vehicle]!
        do {
            fetchedVehicle = try self.managedObjectContext.executeFetchRequest(fetchRequest) as! [Vehicle]
        } catch {
            fatalError("fetch failed")
        }
        var vehicle : Vehicle? = nil
        if fetchedVehicle.count == 0 {
            printVDBG("none fetched")
            return nil
        }else{
            printVDBG("\(fetchedVehicle.count) fetched")
            for v in fetchedVehicle {
                print("name:\(name)")
                print("v.name:\(v.module)")
                if v.module == name {
                    vehicle = v
                }
            }
            return vehicle
        }
        
    }
    
    func updateVehicle(vehicle: Vehicle){
        printVDBG("updateVehicle: \(vehicle.name))")
        let newVehicle = fetchVehicleByName(vehicle.name!)
        if newVehicle != nil{
            newVehicle!.name = vehicle.name
            newVehicle!.module = vehicle.module
            newVehicle!.v2model = vehicle.v2model
            newVehicle!.year = vehicle.year
            do {
                try newVehicle!.managedObjectContext!.save()
            } catch {
                fatalError("couldn't save context")
            }
        }
    }
    
    func deleteVehicleByName(name : String){
        printVDBG("deleteVehicle")
        let result = fetchVehicleByName(name)
        if result != nil {
        printDBG("result: \(result!.name)")
        self.managedObjectContext.deleteObject(result!)
        do {
            try self.managedObjectContext.save()
        } catch {
            let saveError = error as NSError
            printVDBG("\(saveError)")
        }
        }
    }
}
