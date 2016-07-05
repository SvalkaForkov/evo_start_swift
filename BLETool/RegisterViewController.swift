//
//  RegisterViewController.swift
//  BLETool
//
//  Created by Xiaotu Zhang on 2016-06-20.
//  Copyright © 2016 fortin. All rights reserved.
//

import UIKit

class RegisterViewController: UIViewController {

    var dataController : DataController!
    var appDelegeate : AppDelegate!
    var vehicles : [Vehicle] = []
    var name: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        appDelegeate = UIApplication.sharedApplication().delegate as! AppDelegate
        dataController = appDelegeate.dataController
        vehicles = dataController.getAllVehicles()
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(animated: Bool) {
        print("viewWillAppear: \(self.name)")
    }
    
    @IBAction func onBack(sender: UIButton) {
        performSegueWithIdentifier("back", sender: sender)
    }

    @IBAction func onSave(sender: UIButton) {
        self.name = ""
        print("\(self.name)")
        dataController.saveVehicle(self.name!, address: self.name!)
        performSegueWithIdentifier("back", sender: sender)
    }
    
}
