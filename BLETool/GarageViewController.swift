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
    let DBG = true
    let VDBG = false
    var flagDemo = false
    
    @IBOutlet var buttonAdd: UIButton!
    @IBOutlet var tableView: UITableView!
    
    let tag_default_module = "defaultModule"
    var centralManager:CBCentralManager!
    var dataController : DataController?
    var appDelegate: AppDelegate?
    
    var vehicleList : [Vehicle] = []
    var selectedModule = ""
    var isFound = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        printVDBG("View did load")
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title:"", style:.Plain, target:nil, action:nil)
    }
    
    override func viewWillAppear(animated: Bool) {
        flagDemo = getDemoFlag()
        buttonAdd.clipsToBounds = true
        
        tableView.dataSource = self
        tableView.delegate = self
        
        if !flagDemo {
            printVDBG("View will appear")
            appDelegate = UIApplication.sharedApplication().delegate as? AppDelegate
            dataController = appDelegate!.dataController
            
            vehicleList = dataController!.getAllVehicles()
            if vehicleList.count == 0 {
                printVDBG("No vehicle")
            }else{
                printVDBG("Found vehicle : \(vehicleList.count)")
            }
            
            animateTableView(false)
            centralManager = CBCentralManager(delegate: self, queue:nil)
        }else{
            printDBG("Demo mode : On")
            buttonAdd.hidden = true
        }
    }
    
    override func viewDidAppear(animated: Bool) {
        printVDBG("GarageViewController: viewDidAppear")
        setLastScene()
        let currentDefault = self.getDefaultModuleName()
        self.printDBG("Current default : \(currentDefault)")    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if !flagDemo {
            return vehicleList.count
        }else{
            return 1
        }
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("GarageCell", forIndexPath: indexPath) as! CustomGarageCell
        cell.contentView.layer.cornerRadius = 0.0
        if !flagDemo {
            cell.labelName!.text = vehicleList[indexPath.row].name!.capitalizedString
            let model = vehicleList[indexPath.row].v2model!
            let make : Make! =  model.model2make
            cell.logo.image = UIImage(named: make.title!)
            cell.labelMake!.text = make!.title!.capitalizedString
            cell.labelModel!.text = vehicleList[indexPath.row].v2model!.title!.capitalizedString
        }else{
            cell.labelName!.text = "Demo"
            cell.logo.image = UIImage(named: "AppIcon")
            cell.labelMake!.text = "Demo"
            cell.labelModel!.text = "Demo"
        }
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if !flagDemo {
            selectedModule = vehicleList[indexPath.row].module!
            printVDBG("click \(selectedModule)")
            
            isFound = false
            if centralManager != nil {
                centralManager.scanForPeripheralsWithServices(nil, options: nil)
                printVDBG("scan for selected module")
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
                    self.printVDBG("starting to find selected module")
                    sleep(2)
                    dispatch_async(dispatch_get_main_queue(),{
                        if !self.isFound {
                            self.printDBG("No match module found")
                            if self.centralManager.isScanning {
                                self.centralManager.stopScan()
                            }
                            self.showAlert()
                        }
                    })
                })
            }
        }else{
            printVDBG("click in demo mode")
            setSelectedModuleInTable("")
            self.navigationController?.popToRootViewControllerAnimated(true)
        }
        tableView.deselectRowAtIndexPath(indexPath, animated: false)
    }
    
    func showAlert() {
        if NSClassFromString("UIAlertController") != nil {
            let alertController = UIAlertController(title: "Info", message: "Failed to connect", preferredStyle: UIAlertControllerStyle.Alert)
            presentViewController(alertController, animated: true, completion:{
                alertController.view.superview?.userInteractionEnabled = true
                alertController.view.superview?.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.alertControllerBackgroundTapped)))
            })
        }
    }
    
    func alertControllerBackgroundTapped()    {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {    }
    
    
    func setDefaultModule(value: String){
        printVDBG("Set default module : \(value)")
        NSUserDefaults.standardUserDefaults().setObject(value, forKey: tag_default_module)
    }
    
    func tableView(tableView: UITableView, editActionsForRowAtIndexPath indexPath: NSIndexPath) -> [UITableViewRowAction]? {
        let favorite = UITableViewRowAction(style: .Default, title: "Set\nDefault") { action, index in
            self.printVDBG("favorite button tapped")
            if !self.flagDemo {
                let vehicleToFavorate : String! = self.vehicleList[indexPath.row].module
                self.setDefaultModule(vehicleToFavorate)
            }else{
                self.printDBG("This will set vehicle to favorite")
            }
            self.tableView.setEditing(false, animated: true)
        }
        favorite.backgroundColor = UIColor.orangeColor()
        
        let delete = UITableViewRowAction(style: .Normal, title: "Delete ") { action, index in
            if !self.flagDemo {
                let vehicleToDelete : String! = self.vehicleList[indexPath.row].module
                self.printDBG("Vehicle to Delete : \(vehicleToDelete)")
                let currentDefault = self.getDefaultModuleName()
                self.printDBG("Current default : \(currentDefault)")
                if vehicleToDelete == currentDefault {
                    self.vehicleList.removeAtIndex(indexPath.row)
                    tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.Automatic)
                    self.dataController!.deleteVehicleByName(vehicleToDelete)
                    if self.vehicleList.count == 0 {
                        self.setDefault("")
                        self.printDBG("Clear default")
                    }else{
                        self.setDefault(self.vehicleList[0].module!)
                    }
                }else{
                    print("\(indexPath.row)")
                    self.vehicleList.removeAtIndex(indexPath.row)
                    tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.Automatic)
                    self.dataController!.deleteVehicleByName(vehicleToDelete)
                    self.printDBG("Deleting non-favorite car\(vehicleToDelete)")
                }
                print("\(indexPath.row)")
            }else{
                self.printDBG("In demo mode : This will delete vehicle")
                self.tableView.setEditing(false, animated: true)
            }
        }
        delete.backgroundColor = UIColor.redColor()
        
        return [delete, favorite]
    }
    
    func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // the cells you would like the actions to appear needs to be editable
        return true
    }
    
    func centralManagerDidUpdateState(central: CBCentralManager) {
        switch(central.state){
        case .PoweredOn:
            printVDBG("CBCentralManagerState.PoweredOn")
            break
        case .PoweredOff:
            printVDBG("CBCentralManagerState.PoweredOff")
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
        let nameOfDeviceFound = peripheral.name as String!
        if nameOfDeviceFound != nil {
            printVDBG("Did discover \(nameOfDeviceFound)")
            printVDBG("Selected module is \(selectedModule)")
            if nameOfDeviceFound == selectedModule{
                printVDBG("Match")
                isFound = true
                if centralManager.isScanning {
                    centralManager.stopScan()
                }
                printVDBG("Stop scanning after \(nameOfDeviceFound) device found")
                centralManager = nil
                setSelectedModuleInTable(selectedModule)
                self.navigationController?.popToRootViewControllerAnimated(true)
            }
        }
    }
    
    @IBAction func onAddVehicle(sender: UIButton) {
        printVDBG("aGarageViewController : dd click vehicle")
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
        printVDBG("Set default : \(value)")
        NSUserDefaults.standardUserDefaults().setObject(value, forKey: tag_default_module)
        let defaultModule =
            NSUserDefaults.standardUserDefaults().objectForKey(tag_default_module)
                as? String
        printVDBG("Default now is : \(defaultModule)")
    }
    
    func getDefaultModuleName() -> String{
        printVDBG("Get Default Module Name")
        let defaultModule = NSUserDefaults.standardUserDefaults().objectForKey(tag_default_module)
            as? String
        if defaultModule != nil {
            printVDBG("default is not nil : \(defaultModule)")
            return defaultModule!
        }else{
            printVDBG("default is nil")
            return ""
        }
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "garage2control" {
            printVDBG("prepareForSegue -> control scene")
            printVDBG("now select name is \(selectedModule)")
            let dest = segue.destinationViewController as! ViewController
            dest.module = selectedModule
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
                if getLastScene() == "Control" {
                    cell.transform = CGAffineTransformMakeTranslation(tableWidth, 0)
                }else if getLastScene() == "Scan" {
                    cell.transform = CGAffineTransformMakeTranslation(-tableWidth, 0)
                }
            }
        }
        
        for cell in cells {
            UIView.animateWithDuration(1, delay: 0.05 * Double(index), usingSpringWithDamping: 0.8, initialSpringVelocity: 0, options: UIViewAnimationOptions.CurveEaseIn, animations: {
                cell.transform = CGAffineTransformMakeTranslation(0, 0)
                }, completion: nil)
            index += 1
        }
    }
    
    func getLastScene() -> String{
        let lastScene =
            NSUserDefaults.standardUserDefaults().objectForKey("lastScene")
                as? String
        if lastScene != nil {
            printVDBG("Get last scene : \(lastScene)")
            return lastScene!
        }else{
            printVDBG("Get last scene : None")
            return ""
        }
    }
    
    func setLastScene(){
        printVDBG("Set last scene : Garage")
        NSUserDefaults.standardUserDefaults().setObject("Garage", forKey: "lastScene")
    }
    
    func setSelectedModuleInTable(value : String){
        printVDBG("Set selected car")
        NSUserDefaults.standardUserDefaults().setObject(value, forKey: "selectedModule")
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
        var h = "\(components.hour)"
        if components.hour < 10 {
            h = "0\(components.hour)"
        }
        var m = "\(components.minute)"
        if components.minute < 10 {
            m = "0\(components.minute)"
        }
        var s = "\(components.second)"
        if components.second < 10 {
            s = "0\(components.second)"
        }
        return "[\(h):\(m):\(s)] - Garage - "
    }
    
    func getDemoFlag() -> Bool{
        let flag =
            NSUserDefaults.standardUserDefaults().objectForKey("flagDemo")
                as? Bool
        printDBG("Get demo flag : \(flag!)")
        return flag!
    }
}
