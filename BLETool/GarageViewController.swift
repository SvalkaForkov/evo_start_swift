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
    
    @IBAction func onAddVehicle(sender: UIButton) {
        print("add click vehicle")
        
    }
    
    @IBOutlet var buttonAdd: UIButton!
    @IBOutlet var tableView: UITableView!
    @IBOutlet var topBar: UIView!
    var centralManager:CBCentralManager!
    var vehicles : [Vehicle] = []
    var selectedName = ""
    
    override func viewWillAppear(animated: Bool) {
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        let dataController = appDelegate.dataController
        
        print("setting up delegate and core data")
        vehicles = dataController.getAllVehicles()
        print("fetching vehicle list")
        tableView.dataSource = self
        tableView.delegate = self
        tableView.separatorStyle = UITableViewCellSeparatorStyle.None
        tableView.cellLayoutMarginsFollowReadableWidth = false
        tableView.layoutMargins = UIEdgeInsetsZero
        tableView.separatorInset = UIEdgeInsetsZero
        centralManager = CBCentralManager(delegate: self, queue:nil)
        if vehicles.count == 0 {
            print("no vehicle")
        }else{
            //            buttonAdd.hidden = true
            print("found vehicle")
        }
    }
    
    func centralManagerDidUpdateState(central: CBCentralManager) {
        switch(central.state){
        case CBCentralManagerState.PoweredOn:
            print("Ble PoweredOn")
            print("Scanning bluetooth")
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
            print("and name is \(selectedName)")
            if nameOfDeviceFound == selectedName{
                print("Match")
                centralManager.stopScan()
                print("Stop scanning after \(nameOfDeviceFound) device found")
                setDefault(selectedName)
                centralManager = nil
                self.navigationController?.popToRootViewControllerAnimated(true)
            }
        }
    }
    
    func setDefault(value: String){
        print("set default : \(value)")
        NSUserDefaults.standardUserDefaults().setObject(value, forKey: "default")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("garage viewDidLoad")
        
        
        //        let cons1 = tableView.topAnchor.constraintEqualToAnchor(topBar.bottomAnchor)
        //        let cons2 = topBar.heightAnchor.constraintEqualToConstant(56)
        //        NSLayoutConstraint.activateConstraints([cons1,cons2])
        //        print("Set constrains to top bar")
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return vehicles.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("GarageCell", forIndexPath: indexPath) as! CustomCell
        
        cell.mainView.layer.cornerRadius = 5.0
        cell.label1!.text = vehicles[indexPath.row].name
        cell.label2!.text = vehicles[indexPath.row].make
        cell.label3!.text = vehicles[indexPath.row].model
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        selectedName = vehicles[indexPath.row].name!
        print("click \(selectedName)")
        centralManager.scanForPeripheralsWithServices(nil, options: nil)
        tableView.deselectRowAtIndexPath(indexPath, animated: false)
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "garage2control" {
            print("prepareForSegue -> control scene")
            print("now select name is \(selectedName)")
            let dest = segue.destinationViewController as! ViewController
            dest.name = selectedName
        }
    }
}
