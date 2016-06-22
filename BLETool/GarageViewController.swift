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
    
    @IBAction func onAddVehicle(sender: UIButton) {
        print("add click vehicle")
        
    }
    
    @IBOutlet var buttonAdd: UIButton!
    @IBOutlet var tableView: UITableView!
    @IBOutlet var topBar: UIView!
    
    var vehicles = []
    var selectedName = ""
    
    override func viewWillAppear(animated: Bool) {
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        let dataController = appDelegate.dataController
        
        print("setting up delegate and core data")
        vehicles = dataController.getAllVehicles()
        print("fetching vehicle list")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("garage viewDidLoad")
        let cons1 = tableView.topAnchor.constraintEqualToAnchor(topBar.bottomAnchor)
        let cons2 = topBar.heightAnchor.constraintEqualToConstant(56)
        NSLayoutConstraint.activateConstraints([cons1,cons2])
        print("Set constrains to top bar")
        tableView.dataSource = self
        tableView.delegate = self
        
        
        if vehicles.count == 0 {
            print("no vehicle")
        }else{
            buttonAdd.hidden = true
            print("found vehicle")
        }
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return vehicles.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("GarageCell", forIndexPath: indexPath) as! CustomCell
        cell.label1!.text = vehicles[indexPath.row].name
        cell.label2!.text = vehicles[indexPath.row].name
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        selectedName = vehicles[indexPath.row].name
        print("\(selectedName)")
//        self.performSegueWithIdentifier("segueToControl", sender: indexPath)
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
        print("prepareForSegue")
    }
}
