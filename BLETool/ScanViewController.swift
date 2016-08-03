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
    
    var deviceName : [String] = []
    var deviceWithRssi = [String : Int]()
    var devices : [CBPeripheral] = []
    var selectedName : String = ""
    
    var dataController : DataController!
    var appDelegeate : AppDelegate!
    var vehicles : [Vehicle] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.dataSource = self
        tableView.delegate = self
        centralManager = CBCentralManager(delegate: self, queue:nil)
        appDelegeate = UIApplication.sharedApplication().delegate as! AppDelegate
        dataController = appDelegeate.dataController
        tableView.separatorStyle = UITableViewCellSeparatorStyle.None
    }
    
    @IBAction func onBack(sender: UIButton) {
        print("return to garage scene")
        performSegueWithIdentifier("segueBackToGarage", sender: sender)
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return deviceName.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("ScanCell", forIndexPath: indexPath) as! CustomScanCell
        let deviceNameString = deviceName[indexPath.row] as String
        cell.labelName!.text = deviceNameString
        let rssi = deviceWithRssi[deviceNameString]
        if rssi != nil {
            if rssi > -30 && rssi < -50 {
                cell.imageSignal.setImage(UIImage(named: "High Connection"), forState: .Normal)
            }else if rssi >= -50 && rssi < -70 {
                cell.imageSignal.setImage(UIImage(named: "Medium Connection"), forState: .Normal)
                
            }else if rssi >= -70{
                cell.imageSignal.setImage(UIImage(named: "Low Connection"), forState: .Normal)
            }
        }
        let whiteRoundedView : UIView = UIView(frame: CGRectMake(0, 10, self.view.frame.size.width, 120))
        
        whiteRoundedView.layer.backgroundColor = CGColorCreate(CGColorSpaceCreateDeviceRGB(), [1.0, 1.0, 1.0, 1.0])
        whiteRoundedView.layer.masksToBounds = false
        whiteRoundedView.layer.cornerRadius = 4.0
        whiteRoundedView.layer.shadowOffset = CGSizeMake(-1, 1)
        whiteRoundedView.layer.shadowOpacity = 0.2
//        cell.layer.cornerRadius = 6
//        cell.layer.masksToBounds = true
//        cell.layer.shadowColor = UIColor.blackColor().CGColor
//        cell.layer.shadowOffset = CGSizeMake(0, 1)
//        cell.layer.shadowRadius = 5
//        cell.layer.shadowOpacity = 1.0
        cell.contentView.addSubview(whiteRoundedView)
        cell.contentView.sendSubviewToBack(whiteRoundedView)
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        selectedName = deviceName[indexPath.row] as String
        print("\(selectedName)")
        var existing = false
        if vehicles.count > 0 {
            for vehicle in vehicles {
                if vehicle.name?.rangeOfString(selectedName) != nil {
                    existing = true
                    print("vehicle existing, exiting for loop")
                    break
                }
            }
        }
        
        if !existing {
            //            dataController.saveVehicle(selectedName, address: selectedName)
            performSegueWithIdentifier("segueToRegister", sender: nil)
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
        //            (advertisementData as NSDictionary).objectForKey(CBAdvertisementDataLocalNameKey) as! NSString
        peripheral.readRSSI()
        print("\(nameOfDeviceFound) Found")
        devices.append(peripheral)
        deviceName.append("\(nameOfDeviceFound!)")
        tableView.reloadData()
        if nameOfDeviceFound!.rangeOfString("EVO") != nil {
            //            centralManager.stopScan()
        }
        //        self.peripheral = peripheral
        //        self.peripheral.delegate = self
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
        if segue.identifier == "segueToRegister" {
            print("prepareForSegue -> register scene")
            print("now select name is \(selectedName)")
            let dest = segue.destinationViewController as! RegisterViewController
            dest.name = selectedName
        }
    }}
