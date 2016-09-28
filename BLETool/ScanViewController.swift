//
//  ScanViewController.swift
//  BLETool
//
//  Created by Xiaotu Zhang on 2016-06-14.
//  Copyright © 2016 fortin. All rights reserved.
//

import UIKit
import CoreBluetooth

class ScanViewController: UIViewController ,UITableViewDataSource, UITableViewDelegate{
    
    @IBOutlet var topBar: UIView!
    @IBOutlet var tableView: UITableView!
    
    var devices : [String] = []
    var deviceWithRssi = Dictionary<String,Int>()
    var selectedName : String = ""
    var vehicles : [Vehicle] = []
    var lastScene : String = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("viewDidLoad")
        devices.append("EVO_DEMO_1")
        devices.append("EVO_DEMO_2")
        deviceWithRssi["EVO_DEMO_1"] = -47
        deviceWithRssi["EVO_DEMO_2"] = -85
    }
    
    override func viewWillAppear(animated: Bool) {
        print("viewWillAppear")
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        let dataController = appDelegate.dataController
        vehicles = dataController.getAllVehicles()
        
    }
    
    override func viewDidAppear(animated: Bool) {
        print("viewDidAppear")
        lastScene = getLastScene()
        tableView.dataSource = self
        tableView.delegate = self
        animateTableView(false)
        setLastScene()
        
    }
    
    @IBAction func onBack(sender: UIButton) {
        print("return to garage scene")
        performSegueWithIdentifier("segueBackToGarage", sender: sender)
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return devices.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("ScanCell", forIndexPath: indexPath) as! CustomScanCell
        let deviceName = devices[indexPath.row] as String
        cell.labelName!.text = deviceName
        let rssi = deviceWithRssi[deviceName]
        
        if rssi != nil {
            print("rssi : \(rssi)")
            cell.labelValue.text = "\(rssi!)"
            if rssi < 0 && rssi > -50 {
                cell.imageSignal.setImage(UIImage(named: "High Connection"), forState: .Normal)
            }else if rssi <= -50 && rssi > -70 {
                cell.imageSignal.setImage(UIImage(named: "Medium Connection"), forState: .Normal)
            }else if rssi <= -70{
                cell.imageSignal.setImage(UIImage(named: "Low Connection"), forState: .Normal)
            }
        }else{
            print("rssi is nil")
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
        selectedName = devices[indexPath.row] as String
        print("didSelectRowAtIndexPath : \(selectedName)")
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
        if !existing {
            performSegueWithIdentifier("scan2register", sender: nil)
        }else{
            print("return to garage scene")
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
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "scan2register" {
            print("prepareForSegue -> register scene")
            print("now select name is \(selectedName)")
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
        print("getLsetLastScene : Scan")
        NSUserDefaults.standardUserDefaults().setObject("Scan", forKey: "lastScene")
    }
}


