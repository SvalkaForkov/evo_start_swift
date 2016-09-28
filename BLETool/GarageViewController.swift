//
//  TableViewController.swift
//  BLETool
//
//  Created by Xiaotu Zhang on 2016-06-14.
//  Copyright © 2016 fortin. All rights reserved.
//

import UIKit
import CoreBluetooth


class GarageViewController: UIViewController ,UITableViewDataSource, UITableViewDelegate{
    
    @IBOutlet var buttonAdd: UIButton!
    @IBOutlet var tableView: UITableView!
    let tag_default_module = "defaultModule"
    var vehicles : [Vehicle] = []
    var selectedModule = ""
    var dataController : DataController?
    var isFound = false
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
//        cell.contentView.layer.cornerRadius = 25.0
        cell.mainView.layer.cornerRadius = 20.0
        cell.labelName!.text = vehicles[indexPath.row].name!.capitalizedString
        let model = vehicles[indexPath.row].v2model!
        let make : Make! =  model.model2make
        cell.logo.image = UIImage(named: make.title!)
        cell.labelMake!.text = make!.title!.capitalizedString
        cell.labelModel!.text = vehicles[indexPath.row].v2model!.title!.capitalizedString
        
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        selectedModule = vehicles[indexPath.row].module!
        setDefault(selectedModule)
        self.navigationController?.popToRootViewControllerAnimated(true)
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
    
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == UITableViewCellEditingStyle.Delete {
            let vehicleToDelete : String! = vehicles[indexPath.row].module
            print("Vehicle to Delete : \(vehicleToDelete)")
            let currentDefault = getDefaultModuleName()
            print("Current default : \(currentDefault)")
            if vehicleToDelete == currentDefault {
                vehicles.removeAtIndex(indexPath.row)
                tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.Automatic)
                dataController!.deleteVehicleByName(vehicleToDelete)
                if vehicles.count == 0 {
                    setDefault("")
                }else{
                    setDefault(vehicles[0].module!)
                }
            }else{
                vehicles.removeAtIndex(indexPath.row)
                tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.Automatic)
                dataController!.deleteVehicleByName(vehicleToDelete)
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
            UIView.animateWithDuration(1, delay: 0.05 * Double(index), usingSpringWithDamping: 0.8, initialSpringVelocity: 0, options: UIViewAnimationOptions.CurveEaseIn, animations: {
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
        print("setUpNavigationBar")    }
    
}
