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
    let DBG = true
    let VDBG = false
    var devices : [CBPeripheral] = []
    var deviceWithRssi = Dictionary<String,Int>()
    var selectedName : String = ""
    var vehicles : [Vehicle] = []
    var lastScene : String = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        printVDBG("viewDidLoad")
        centralManager = CBCentralManager(delegate: self, queue:nil)
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title:"", style:.Plain, target:nil, action:nil)
    }
    
    override func viewWillAppear(animated: Bool) {
        printVDBG("viewWillAppear")
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        let dataController = appDelegate.dataController
        vehicles = dataController.getAllVehicles()
        
    }
    
    override func viewDidAppear(animated: Bool) {
        printVDBG("viewDidAppear")
        lastScene = getLastScene()
        tableView.dataSource = self
        tableView.delegate = self
        animateTableView(false)
        setLastScene()
        
    }
    
    @IBAction func onBack(sender: UIButton) {
        printVDBG("return to garage scene")
        performSegueWithIdentifier("segueBackToGarage", sender: sender)
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return devices.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("ScanCell", forIndexPath: indexPath) as! CustomScanCell
        let deviceName = devices[indexPath.row].name! as String
        cell.labelName!.text = deviceName
        let rssi = deviceWithRssi[deviceName]
        
        if rssi != nil {
            printVDBG("rssi : \(rssi)")
            cell.labelValue.text = "\(rssi!)"
            if rssi < 0 && rssi > -50 {
                cell.imageSignal.setImage(UIImage(named: "High Connection"), forState: .Normal)
            }else if rssi <= -50 && rssi > -70 {
                cell.imageSignal.setImage(UIImage(named: "Medium Connection"), forState: .Normal)
            }else if rssi <= -70{
                cell.imageSignal.setImage(UIImage(named: "Low Connection"), forState: .Normal)
            }
        }else{
            printVDBG("rssi is nil")
        }
        let tableWidth : CGFloat = tableView.bounds.size.width
        cell.mainView.layer.cornerRadius = 2.0
        if lastScene == "Garage" {
            cell.transform = CGAffineTransformMakeTranslation(tableWidth, 0)
        }else if lastScene == "Register" {
            cell.transform = CGAffineTransformMakeTranslation(-tableWidth, 0)
        }
        UIView.animateWithDuration(1.5, delay: 0.2, usingSpringWithDamping: 0.8, initialSpringVelocity: 0, options: UIViewAnimationOptions.CurveEaseIn, animations: {
            cell.transform = CGAffineTransformMakeTranslation(0, 0)
            }, completion: nil)
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        selectedName = devices[indexPath.row].name! as String
        printVDBG("didSelectRowAtIndexPath : \(selectedName)")
        var existing = false
        if vehicles.count > 0 {
            for vehicle in vehicles {
                if vehicle.module?.rangeOfString(selectedName) != nil {
                    existing = true
                    printVDBG("vehicle exists")
                    break
                }
            }
        }
        centralManager.stopScan()
        if !existing {
            performSegueWithIdentifier("scan2register", sender: nil)
        }else{
            printVDBG("return to garage scene")
            showAlert()
            //            self.navigationController?.popViewControllerAnimated(true)
        }
    }
    
    func showAlert() {
        if NSClassFromString("UIAlertController") != nil {
            let alertController = UIAlertController(title: "Again?", message: "This one is registered already", preferredStyle: UIAlertControllerStyle.Alert)
            presentViewController(alertController, animated: true, completion:{
                alertController.view.superview?.userInteractionEnabled = true
                alertController.view.superview?.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.alertControllerBackgroundTapped)))
            })
        }
    }
    
    func alertControllerBackgroundTapped()    {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func centralManagerDidUpdateState(central: CBCentralManager) {
        switch(central.state){
        case .PoweredOn:
            printVDBG("CBCentralManagerState.PoweredOn")
            centralManager.scanForPeripheralsWithServices(nil, options: nil)
            printVDBG("scanForPeripheralsWithServices")
            break
        case .PoweredOff:
            printVDBG("CBCentralManagerState.PoweredOff")
            centralManager.stopScan()
            break
        case .Unauthorized:
            printVDBG("CBCentralManagerState.Unauthorized")
            break
        case .Resetting:
            printVDBG("CBCentralManagerState.Resetting")
            break
        case .Unknown:
            printVDBG("CBCentralManagerState.Unknown")
            break
        case .Unsupported:
            printVDBG("CBCentralManagerState.Unsupported")
            break
        }
    }
    
    func centralManager(central: CBCentralManager, didDiscoverPeripheral peripheral: CBPeripheral, advertisementData: [String : AnyObject], RSSI: NSNumber) {
        printVDBG("didDiscoverPeripheral")
        let nameOfDeviceFound = peripheral.name
        if nameOfDeviceFound != nil {
            printVDBG("\(nameOfDeviceFound!) Found")
            devices.append(peripheral)
            deviceWithRssi[peripheral.name!] = RSSI.integerValue
            tableView.reloadData()
        }
    }
    
    func centralManager(central: CBCentralManager, didConnectPeripheral peripheral: CBPeripheral) {
        printVDBG("didConnectPeripheral : \(peripheral.name)")
    }
    
    func centralManager(central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: NSError?) {
        printVDBG("didDisconnectPeripheral")
        central.scanForPeripheralsWithServices(nil, options: nil)
    }
    
    func peripheral(peripheral: CBPeripheral, didUpdateValueForCharacteristic characteristic: CBCharacteristic, error: NSError?) {
        printVDBG("Characteristic value updated")
    }
    
    func peripheral(peripheral: CBPeripheral, didDiscoverServices error: NSError?) {
        printVDBG("Discovering services & characteristics")
        
    }
    
    func peripheral(peripheral: CBPeripheral, didDiscoverCharacteristicsForService service: CBService, error: NSError?) {
        
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "scan2register" {
            printVDBG("prepareForSegue -> register scene")
            printVDBG("now select name is \(selectedName)")
            let dest = segue.destinationViewController as! RegisterViewController
            dest.module = selectedName
        }
    }
    
    func animateTableView(vertical : Bool){
        tableView.reloadData()
        var index = 0
        let cells = tableView.visibleCells
        let tableHeight : CGFloat = tableView.bounds.size.height
        let tableWidth : CGFloat = tableView.bounds.size.width
        if vertical {
            for i in cells {
                let cell : UITableViewCell = i as UITableViewCell
                cell.transform = CGAffineTransformMakeTranslation(0, tableHeight)
            }
        } else {
            for cell in cells {
                //old expression                let cell : UITableViewCell = i as UITableViewCell
                if lastScene == "Garage" || lastScene == "Control"{
                    cell.transform = CGAffineTransformMakeTranslation(tableWidth, 0)
                }else if lastScene == "Register" {
                    cell.transform = CGAffineTransformMakeTranslation(-tableWidth, 0)
                }
            }
        }
        for cell in cells {
            //old expression           let cell : UITableViewCell = j as UITableViewCell
            UIView.animateWithDuration(1, delay: 0.05 * Double(index), usingSpringWithDamping: 0.8, initialSpringVelocity: 0, options: UIViewAnimationOptions.CurveEaseIn, animations: {
                cell.transform = CGAffineTransformMakeTranslation(0, 0)
                }, completion: nil)
            index += 1
        }
    }
    
    func addLayer(){
        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = self.view.bounds
        let colorTop = UIColor.clearColor().CGColor
        let colorBottom = UIColor.whiteColor().CGColor
        gradientLayer.colors = [colorTop, colorBottom]
        self.view.layer.addSublayer(gradientLayer)
    }
    
    func getLastScene() -> String{
        printVDBG("getLastScene")
        let lastScene =
            NSUserDefaults.standardUserDefaults().objectForKey("lastScene")
                as? String
        if lastScene != nil {
            return lastScene!
        }else{
            return ""
        }
    }
    
    func setLastScene(){
        printVDBG("getLsetLastScene : Scan")
        NSUserDefaults.standardUserDefaults().setObject("Scan", forKey: "lastScene")
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
        
        return "[\(components.hour):\(components.minute):\(components.second)] - Scan - "
    }
}


