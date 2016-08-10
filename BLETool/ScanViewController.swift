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
    
    
    @IBOutlet var topBar: UIView!
    @IBOutlet var tableView: UITableView!
    
    var moduleNames : [String] = []
    var deviceWithRssi = [String : Int]()
    var devices : [CBPeripheral] = []
    var selectedName : String = ""
    
    var dataController : DataController!
    var appDelegeate : AppDelegate!
    var vehicles : [Vehicle] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        centralManager = CBCentralManager(delegate: self, queue:nil)
        appDelegeate = UIApplication.sharedApplication().delegate as! AppDelegate
        dataController = appDelegeate.dataController
        
    }
    
    
    override func viewDidAppear(animated: Bool) {
        tableView.dataSource = self
        tableView.delegate = self
        tableView.cellLayoutMarginsFollowReadableWidth = false
        tableView.layoutMargins = UIEdgeInsetsZero
        tableView.separatorInset = UIEdgeInsetsZero
        
        
        tableView.separatorStyle = UITableViewCellSeparatorStyle.None
        animateTableView()
    }
    @IBAction func onBack(sender: UIButton) {
        print("return to garage scene")
        performSegueWithIdentifier("segueBackToGarage", sender: sender)
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return moduleNames.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("ScanCell", forIndexPath: indexPath) as! CustomScanCell
        let moduleNameString = moduleNames[indexPath.row] as String
        cell.labelName!.text = moduleNameString
        let rssi = deviceWithRssi[moduleNameString]
        
        if rssi != nil {
            if rssi > -30 && rssi < -50 {
                cell.imageSignal.setImage(UIImage(named: "High Connection"), forState: .Normal)
            }else if rssi >= -50 && rssi < -70 {
                cell.imageSignal.setImage(UIImage(named: "Medium Connection"), forState: .Normal)
                
            }else if rssi >= -70{
                cell.imageSignal.setImage(UIImage(named: "Low Connection"), forState: .Normal)
            }
        }
        
        cell.mainView.layer.cornerRadius = 5.0
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        selectedName = moduleNames[indexPath.row] as String
        print("\(selectedName)")
        var existing = false
        if vehicles.count > 0 {
            for vehicle in vehicles {
                if vehicle.module?.rangeOfString(selectedName) != nil {
                    existing = true
                    print("vehicle exists")
                    break
                }
            }
        }
        centralManager.stopScan()
        if !existing {
            performSegueWithIdentifier("scan2register", sender: nil)
        }else{
            print("return to garage scene")
            self.navigationController?.popViewControllerAnimated(true)
        }
    }
    
    func centralManagerDidUpdateState(central: CBCentralManager) {
        switch(central.state){
        case CBCentralManagerState.PoweredOn:
            print("powered on")
            centralManager.scanForPeripheralsWithServices(nil, options: nil)
            print("scan for peripherals")
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
        let nameOfDeviceFound = peripheral.name
        if nameOfDeviceFound != nil {
            peripheral.readRSSI()
            print("\(nameOfDeviceFound) Found")
            devices.append(peripheral)
            moduleNames.append("\(nameOfDeviceFound!)")
            tableView.reloadData()
            if nameOfDeviceFound!.rangeOfString("EVO") != nil {
                
            }
        }
    }
    
    func peripheralDidUpdateRSSI(peripheral: CBPeripheral, error: NSError?) {
        print("\(peripheral.name!) updated : \(peripheral.RSSI?.integerValue)")
        deviceWithRssi[peripheral.name!] = peripheral.RSSI?.integerValue
        tableView.reloadData()
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
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "scan2register" {
            print("prepareForSegue -> register scene")
            print("now select name is \(selectedName)")
            let dest = segue.destinationViewController as! RegisterViewController
            dest.module = selectedName
        }
    }
    
    func animateTableView(){
        tableView.reloadData()
        
        let cells = tableView.visibleCells
        let tableHeight : CGFloat = tableView.bounds.size.height
        
        for i in cells {
            let cell : UITableViewCell = i as UITableViewCell
            cell.transform = CGAffineTransformMakeTranslation(0, tableHeight)
        }
        
        var index = 0
        
        for j in cells {
            let cell : UITableViewCell = j as UITableViewCell
            UIView.animateWithDuration(1.5, delay: 0.05 * Double(index), usingSpringWithDamping: 0.8, initialSpringVelocity: 0, options: UIViewAnimationOptions.CurveEaseIn, animations: {
                cell.transform = CGAffineTransformMakeTranslation(0, 0)
                }, completion: nil)
            index += 1
        }
    }
}


