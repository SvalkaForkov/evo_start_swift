//
//  TableViewController.swift
//  BLETool
//
//  Created by Xiaotu Zhang on 2016-06-14.
//  Copyright © 2016 fortin. All rights reserved.
//

import UIKit
import CoreBluetooth


class GarageViewController: UIViewController ,UITableViewDataSource, UITableViewDelegate,CBCentralManagerDelegate, CBPeripheralDelegate{
    
    @IBOutlet var buttonAdd: UIButton!
    @IBOutlet var tableView: UITableView!
    
    var centralManager:CBCentralManager!
    var vehicles : [Vehicle] = []
    var selectedModule = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("GarageViewController : garage viewDidLoad")
    }
    
    override func viewWillAppear(animated: Bool) {
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        let dataController = appDelegate.dataController
        print("GarageViewController : setting up delegate and core data")
        vehicles = dataController.getAllVehicles()
        print("GarageViewController : fetching vehicle list")
        tableView.dataSource = self
        tableView.delegate = self
        tableView.separatorStyle = UITableViewCellSeparatorStyle.None
        tableView.cellLayoutMarginsFollowReadableWidth = false
        centralManager = CBCentralManager(delegate: self, queue:nil)
        print("\(buttonAdd.layer.borderWidth)")
        buttonAdd.layer.cornerRadius = 19.0
        buttonAdd.clipsToBounds = true
        if vehicles.count == 0 {
            print("no vehicle")
        }else{
            print("found vehicle")
        }
    }
    
    @IBAction func onAddVehicle(sender: UIButton) {
        print("aGarageViewController : dd click vehicle")
    }
    
    func setDefault(value: String){
        print("Set default : \(value)")
        NSUserDefaults.standardUserDefaults().setObject(value, forKey: "defaultModule")
        let defaultModule =
            NSUserDefaults.standardUserDefaults().objectForKey("defaultModule")
                as? String
        print("Default now is : \(defaultModule)")
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return vehicles.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("GarageCell", forIndexPath: indexPath) as! CustomGarageCell
        cell.mainView.layer.cornerRadius = 5.0
        cell.label1!.text = vehicles[indexPath.row].name
        cell.label2!.text = vehicles[indexPath.row].make
        cell.label3!.text = vehicles[indexPath.row].model
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        selectedModule = vehicles[indexPath.row].module!
        print("click \(selectedModule)")
        centralManager.scanForPeripheralsWithServices(nil, options: nil)
        print("scan for selected module")
        tableView.deselectRowAtIndexPath(indexPath, animated: false)
    }
    
    func centralManagerDidUpdateState(central: CBCentralManager) {
        switch(central.state){
        case CBCentralManagerState.PoweredOn:
            print("Ble PoweredOn")
            break
        case CBCentralManagerState.PoweredOff:
            print("Ble PoweredOff")
            centralManager.stopScan()
            break
        case CBCentralManagerState.Unauthorized:
            print("Unauthorized state")
            break
        case CBCentralManagerState.Resetting:
            print("Resetting state")
            break
        case CBCentralManagerState.Unknown:
            print("unknown state")
            break
        case CBCentralManagerState.Unsupported:
            print("Unsupported state")
            break
        }
    }
    
    func centralManager(central: CBCentralManager, didDiscoverPeripheral peripheral: CBPeripheral, advertisementData: [String : AnyObject], RSSI: NSNumber) {
        let nameOfDeviceFound = peripheral.name as String!
        if nameOfDeviceFound != nil {
            print("Did discover \(nameOfDeviceFound)")
            print("Selected module is \(selectedModule)")
            if nameOfDeviceFound == selectedModule{
                print("Match")
                centralManager.stopScan()
                print("Stop scanning after \(nameOfDeviceFound) device found")
                setDefault(selectedModule)
                centralManager = nil
                self.navigationController?.popToRootViewControllerAnimated(true)
            }
        }
    }
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "garage2control" {
            print("prepareForSegue -> control scene")
            print("now select name is \(selectedModule)")
            let dest = segue.destinationViewController as! ViewController
            dest.module = selectedModule
        }
    }
}
