//
//  RegisterViewController.swift
//  BLETool
//
//  Created by Xiaotu Zhang on 2016-06-20.
//  Copyright © 2016 fortin. All rights reserved.
//

import UIKit

class RegisterViewController: UIViewController , UITextFieldDelegate{

    var dataController : DataController!
    var appDelegeate : AppDelegate!
    var vehicles : [Vehicle] = []
    var module: String?
    
    @IBOutlet var nameField: UITextField!
    var indexForModel : Int! = 0
    var indexForYear : Int! = 0
    var indexForMake : Int! = 0
    @IBOutlet var buttonSelectMake: UIButton!
    @IBOutlet var buttonSelectModel: UIButton!
    @IBOutlet var buttonSelectYear: UIButton!
    @IBOutlet var buttonRegister: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        appDelegeate = UIApplication.sharedApplication().delegate as! AppDelegate
        dataController = appDelegeate.dataController
        vehicles = dataController.getAllVehicles()
        nameField.delegate = self
        
//        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("keyboardWillShow:"), name: UIKeyboardWillShowNotification, object: nil)
//        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("keyboardWillHide:"), name: UIKeyboardWillHideNotification, object: nil)

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(animated: Bool) {
        print("viewWillAppear: selected \(module)")
        buttonRegister.layer.cornerRadius = 25.0
        buttonRegister.clipsToBounds = true
    }
    
    override func viewDidAppear(animated: Bool) {
        print(viewDidAppear)
        nameField.endEditing(true)
        setLastScene()
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return false
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
        print("set default : \(value)")
        NSUserDefaults.standardUserDefaults().setObject(value, forKey: "defaultModule")
    }
    
    @IBAction func onBack(sender: UIButton) {
        performSegueWithIdentifier("back", sender: sender)
    }

    @IBAction func onSave(sender: UIButton) {
        if checkInfo() {
            print("save vehicle")
            let yearValue = NSDecimalNumber(string: buttonSelectYear.titleLabel!.text!)
            let model = dataController.fetchModelByTitle((buttonSelectModel?.titleLabel!.text)!)!
            dataController.saveVehicle(nameField.text!, model: model, year: yearValue, module: self.module!)
            setDefault(self.module!)
            print("prepare to go back to control")
            self.navigationController?.popToRootViewControllerAnimated(true)
        }else{
            print("info is not complete")
        }
    }
    
    @IBAction func onTap(sender: UITapGestureRecognizer) {
//        if nameField.isFirstResponder() {
            nameField.endEditing(true)
//        }
    }
    
    func checkInfo() -> Bool {
        print("check all infomation is filled")
        if nameField.text!.isEmpty {
            print("no name")
            return false
        }
        if buttonSelectMake.titleLabel!.text == "Select Make" {
            print("No make selected")
            return false
        }
        if buttonSelectModel.titleLabel!.text == "Select Model" {
            print("No model selected")
            return false
        }
        if buttonSelectYear.titleLabel!.text == "Select Year" {
            print("No year selected")
            return false
        }
        return true
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
    
    @IBAction func onSelectModel(sender: UIButton) {
        if buttonSelectMake.titleLabel?.text != "Select Make" {
            performSegueWithIdentifier("selectModel", sender: sender)
        }else{
            showAlert()
        }
    }
    
    func showAlert() {
        if NSClassFromString("UIAlertController") != nil {
            let alertController = UIAlertController(title: "Tip", message: "Please select a make first", preferredStyle: UIAlertControllerStyle.Alert)
            presentViewController(alertController, animated: true, completion:{
                alertController.view.superview?.userInteractionEnabled = true
                alertController.view.superview?.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.alertControllerBackgroundTapped)))
            })
        }
    }
    
    func alertControllerBackgroundTapped()    {
        self.dismissViewControllerAnimated(true, completion: nil)
    }

    func setLastScene(){
        print("getLsetLastScene : Register")
        NSUserDefaults.standardUserDefaults().setObject("Register", forKey: "lastScene")
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "selectYear"{
            let destController = segue.destinationViewController as! YearViewController
            destController.lastChoice = indexForYear
            destController.registerViewController = self
        }else if segue.identifier == "selectMake"{
            let destController = segue.destinationViewController as! MakeViewController
                destController.lastChoice = indexForMake
            destController.registerViewController = self
        }else if segue.identifier == "selectModel"{
            let destController = segue.destinationViewController as! ModelViewController
            destController.registerViewController = self
            destController.lastChoice = indexForModel
            let make = buttonSelectMake?.titleLabel?.text
            destController.make = dataController.fetchMakeByTitle(make!)
        }else{
            
        }
    }
}
