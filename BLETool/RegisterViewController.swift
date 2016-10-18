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
    var networkFailedTime : Int?
    let tag_last_update = "tag_last_update"
    
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
        networkFailedTime = 0
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func viewWillAppear(animated: Bool) {
        print("viewWillAppear: selected \(module)")
        buttonRegister.layer.cornerRadius = 25.0
        buttonRegister.clipsToBounds = true
        if !compareDays(){
        requestMake()
        }
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
            if dataController.getAllVehicles().count == 1 {
                setDefault(self.module!)
            }
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
    
    func requestModel(make: String, id: Int){
        var makeAndModels : Array<Array<String>> = []
        let requestURL: NSURL = NSURL(string: "http://fortin.ca/js/models.json?makeid=\(id)")!
        let urlRequest: NSMutableURLRequest = NSMutableURLRequest(URL: requestURL)
        let session = NSURLSession.sharedSession()
        let task = session.dataTaskWithRequest(urlRequest) {
            (data, response, error) -> Void in
            
            let httpResponse = response as! NSHTTPURLResponse
            let statusCode = httpResponse.statusCode
            
            if (statusCode == 200) {
                print("fetch model statusCode 200.")
                do{
                    let json = try NSJSONSerialization.JSONObjectWithData(data!, options:.AllowFragments)
                    if let models : [[String: AnyObject]] = json["models"] as? [[String: AnyObject]] {    //[[String: AnyObject]]
                        for model in models {
                            if let name = model["name"] as? String {
                                makeAndModels.append([name, make])
                            }
                        }
                    }
                }catch {
                    print("Error with Json: \(error)")
                }
            }
            for array in makeAndModels {
                dispatch_async(dispatch_get_main_queue(),{
                    self.dataController!.insertModelAndMake(array[0], makeTitle: array[1])
                })
            }
        }
        task.resume()
    }
    
    func requestMake(){
        print("request make")
        var makeswithid = Dictionary<String, Int>()
        let requestURL: NSURL = NSURL(string: "http://fortin.ca/js/makes.json")!
        let urlRequest: NSMutableURLRequest = NSMutableURLRequest(URL: requestURL)
        let session = NSURLSession.sharedSession()
        let task = session.dataTaskWithRequest(urlRequest) {
            (data, response, error) -> Void in
            if response != nil {
                let httpResponse = response as! NSHTTPURLResponse
                let statusCode = httpResponse.statusCode
                
                if (statusCode == 200) {
                    NSUserDefaults.standardUserDefaults().setObject(NSDate(), forKey: self.tag_last_update)
                    print("Set last updated date")
                    self.networkFailedTime = 0
                    print("fetch makes statusCode 200.")
                    do{
                        let json = try NSJSONSerialization.JSONObjectWithData(data!, options:.AllowFragments)
                        if let makes : [[String: AnyObject]] = json["makes"] as? [[String: AnyObject]] {    //[[String: AnyObject]]
                            for make in makes {
                                if let name = make["name"] as? String {
                                    if let id = make["makeid"] as? Int {
                                        let makename : String = name
                                        print(name)
                                        let makeid : Int = id
                                        makeswithid[makename] = makeid
                                    }
                                }
                            }
                        }
                        let sortedKeysAndValues = Array(makeswithid).sort({ $0.0 < $1.0 })
                        for (make,id) in sortedKeysAndValues {
                            self.requestModel(make,id: id)
                        }
                    }catch {
                        print("Error with Json: \(error)")
                        if self.networkFailedTime > 1 {
                            
                        }else {
                            self.showActionSheetCheckNetwork()
                        }
                        self.networkFailedTime = self.networkFailedTime! + 1
                    }
                }
            }else{
                if self.networkFailedTime > 1 {
                    
                }else {
                    self.showActionSheetCheckNetwork()
                }
                self.networkFailedTime = self.networkFailedTime! + 1
            }
        }
        task.resume()
    }
    
    func showActionSheetCheckNetwork(){
        let actionSheet = UIAlertController(title: "Cannot connect to server.", message: "Please check network settings or use local data.", preferredStyle: .ActionSheet)
        actionSheet.addAction(UIAlertAction(title: "Go to network setting.", style: .Default,handler: {
            action in
            let settingsUrl = NSURL(string: UIApplicationOpenSettingsURLString)
            if let url = settingsUrl {
                UIApplication.sharedApplication().openURL(url)
            }
        }))
        actionSheet.addAction(UIAlertAction(title: "Use Local Data", style: .Cancel, handler: nil))
        self.presentViewController(actionSheet, animated: true, completion: nil)
    }
    
    func showActionSheetCheckNetworkFailed(){
        let actionSheet = UIAlertController(title: "Network is still not available.", message: "Please check use local data.", preferredStyle: .ActionSheet)
        actionSheet.addAction(UIAlertAction(title: "Use Local Data", style: .Cancel, handler: nil))
        self.presentViewController(actionSheet, animated: true, completion: nil)
    }
    
    
    func compareDays() -> Bool{
        let calendar = NSCalendar.currentCalendar()
        
        let firstDate = NSUserDefaults.standardUserDefaults().objectForKey(tag_last_update)
            as? NSDate
        if firstDate == nil {
            return false
        }else{
        let secondDate = NSDate()
        
        
        let date1 = calendar.startOfDayForDate(firstDate!)
        let date2 = calendar.startOfDayForDate(secondDate)
        
        let flags = NSCalendarUnit.Day
        let components = calendar.components(flags, fromDate: date1, toDate: date2, options: [])
        
        let days = components.day
            if days > 1 {
                return false
            }else{
                return true
            }
        }
    }
}
