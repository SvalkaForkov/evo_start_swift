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
        buttonAdd.layer.cornerRadius = 25.0
        buttonAdd.clipsToBounds = true
        buttonAdd.layer.borderWidth = 1
        buttonAdd.layer.borderColor = getColorFromHex(0x910015).CGColor
        
        if vehicles.count == 0 {
            print("no vehicle")
        }else{
            print("found vehicle")
        }
        
        animateTableView()
    }
    
    @IBAction func onAddVehicle(sender: UIButton) {
        print("aGarageViewController : dd click vehicle")
    }
    
    func getColorFromHex(value: UInt) -> UIColor{
        return UIColor(
            red: CGFloat((value & 0xFF0000) >> 16) / 255.0,
            green: CGFloat((value & 0x00FF00) >> 8) / 255.0,
            blue: CGFloat(value & 0x0000FF) / 255.0,
            alpha: CGFloat(1.0)
        )
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
        cell.mainView.layer.cornerRadius = 15.0
        
        cell.label1!.text = vehicles[indexPath.row].name!.capitalizedString
        cell.label2!.text = vehicles[indexPath.row].make!.capitalizedString
        cell.label3!.text = vehicles[indexPath.row].model!.capitalizedString
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
