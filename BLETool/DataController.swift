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
    
    init(moc: NSManagedObjectContext) {
        self.managedObjectContext = moc
        print("DataController : init moc")
    }
    
//    func initialDatabase(){
//        let data = [
//            ["CL","Acura"],["CSX","Acura"],["EL","Acura"],["ILX","Acura"],["Integra","Acura"],["MDX","Acura"],["RDX","Acura"],["RL","Acura"],["RLX","Acura"],
//            ["RSX","Acura"],["SLX","Acura"],["TL","Acura"],["TLX","Acura"],["TSX","Acura"],["Vigor","Acura"],["ZDX","Acura"],
//            ["MV1","AM General"],
//            ["A1","Audi"],["A4","Audi"],["A4 Allroad","Audi"],["A5","Audi"],["A5 Cabriolet","Audi"],["A6","Audi"],["A7","Audi"],["A8","Audi"],["Q3","Audi"],["Q5","Audi"],["Q7","Audi"],
//            ["R8","Audi"],["RS4","Audi"],["RS5","Audi"],["RS7","Audi"],["S3","Audi"],["S4","Audi"],["S5","Audi"],["S6","Audi"],["S7","Audi"],["S8","Audi"],["SQ5","Audi"],["TT","Audi"],
//            ["1 Series","BMW"],["2 Series","BMW"],["3 Series Coupe","BMW"],["3 Series","BMW"],["5 Series","BMW"],["6 Series","BMW"],["M1","BMW"],["M3","BMW"],["M5","BMW"],["M6","BMW"],
//            ["X1","BMW"],["X4","BMW"],["X5","BMW"],["X5 Diesel","BMW"],["X6","BMW"],["Z4","BMW"],
//            ["Allure","Buick"],["Century","Buick"],["Encore","Buick"],["Enclave","Buick"],["LaCrosse","Buick"],["LeSabre","Buick"],["Lucerne","Buick"],["Park Avenue","Buick"],["Rainier","Buick"],
//            ["Regal","Buick"],["Rendezvous","Buick"],["Reviera","Buick"],["Roadmaster","Buick"],["Skylark","Buick"],["Terraza","Buick"],["Verano","Buick"],
//            ["A1","Audi"],["A3","Audi"],["A4","Audi"],["A5","Audi"],["A6","Audi"],
//            ["C-Class","Mercedes-Benz"],["B-Class","Mercedes-Benz"],["E-Class","Mercedes-Benz"]
//        ]
//        for array in data {
//            insertModelAndMake(array[0], makeTitle: array[1])
//        }
//    }
    
//    func insertAll(data: [[String : String]]){
//        for array in data {
//            insertModelAndMake(array[0]!, makeTitle: array[1]!)
//        }
//    }
    
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
                do {
                    try self.managedObjectContext.save()
                } catch {
                    fatalError("Save context failed")
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
        print("DataController : fetched \(fetchedMakes!.count)")
        return fetchedMakes!
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
