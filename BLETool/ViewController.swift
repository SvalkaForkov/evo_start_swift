//
//  ViewController.swift
//  BLETool
//
//  Created by Xiaotu Zhang on 2016-02-18.
//  Copyright © 2016 fortin. All rights reserved.
//

import UIKit
import CoreBluetooth
import AudioToolbox

extension NSData {
    var hexString : String! {
        let buf = UnsafePointer<UInt8>(bytes)
        let charA = UInt8(UnicodeScalar("a").value)
        let char0 = UInt8(UnicodeScalar("0").value)
        
        func itoh(i: UInt8) -> UInt8 {
            return (i > 9) ? (charA + i - 10) : (char0 + i)
        }
        
        let p = UnsafeMutablePointer<UInt8>.alloc(length * 2)
        
        for i in 0..<length {
            p[i*2] = itoh((buf[i] >> 4) & 0xF)
            p[i*2+1] = itoh(buf[i] & 0xF)
        }
        
        return NSString(bytesNoCopy: p, length: length*2, encoding: NSUTF8StringEncoding, freeWhenDone: true) as! String
    }
}

extension Int {
    var data: NSData {
        var int = self
        return NSData(bytes: &int, length: sizeof(Int))
    }
}

class ViewController: UIViewController, CBCentralManagerDelegate, CBPeripheralDelegate {
    var centralManager:CBCentralManager!
    var peripheral : CBPeripheral!
    var service : CBService!
    var writeCharacteristic : CBCharacteristic!
    var notificationCharacteristic : CBCharacteristic!
    
    var vehicleName = ""
    var module = ""
    var count = 0
    var matchFound = false
    var receivedLock = false
    var receivedUnlock = false
    var receivedStart = false
    var receivedStop = false
    var started = false
    var isManuallyDisconnected = false
    
    @IBOutlet var buttonGarage: UIButton!
    @IBOutlet var buttonLock: UIButton!
    @IBOutlet var buttonUnlock: UIButton!
    @IBOutlet var buttonStart: UIButton!
    @IBOutlet var buttonClearLog: UIButton!
    @IBOutlet var textViewLog: UITextView!
    @IBOutlet var imageStatus: UIImageView!
    @IBOutlet var buttonDoor: UIButton!
    @IBOutlet var buttonEngine: UIButton!
    
    override func viewDidLoad() {
        print("ViewController : viewDidLoad")
        super.viewDidLoad()
        self.navigationController?.navigationBar.barTintColor = getColorFromHex(0x910015)
        self.navigationController?.navigationBar.tintColor = UIColor.whiteColor()
        self.navigationController?.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName:UIColor.whiteColor()]    //getColorFromHex(0xe21f1d)
        self.navigationController?.navigationBar.titleTextAttributes = [NSFontAttributeName: UIFont(name: "Avenir Next", size: 17)!]
        self.navigationController?.navigationItem.leftBarButtonItem?.setTitleTextAttributes([NSFontAttributeName: UIFont(name: "Avenir Next", size: 17)!], forState: UIControlState.Normal)
        self.navigationController?.navigationItem.leftBarButtonItem?.setTitleTextAttributes([NSForegroundColorAttributeName:UIColor.blackColor()], forState: UIControlState.Normal)
        removeBorderFromBar()
        textViewLog.text = ""
    
    }
    
    override func viewWillAppear(animated: Bool) {
        buttonStart.backgroundColor = UIColor.clearColor()
        buttonStart.setTitleColor(getColorFromHex(0x910015), forState: UIControlState.Normal)
        buttonStart.layer.borderWidth = 1
        buttonStart.layer.borderColor = getColorFromHex(0x910015).CGColor
        buttonStart.layer.cornerRadius = 25.0
        buttonStart.clipsToBounds = true
        
        buttonUnlock.layer.cornerRadius = 25.0
        buttonUnlock.clipsToBounds = true
        
        buttonLock.layer.cornerRadius = 25.0
        buttonLock.clipsToBounds = true
        
        buttonEngine.layer.cornerRadius = 25.0
        buttonEngine.clipsToBounds = true
        
        buttonDoor.layer.cornerRadius = 25.0
        buttonDoor.clipsToBounds = true
        
        buttonGarage.layer.cornerRadius = 25.0
        buttonGarage.backgroundColor = UIColor.clearColor()
        buttonGarage.layer.borderWidth = 1
        buttonGarage.layer.borderColor = getColorFromHex(0x910015).CGColor
        buttonGarage.clipsToBounds = true
        getDefault()
        print("ViewController : viewWillAppear")
        if module != "" {
            print("not nil : " + module)	
            centralManager = CBCentralManager(delegate: self, queue:nil)
            buttonGarage.setImage(UIImage(named: "Garage"), forState: .Normal)
        }else{
            print("prompt image")
            buttonGarage.setImage(UIImage(named: "Add Car"), forState: .Normal)
//            imageStatus.s = UIImage(named: "Garage")
            buttonStart.hidden = true
            buttonLock.hidden = true
            buttonUnlock.hidden = true
        }
    }
    
    func getDefault(){
        print("ViewController : check default")
        let defaultModule =
            NSUserDefaults.standardUserDefaults().objectForKey("defaultModule")
                as? String
        if defaultModule != nil {
            module = defaultModule!
            print("default is not nil : \(module)")
        }else{
            print("default is nil")
            module = ""
            checkDatabase()
        }
    }
    
    func checkDatabase(){
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        let dataController = appDelegate.dataController
        let vehicles : [Vehicle] = dataController.getAllVehicles()
        if vehicles.count > 0 {
            module = vehicles[0].module!
            print("use first vehicle in the database")
        }else {
            module = ""
            print("no vehicle registerd")
        }
    }
    
    @IBAction func onClearLog(sender: UIButton) {
        self.textViewLog.text = ""
    }
    
    @IBAction func onGarageButton(sender: UIButton) {
        if module != "" {
            print("on Garage button clicked")
            centralManager.stopScan()
            if peripheral != nil {
                centralManager.cancelPeripheralConnection(peripheral)
                centralManager = nil
                print("disconnect")
            }
            performSegueWithIdentifier("control2garage", sender: sender)
        }else{
            performSegueWithIdentifier("control2scan", sender: self)
        }
    }
    
    func removeBorderFromBar() {
        for p in self.navigationController!.navigationBar.subviews {
            for c in p.subviews {
                if c is UIImageView {
                    c.removeFromSuperview()
                }
            }
        }
    }
    
    func getColorFromHex(value: UInt) -> UIColor{
        return UIColor(
            red: CGFloat((value & 0xFF0000) >> 16) / 255.0,
            green: CGFloat((value & 0x00FF00) >> 8) / 255.0,
            blue: CGFloat(value & 0x0000FF) / 255.0,
            alpha: CGFloat(1.0)
        )
    }
    
    func logOnScreen(line: String){
        self.textViewLog.text = self.textViewLog.text.stringByAppendingString("\(line)\n")
    }
    
    func setDefault(value: String){
        print("set default : \(value)")
        NSUserDefaults.standardUserDefaults().setObject(value, forKey: "defaultModule")
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func centralManagerDidUpdateState(central: CBCentralManager) {
        switch(central.state){
        case CBCentralManagerState.PoweredOn:
            print("Ble PoweredOn")
            matchFound = false
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
                print("Go off main thread : finding matched module")
                sleep(2)
                dispatch_async(dispatch_get_main_queue(),{
                    if !self.matchFound {
                        print("No match module found")
                        self.buttonLock.hidden = true
                        self.buttonUnlock.hidden = true
                        self.buttonStart.hidden = true
                    }else{
                        self.buttonLock.hidden = false
                        self.buttonUnlock.hidden = false
                        self.buttonStart.hidden = false
                    }
                })
            })
            centralManager.scanForPeripheralsWithServices(nil, options: nil)
            print("Scanning bluetooth")
            break
        case CBCentralManagerState.PoweredOff:
            print("Ble PoweredOff")
            centralManager.stopScan()
            break
        case CBCentralManagerState.Unauthorized:
            print("Unauthorized state")
            break
        case CBCentralManagerState.Resetting:
            print("Resetting state")
            break
        case CBCentralManagerState.Unknown:
            print("unknown state")
            break
        case CBCentralManagerState.Unsupported:
            print("Unsupported state")
            break
        }
    }
    
    func centralManager(central: CBCentralManager, didDiscoverPeripheral peripheral: CBPeripheral, advertisementData: [String : AnyObject], RSSI: NSNumber) {
        let nameOfDeviceFound = peripheral.name as String!
        if nameOfDeviceFound != nil {
            print("Did discover : \(nameOfDeviceFound)")
            print("Default module is : \(module)")
            if nameOfDeviceFound == module{
                print("Match and stop scan")
                matchFound = true
                centralManager.stopScan()
                self.peripheral = peripheral
                self.peripheral.delegate = self
                centralManager.connectPeripheral(self.peripheral, options: nil)
                print("Connecting : \(self.peripheral.name)")
            }
        }
    }
    
    func centralManager(central: CBCentralManager, didConnectPeripheral peripheral: CBPeripheral) {
        print("Peripheral connected")
        print("set default Peripheral")
        setDefault(peripheral.name!)
        peripheral.discoverServices([CBUUID(string: "1234")])
        print("DiscoverService: 1234")
    }
    
    func peripheral(peripheral: CBPeripheral, didDiscoverServices error: NSError?) {
        print("Service discoverd")
        for service in peripheral.services! {
            if(service.UUID.UUIDString == "1234"){
                self.service = service
            }
            print("Found service: \(service.UUID)")
            peripheral.discoverCharacteristics([CBUUID(string: "1235"),CBUUID(string: "1236")], forService: service)
        }
    }
    
    func peripheral(peripheral: CBPeripheral, didDiscoverCharacteristicsForService service: CBService, error: NSError?) {
        print("Discovered characteristic")
        for characteristic in service.characteristics! {
            if(characteristic.UUID.UUIDString == "1235"){
                self.writeCharacteristic = characteristic
                print("set writeCharacteristic")
            }
            if(characteristic.UUID.UUIDString == "1236"){
                self.notificationCharacteristic = characteristic
                setNotification(true)
            }
            print("Found characteristic: \(characteristic.UUID)")
        }
        print("Connection ready")
        showControl(true)
    }
    
    func showControl(val: Bool){
        if(!val){
            buttonLock.enabled = false
            buttonUnlock.enabled = false
            buttonStart.enabled = false
        }else{
            buttonLock.enabled = true
            buttonUnlock.enabled = true
            buttonStart.enabled = true
        }
    }
    
    
    @IBAction func onLock(sender: UIButton) {
        print("onlock")
        let data = NSData(bytes: [0x30] as [UInt8], length: 1)
        sendCommend(data, action: 0)
    }
    
    
    @IBAction func onUnlock(sender: UIButton) {
        print("onUnlock")
        let data = NSData(bytes: [0x31] as [UInt8], length: 1)
        sendCommend(data, action: 1)
    }
    
    @IBAction func onStart(sender: UIButton) {
        print("on start: started = \(started)")
        if started {
            print("go stop engine")
            stopEngine()
        } else {
            print("go start engine")
            startEngine()
        }
    }
    
    func startEngine() {
        print("startEngine")
        let data = NSData(bytes: [0x32] as [UInt8], length: 1)
        sendCommend(data, action: 2)
        started = true
        receivedStart = true
    }
    
    func stopEngine() {
        print("stopEngine")
        let data = NSData(bytes: [0x33] as [UInt8], length: 1)
        receivedStop = false
        sendCommend(data, action: 3)
        started = false
        receivedStop = true
    }
    
    func sendCommend(data : NSData, action : Int){
        print("send command : \(action)")
        count = 0
        var flag : Bool
        switch action {
        case 0:
            flag = receivedLock
            break
        case 1:
            flag = receivedUnlock
            break
        case 2:
            flag = receivedStart
            break
        case 3:
            flag = receivedStop
            break
        default:
            break
        }
        flag = false
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
            print("go off main thread")
            self.peripheral.writeValue(data, forCharacteristic: self.writeCharacteristic, type: .WithResponse)
            dispatch_async(dispatch_get_main_queue(),{
                self.logOnScreen("Send : 1st time")
            })
            sleep(1)
            switch action {
            case 0:
                flag = self.receivedLock
                break
            case 1:
                flag = self.receivedUnlock
                break
            case 2:
                flag = self.receivedStart
                break
            case 3:
                flag = self.receivedStop
                break
            default:
                break
            }
            if flag {
                return
            }
            self.peripheral.writeValue(data, forCharacteristic: self.writeCharacteristic, type: .WithResponse)
            dispatch_async(dispatch_get_main_queue(),{
                self.logOnScreen("Send : 2nd time")
            })
            sleep(1)
            switch action {
            case 0:
                flag = self.receivedLock
                break
            case 1:
                flag = self.receivedUnlock
                break
            case 2:
                flag = self.receivedStart
                break
            case 3:
                flag = self.receivedStop
                break
            default:
                break
            }
            if flag {
                return
            }
            self.peripheral.writeValue(data, forCharacteristic: self.writeCharacteristic, type: .WithResponse)
            dispatch_async(dispatch_get_main_queue(),{
                self.logOnScreen("Send : 3rd time")
            })
            sleep(1)
            switch action {
            case 0:
                flag = self.receivedLock
                break
            case 1:
                flag = self.receivedUnlock
                break
            case 2:
                flag = self.receivedStart
                break
            case 3:
                flag = self.receivedStop
                break
            default:
                break
            }
            if flag {
                return
            }
            self.peripheral.writeValue(data, forCharacteristic: self.writeCharacteristic, type: .WithResponse)
            dispatch_async(dispatch_get_main_queue(),{
                self.logOnScreen("Send : 4th time")
            })
            sleep(1)
            switch action {
            case 0:
                flag = self.receivedLock
                break
            case 1:
                flag = self.receivedUnlock
                break
            case 2:
                flag = self.receivedStart
                break
            case 3:
                flag = self.receivedStop
                break
            default:
                break
            }
            if flag {
                return
            }
            self.peripheral.writeValue(data, forCharacteristic: self.writeCharacteristic, type: .WithResponse)
            dispatch_async(dispatch_get_main_queue(),{
                self.logOnScreen("Send : 5th time")
            })
        })
    }
    
    func setNotification(enabled: Bool){
        print("setNotification = true")
        peripheral.setNotifyValue(enabled, forCharacteristic: notificationCharacteristic)
    }
    
    func peripheral(peripheral: CBPeripheral, didUpdateValueForCharacteristic characteristic: CBCharacteristic, error: NSError?) {
        let val = characteristic.value!.hexString
        if(val=="00008001"){
            //ack for locked
            logOnScreen("\(val) : \(count)")
            count = count + 1
            receivedLock = true
            showLocked()
            AudioServicesPlayAlertSound(UInt32(kSystemSoundID_Vibrate))
        }else if(val=="00000002"){
            //ack for unlocked
            logOnScreen("\(val) : \(count)")
            count = count + 1
            receivedUnlock = true
            showUnlocked()
            AudioServicesPlayAlertSound(SystemSoundID(kSystemSoundID_Vibrate))
        }else if(val=="00000201"){
            //ack for started
            started = true
            logOnScreen("\(val) : \(count)")
            count = count + 1
            receivedStart = true
            showStarted()
        }else if(val=="00000001"){
            started = false
            //ack for stopped
            logOnScreen("\(val) : \(count)")
            count = count + 1
            receivedStop = true
            showStopped()
        }else if(val=="0240000f"){
            //ack for locked
            logOnScreen("\(val) : \(count)")
            showStopped()
        }else{
            logOnScreen("\(val) : \(count)")
            print("\(val) : \(count)")
            count = count + 1
            receivedLock = true
            receivedStop = true
            receivedStart = true
            receivedUnlock = true
        }
        print("Charateristic's value has updated : \(val!)")
    }
    
    func showStopped(){
        buttonStart.setTitleColor(getColorFromHex(0x910015), forState: .Normal)
        buttonStart.backgroundColor = UIColor.clearColor()
        buttonStart.setTitle("Start", forState: UIControlState.Normal)
        buttonEngine.setImage(UIImage(named: "Engine"), forState: .Normal)
    }
    
    func showStarted(){
        buttonStart.setTitleColor(UIColor.whiteColor(), forState: .Normal)
        buttonStart.backgroundColor = getColorFromHex(0x910015)
        buttonStart.setTitle("Stop", forState: UIControlState.Normal)
        buttonEngine.setImage(UIImage(named: "Engine Start"), forState: .Normal)
        
        
        UIView.animateWithDuration(1, animations: {
//            self.setAnchorPoint(CGPoint(x: 0.5, y: 0.0), view: self.buttonStart)
//            self.buttonStart.layoutIfNeeded()
            self.buttonStart.layer.anchorPoint = CGPoint(x: 0.5, y: 0.0)
            var _3Dt = CATransform3DIdentity
            _3Dt.m34 = 1.0 / -500
            _3Dt = CATransform3DTranslate(_3Dt, -self.buttonStart.bounds.size.height/2, 0, 0)
            _3Dt = CATransform3DRotate(_3Dt, CGFloat(M_PI*1.6), 1,0,0)
            _3Dt = CATransform3DTranslate(_3Dt, self.buttonStart.bounds.size.height/2, 0, 0)
            self.buttonStart.layer.transform = _3Dt
        })
    }
    
    func showUnlocked(){
        buttonLock.backgroundColor = UIColor.clearColor()
        buttonUnlock.backgroundColor = getColorFromHex(0x910015)
        buttonDoor.setImage(UIImage(named: "Unlock"), forState: .Normal)
    }

    func showLocked(){
        buttonLock.backgroundColor = getColorFromHex(0x910015)
        buttonUnlock.backgroundColor = UIColor.clearColor()
        buttonDoor.setImage(UIImage(named: "Lock"), forState: .Normal)
    }

    func setAnchorPoint(anchorPoint: CGPoint, view: UIView){
        let oldOrigin = view.frame.origin
        view.layer.anchorPoint = anchorPoint
        let newOrigin = view.frame.origin
        
        let transition = CGPointMake (newOrigin.x - oldOrigin.x, newOrigin.y - oldOrigin.y)
        
        view.center = CGPointMake (view.center.x - transition.x, view.center.y - transition.y)
    }
    
    
    
    func centralManager(central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: NSError?) {
        print("Disconnected")
        if !isManuallyDisconnected {
            central.scanForPeripheralsWithServices(nil, options: nil)
            showControl(false)
        }
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        if self.isMovingToParentViewController() {
            print("on back clicked")
            isManuallyDisconnected = true
            centralManager.cancelPeripheralConnection(self.peripheral)
        }
    }
}

