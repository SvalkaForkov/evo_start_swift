//
//  ScanViewController.swift
//  BLETool
//
//  Created by Xiaotu Zhang on 2016-06-14.
//  Copyright © 2016 fortin. All rights reserved.
//

import UIKit
import CoreBluetooth

class ScanViewController: UIViewController ,UITableViewDataSource, UITableViewDelegate, CBCentralManagerDelegate, CBPeripheralDelegate{
    
    var centralManager:CBCentralManager!
    var peripheral : CBPeripheral!
    
    @IBOutlet var tableView: UITableView!
    @IBOutlet var topBar: UIView!
    
    var deviceName : [NSString] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.dataSource = self
        tableView.delegate = self
        centralManager = CBCentralManager(delegate: self, queue:nil)
        
        let cons1 = tableView.topAnchor.constraintEqualToAnchor(topBar.bottomAnchor)
        let cons2 = topBar.heightAnchor.constraintEqualToConstant(56)
        NSLayoutConstraint.activateConstraints([cons1,cons2])
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return deviceName.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("ScanCell", forIndexPath: indexPath)
        cell.textLabel!.text = deviceName[indexPath.row] as? String
        return cell
    }
    
    func centralManagerDidUpdateState(central: CBCentralManager) {
        switch(central.state){
        case CBCentralManagerState.PoweredOn:
            print("powered on")
            centralManager.scanForPeripheralsWithServices(nil, options: nil)
            break
        case CBCentralManagerState.PoweredOff:
            print("powered on")
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
        let nameOfDeviceFound = (advertisementData as NSDictionary).objectForKey(CBAdvertisementDataLocalNameKey) as! NSString
        print("\(nameOfDeviceFound) Found")
        deviceName.append("\(nameOfDeviceFound)")
        tableView.reloadData()
        let i = peripheral.name
        print("Stop scanning after \(i) device found")
        self.peripheral = peripheral
        self.peripheral.delegate = self
    }
    
    func centralManager(central: CBCentralManager, didConnectPeripheral peripheral: CBPeripheral) {
        print("Peripheral connected")
        
    }
    
    func centralManager(central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: NSError?) {
        print("Disconnected")
        central.scanForPeripheralsWithServices(nil, options: nil)
    }
    
    func peripheral(peripheral: CBPeripheral, didUpdateValueForCharacteristic characteristic: CBCharacteristic, error: NSError?) {
        print("Characteristic value updated")
    }
    
    func peripheral(peripheral: CBPeripheral, didDiscoverServices error: NSError?) {
        print("Discovering services & characteristics")
        
    }
    func peripheral(peripheral: CBPeripheral, didDiscoverCharacteristicsForService service: CBService, error: NSError?) {
        
    }
}
