//
//  TableViewController.swift
//  BLETool
//
//  Created by Xiaotu Zhang on 2016-06-14.
//  Copyright © 2016 fortin. All rights reserved.
//

import UIKit
import CoreBluetooth


class GarageViewController: UIViewController ,UITableViewDataSource, UITableViewDelegate, CBCentralManagerDelegate, CBPeripheralDelegate{

    var centralManager:CBCentralManager!
    var peripheral : CBPeripheral!
    
    @IBAction func onAddVehicle(sender: UIButton) {
        
    }

    
    @IBOutlet var tableView: UITableView!
    @IBOutlet var topBar: UIView!
    
    var vehicles = [""]
    var selectedName = ""
    
    override func viewWillAppear(animated: Bool) {
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let cons1 = tableView.topAnchor.constraintEqualToAnchor(topBar.bottomAnchor)
        let cons2 = topBar.heightAnchor.constraintEqualToConstant(56)
        NSLayoutConstraint.activateConstraints([cons1,cons2])
        tableView.dataSource = self
        tableView.delegate = self
        centralManager = CBCentralManager(delegate: self, queue:nil)
        let appDelegate  = UIApplication.sharedApplication().delegate as! AppDelegate
          print("garage loaded")
        let ve = appDelegate.dataController
          print("garage loaded")
        // Do any additional setup after loading the view.
    }

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return vehicles.count
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("GarageItem", forIndexPath: indexPath)
        cell.textLabel!.text = vehicles[indexPath.row]
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        selectedName = vehicles[indexPath.row]
        print("\(selectedName)")
        self.performSegueWithIdentifier("segueToControl", sender: indexPath)
    }
    func centralManagerDidUpdateState(central: CBCentralManager) {
        switch(central.state){
        case CBCentralManagerState.PoweredOn:
            print("powered on")
            centralManager.scanForPeripheralsWithServices(nil, options: nil)
            print("scanning")
            break
        case CBCentralManagerState.PoweredOff:
            print("powered off")
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
        //let nameOfDeviceFound = (advertisementData as NSDictionary).objectForKey(CBAdvertisementDataLocalNameKey) as! NSString
        tableView.reloadData()
        print("reload")
        let peripheralName = peripheral.name
        if vehicles.contains(""){
            vehicles = ["\(peripheralName)"]
        }else{
            vehicles.append("\(peripheralName)")
        }
        print("set name")
        self.peripheral = peripheral
        self.peripheral.delegate = self
        central.stopScan()
    }
    func centralManager(central: CBCentralManager, didConnectPeripheral peripheral: CBPeripheral) {
        print("Peripheral connected")
        
    }

    func centralManager(central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: NSError?) {
        print("Disconnected")
        central.scanForPeripheralsWithServices(nil, options: nil)
    }
    
    func peripheral(peripheral: CBPeripheral, didUpdateValueForCharacteristic characteristic: CBCharacteristic, error: NSError?) {
        
    }
    
    func peripheral(peripheral: CBPeripheral, didDiscoverServices error: NSError?) {
        print("Discovering services & characteristics")
        
    }
    
    func peripheral(peripheral: CBPeripheral, didDiscoverCharacteristicsForService service: CBService, error: NSError?) {
        
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "segueToControl" {
            print("go to control scene")
            print("\(selectedName)")
            let dest = segue.destinationViewController as! ViewController
            dest.name = selectedName
        }
        print("")
    }
}
