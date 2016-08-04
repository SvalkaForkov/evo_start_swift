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
    
    @IBOutlet var nameField: UITextField!
    @IBOutlet var makeField: UITextField!
    @IBOutlet var modelField: UITextField!
    @IBOutlet var yearField: UITextField!
    
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
        if checkInfo() {
            
        }
//        dataController.saveVehicle(self.name!, address: self.name!)
        dataController.saveVehicle(nameField.text!, make: makeField.text!, model: modelField.text!, year: yearField.text!, address: "unknown")
//        performSegueWithIdentifier("back", sender: sender)
        print("prepare to go back to control")
        self.navigationController?.popToRootViewControllerAnimated(true)
    }
    
    @IBAction func onTap(sender: UITapGestureRecognizer) {
        if nameField.isFirstResponder() {
            nameField.endEditing(true)
        }else if makeField.isFirstResponder() {
            makeField.endEditing(true)
        }else if modelField.isFirstResponder() {
            modelField.endEditing(true)
        }else if yearField.isFirstResponder() {
            yearField.endEditing(true)
        }
    }
    
    func checkInfo() -> Bool {
        print("check all infomation is filled")
        if nameField.text!.isEmpty {
            print("no name")
            return false
        }
        if makeField.text!.isEmpty {
            print("no name")
            return false
        }
        if modelField.text!.isEmpty {
            print("no name")
            return false
        }
        if yearField.text!.isEmpty {
            print("no name")
            return false
        }else{
            let year = Int(yearField.text!)
            if year != nil {
                if(year < 1999 || year > 2017){
                    return false
                }
            }else{
                return false
            }
        }
        return true
    }
}
