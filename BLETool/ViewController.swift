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
    @IBOutlet var buttonCap: UIButton!
    @IBOutlet var buttonClearLog: UIButton!
    @IBOutlet var textViewLog: UITextView!
    @IBOutlet var buttonDoor: UIButton!
    @IBOutlet var buttonEngine: UIButton!
    var signal : [UIButton] = []
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
        signal = [signal1,signal2,signal3,signal4,signal5,signal6]
        
    }
    
    override func viewWillAppear(animated: Bool) {
        buttonCover.backgroundColor = UIColor.clearColor()
        
        buttonCover.clipsToBounds = true
//        buttonCover.frame = CGRectMake(0,0,buttonCap.bounds.width,buttonCap.bounds.height)
        let cons = NSLayoutConstraint(
            item: stackView,
            attribute: .Bottom,
            relatedBy: .Equal,
            toItem: stackView.superview,
            attribute: .Bottom,
            multiplier: 1.0,
            constant: -buttonCap.bounds.height/2
        )
        let cons0 = NSLayoutConstraint(
            item: buttonCap,
            attribute: .Bottom,
            relatedBy: .Equal,
            toItem: buttonCap.superview,
            attribute: .Bottom,
            multiplier: 1.0,
            constant: -buttonCap.bounds.height/2
        )
        let cons1 = NSLayoutConstraint(
            item: buttonCover,
            attribute: .Top,
            relatedBy: .Equal,
            toItem: buttonCover.superview,
            attribute: .Top,
            multiplier: 1.0,
            constant: 0
        )
        let cons3 = NSLayoutConstraint(
            item: buttonCover,
            attribute: .Bottom,
            relatedBy: .Equal,
            toItem: buttonCover.superview,
            attribute: .Bottom,
            multiplier: 1.0,
            constant: 0
        )
        let cons2 = NSLayoutConstraint(
            item: buttonStart,
            attribute: .Top,
            relatedBy: .Equal,
            toItem: buttonCap,
            attribute: .Top,
            multiplier: 1.0,
            constant: 0
        )
        NSLayoutConstraint.activateConstraints([cons0,cons1,cons3,cons,cons2])
//        buttonCover.transform = CGAffineTransformMakeTranslation( 0.0, buttonCap.bounds.height / 2 )
//        buttonCover.layoutIfNeeded()
        
        buttonCap.backgroundColor = UIColor.clearColor()
        setAnchorPoint(CGPoint(x: 0.5, y: 0.0), forView: self.buttonCap)
        
        buttonCap.layoutIfNeeded()
        buttonCap.clipsToBounds = true
        
        buttonStart.backgroundColor = UIColor.clearColor()
        setAnchorPoint(CGPoint(x: 0.5, y: 0.0), forView: self.buttonStart)
        
        buttonStart.layoutIfNeeded()
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
//            buttonStart.hidden = true
//            buttonCap.hidden = true
//            buttonLock.hidden = true
//            buttonUnlock.hidden = true
        }
        
        //        let swipeUp = UISwipeGestureRecognizer(target: self, action: #selector(ViewController.onSwispe(_:)))
        //        swipeUp.direction = UISwipeGestureRecognizerDirection.Up
        //        buttonCap.addGestureRecognizer(swipeUp)
        //        let swipeDown = UISwipeGestureRecognizer(target: self, action: #selector(ViewController.onSwispe(_:)))
        //        swipeDown.direction = UISwipeGestureRecognizerDirection.Down
        //        buttonCap.addGestureRecognizer(swipeDown)
        
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
                        self.buttonCap.hidden = true
                        self.buttonStart.hidden = true
                    }else{
                        self.buttonLock.hidden = false
                        self.buttonUnlock.hidden = false
                        self.buttonCap.hidden = false
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
            print("set disable")
            buttonLock.enabled = false
            buttonUnlock.enabled = false
            buttonCap.enabled = false
            buttonStart.enabled = false
        }else{
            print("set enable")
            buttonLock.enabled = true
            buttonUnlock.enabled = true
            buttonCap.enabled = true
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
    }
    
    func stopEngine() {
        print("stopEngine")
        let data = NSData(bytes: [0x33] as [UInt8], length: 1)
        receivedStop = false
        sendCommend(data, action: 3)
        started = false
    }
    
    func sendCommend(data : NSData, action : Int){
        print("send command : \(action)")
        count = 0
        var flag : Bool
        switch action {
        case 0:
            receivedLock = false
            flag = receivedLock
            break
        case 1:
            receivedUnlock = false
            flag = receivedUnlock
            break
        case 2:
            receivedStart = false
            flag = receivedStart
            break
        case 3:
            receivedStop = false
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
            if !receivedLock{
                receivedLock = true
                showLocked()
                AudioServicesPlayAlertSound(UInt32(kSystemSoundID_Vibrate))
            }
        }else if(val=="00000002"){
            //ack for unlocked
            logOnScreen("\(val) : \(count)")
            count = count + 1
            if !receivedUnlock{
                receivedUnlock = true
                showUnlocked()
                AudioServicesPlayAlertSound(SystemSoundID(kSystemSoundID_Vibrate))
            }
        }else if(val=="00000201"){
            //ack for started
            started = true
            logOnScreen("\(val) : \(count)")
            count = count + 1
            if !receivedStart{
                receivedStart = true
                showStarted()
            }
        }else if(val=="00000001"){
            started = false
            //ack for stopped
            logOnScreen("\(val) : \(count)")
            count = count + 1
            if !receivedStop{
                receivedStop = true
                showStopped()
            }
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
        buttonEngine.setImage(UIImage(named: "Engine"), forState: .Normal)
        
    }
    
    func showStarted(){
        buttonEngine.setImage(UIImage(named: "Engine Start"), forState: .Normal)
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
    
    
    func setAnchorPoint(anchorPoint: CGPoint, forView view: UIView) {
        var newPoint = CGPointMake(view.bounds.size.width * anchorPoint.x, view.bounds.size.height * anchorPoint.y)
        var oldPoint = CGPointMake(view.bounds.size.width * view.layer.anchorPoint.x, view.bounds.size.height * view.layer.anchorPoint.y)
        print("postion \(view.layer.position)")
        print("new \(newPoint)")
        print("old \(oldPoint)")
        newPoint = CGPointApplyAffineTransform(newPoint, view.transform)
        oldPoint = CGPointApplyAffineTransform(oldPoint, view.transform)
        print("new \(newPoint)")
        print("old \(oldPoint)")
        var position = view.layer.position
        position.x -= oldPoint.x
        position.x += newPoint.x
        
        position.y -= oldPoint.y
        position.y += newPoint.y
        
        view.layer.anchorPoint = anchorPoint
        view.layoutIfNeeded()
        print("postion \(view.layer.position)")
        UIView.animateWithDuration(0, animations: {
            view.center = oldPoint
        })
        print("postion final \(view.layer.position)")
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
    
    @IBOutlet var buttonCover: UIButton!
    @IBOutlet var swipeDown: UISwipeGestureRecognizer!
    @IBOutlet var swipeUp: UISwipeGestureRecognizer!
    @IBOutlet var longPressStart: UILongPressGestureRecognizer!
    
    @IBOutlet var stackView: UIStackView!
    var startTime = 0.0
    var longPressCountDown = 0
    @IBAction func onLongPressStart(sender: UILongPressGestureRecognizer) {
        switch sender.state {
        case UIGestureRecognizerState.Began:
            print("began")
            startTime = NSDate().timeIntervalSince1970
            longPressCountDown = 0
            break
        case UIGestureRecognizerState.Ended:
            print("ended")
            for index in 0...5 {
                signal[index].setImage(UIImage(named: "Arrow"), forState: .Normal)
                }
            
            break
        default:
            let timeInterval = NSDate().timeIntervalSince1970 - startTime
            if longPressCountDown == 6 {
                print("should send start")
                longPressCountDown = 7
            }else if timeInterval >= 0.300 && longPressCountDown < 6 {
                startTime = NSDate().timeIntervalSince1970
                signal[longPressCountDown].setImage(UIImage(named: "Filled Arrow"), forState: .Normal)
                longPressCountDown += 1
                print("conut + 1 : [\(longPressCountDown)]")
            }
            break
        }
    }
    
    @IBAction func onDown(sender: UISwipeGestureRecognizer) {
        print("swipe down")
        UIView.animateWithDuration(1, animations: {
            var transform = CATransform3DIdentity
            transform.m34 = 1.0 / -1000
            transform = CATransform3DTranslate(transform, -self.buttonCap.bounds.size.height/4, 0, 0)
            transform = CATransform3DRotate(transform, CGFloat(-0.0 * M_PI / 180.0), 1,0,0)
            transform = CATransform3DTranslate(transform, self.buttonCap.bounds.size.height/4, 0, 0)
            self.buttonCap.layer.transform = transform
        })
        longPressStart.enabled = false
    }
    @IBAction func onUp(sender: UISwipeGestureRecognizer) {
        print("swipe up")
        UIView.animateWithDuration(1, animations: {
            var transform = CATransform3DIdentity
            transform.m34 = 1.0 / -1000
            transform = CATransform3DTranslate(transform, -self.buttonCap.bounds.size.height/4, 0, 0)
            transform = CATransform3DRotate(transform, CGFloat(70.0 * M_PI / 180.0), 1,0,0)
            transform = CATransform3DTranslate(transform, self.buttonCap.bounds.size.height/4, 0, 0)
            self.buttonCap.layer.transform = transform
        })
        longPressStart.enabled = true
    }
    
    @IBOutlet var signal6: UIButton!
    @IBOutlet var signal5: UIButton!
    @IBOutlet var signal4: UIButton!
    @IBOutlet var signal3: UIButton!
    @IBOutlet var signal2: UIButton!
    @IBOutlet var signal1: UIButton!
    @IBOutlet var stackViewLongPress: UIStackView!
    
}

