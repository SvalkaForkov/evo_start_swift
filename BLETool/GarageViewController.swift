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
    let tag_default_module = "defaultModule"
    var centralManager:CBCentralManager!
    var vehicles : [Vehicle] = []
    var selectedModule = ""
    var dataController : DataController?
    override func viewDidLoad() {
        super.viewDidLoad()
        print("GarageViewController : garage viewDidLoad")
    }
    
    override func viewWillAppear(animated: Bool) {
        setUpNavigationBar()
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        dataController = appDelegate.dataController
        print("GarageViewController : setting up delegate and core data")
        vehicles = dataController!.getAllVehicles()
        print("GarageViewController : fetching vehicle list")
        
        centralManager = CBCentralManager(delegate: self, queue:nil)
        print("\(buttonAdd.layer.borderWidth)")
        buttonAdd.clipsToBounds = true
        tableView.dataSource = self
        tableView.delegate = self
        
        if vehicles.count == 0 {
            print("no vehicle")
        }else{
            print("found vehicle")
        }
        animateTableView(false)
        
    }
    
    override func viewDidAppear(animated: Bool) {
        print("viewDidAppear")
        setLastScene()
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return vehicles.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("GarageCell", forIndexPath: indexPath) as! CustomGarageCell
        cell.mainView.layer.cornerRadius = 2.0
        cell.labelName!.text = vehicles[indexPath.row].name!.capitalizedString
        cell.labelMake!.text = vehicles[indexPath.row].make!.capitalizedString
        cell.labelModel!.text = vehicles[indexPath.row].model!.capitalizedString
        
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        selectedModule = vehicles[indexPath.row].module!
        print("click \(selectedModule)")
        centralManager.scanForPeripheralsWithServices(nil, options: nil)
        print("scan for selected module")
        tableView.deselectRowAtIndexPath(indexPath, animated: false)
    }
    
     func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == UITableViewCellEditingStyle.Delete {
            let vehicleToDelete = vehicles[indexPath.row]
            vehicles.removeAtIndex(indexPath.row)
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.Automatic)
            dataController!.deleteVehicleByName(vehicleToDelete.name!)
            let currentDefault = getDefaultModuleName()
            if vehicleToDelete.module == currentDefault {
                if vehicles.count == 0 {
                    setDefault("")
                }else{
                    setDefault(vehicles[0].module!)
                }
            }
        }
    }
    
    func centralManagerDidUpdateState(central: CBCentralManager) {
        switch(central.state){
        case CBCentralManagerState.PoweredOn:
            print("CBCentralManagerState.PoweredOn")
            break
        case CBCentralManagerState.PoweredOff:
            print("CBCentralManagerState.PoweredOff")
            centralManager.stopScan()
            break
        case CBCentralManagerState.Unauthorized:
            print("CBCentralManagerState.Unauthorized")
            break
        case CBCentralManagerState.Resetting:
            print("CBCentralManagerState.Resetting")
            break
        case CBCentralManagerState.Unknown:
            print("CBCentralManagerState.Unknown")
            break
        case CBCentralManagerState.Unsupported:
            print("CBCentralManagerState.Unsupported")
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
        NSUserDefaults.standardUserDefaults().setObject(value, forKey: tag_default_module)
        let defaultModule =
            NSUserDefaults.standardUserDefaults().objectForKey(tag_default_module)
                as? String
        print("Default now is : \(defaultModule)")
    }
    
    func getDefaultModuleName() -> String{
        print("Get Default Module Name")
        let defaultModule = NSUserDefaults.standardUserDefaults().objectForKey(tag_default_module)
            as? String
        if defaultModule != nil {
            print("default is not nil : \(defaultModule)")
            return defaultModule!
        }else{
            print("default is nil")
            return ""
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
                if getLastScene() == "Control" {
                    cell.transform = CGAffineTransformMakeTranslation(tableWidth, 0)
                }else if getLastScene() == "Scan" {
                    cell.transform = CGAffineTransformMakeTranslation(-tableWidth, 0)
                }
            }
        }
        for cell in cells {
            //old expression           let cell : UITableViewCell = j as UITableViewCell
            UIView.animateWithDuration(1.5, delay: 0.05 * Double(index), usingSpringWithDamping: 0.8, initialSpringVelocity: 0, options: UIViewAnimationOptions.CurveEaseIn, animations: {
                cell.transform = CGAffineTransformMakeTranslation(0, 0)
                }, completion: nil)
            index += 1
        }
    }
    
    func getLastScene() -> String{
        print("getLastScene")
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
        print("getLsetLastScene : Garage")
        NSUserDefaults.standardUserDefaults().setObject("Garage", forKey: "lastScene")
    }
    
    func setUpNavigationBar(){
        print("setUpNavigationBar")
//        navigationController?.navigationBar.barTintColor = UIColor.yellowColor() // Set top bar color
//        navigationController?.navigationItem.leftBarButtonItem?.setTitleTextAttributes([NSFontAttributeName: UIFont(name: "Avenir Next", size: 17)!], forState: UIControlState.Normal)
//        navigationController?.navigationItem.leftBarButtonItem?.setTitleTextAttributes([NSForegroundColorAttributeName:UIColor.blackColor()], forState: UIControlState.Normal)
//        navigationController?.navigationBar.tintColor = UIColor.blueColor()//navigation item text color
//        navigationController?.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName:UIColor.blackColor()]    //set navigation item text color
//        navigationController?.navigationBar.titleTextAttributes = [NSFontAttributeName: UIFont(name: "Avenir Next", size: 20)!]
    }
    
    func addLayer(){
        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = self.view.bounds
        let colorTop = UIColor.clearColor().CGColor
        let colorBottom = UIColor.whiteColor().CGColor
        gradientLayer.colors = [colorTop, colorBottom]
        self.view.layer.addSublayer(gradientLayer)
    }

}
