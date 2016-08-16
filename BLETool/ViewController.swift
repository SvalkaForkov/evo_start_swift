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
    var countSendTime = 0
    var matchFound = false
    var receivedLock = false
    var receivedUnlock = false
    var receivedStart = false
    var receivedStop = false
    var started = false
    var isManuallyDisconnected = false
    var signal : [UIButton] = []
    var startTime = 0.0
    var longPressCountDown = 0
    var isPressing = false
    var indicator = 0 // 0: Whole car;  1: Engine; 2: Trunk
    @IBOutlet var buttonGarage: UIButton!
    @IBOutlet var buttonLock: UIButton!
    @IBOutlet var buttonUnlock: UIButton!
    
    @IBOutlet var imageDoorIndicator: UIImageView!
    @IBOutlet var imageEngineIndicator: UIImageView!
    @IBOutlet var imageIndicator: UIImageView!
    @IBOutlet var imageCap: UIImageView!
    @IBOutlet var imageStart: UIImageView!
    @IBOutlet var buttonClearLog: UIButton!
    @IBOutlet var textViewLog: UITextView!
    @IBOutlet var buttonDoor: UIButton!
    @IBOutlet var buttonEngine: UIButton!
    @IBOutlet var signal6: UIButton!
    @IBOutlet var signal5: UIButton!
    @IBOutlet var signal4: UIButton!
    @IBOutlet var signal3: UIButton!
    @IBOutlet var signal2: UIButton!
    @IBOutlet var signal1: UIButton!
    @IBOutlet var stackViewLongPress: UIStackView!
    @IBOutlet var buttonCover: UIButton!
    @IBOutlet var swipeDown: UISwipeGestureRecognizer!
    @IBOutlet var swipeUp: UISwipeGestureRecognizer!
    @IBOutlet var longPressStart: UILongPressGestureRecognizer!
    @IBOutlet var stackView: UIStackView!

    override func viewDidLoad() {
        print("ViewController : viewDidLoad")
        super.viewDidLoad()
        navigationController?.navigationBar.barTintColor = UIColor.whiteColor() // Set top bar color
//        navigationController?.navigationBar.tintColor = UIColor.whiteColor()
        navigationController?.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName:UIColor.blackColor()]    //set Title color
        navigationController?.navigationBar.titleTextAttributes = [NSFontAttributeName: UIFont(name: "Avenir Next", size: 17)!]
        navigationController?.navigationItem.leftBarButtonItem?.setTitleTextAttributes([NSFontAttributeName: UIFont(name: "Avenir Next", size: 17)!], forState: UIControlState.Normal)
        navigationController?.navigationItem.leftBarButtonItem?.setTitleTextAttributes([NSForegroundColorAttributeName:UIColor.blackColor()], forState: UIControlState.Normal)
        removeBorderFromBar()
        textViewLog.text = ""
        signal = [signal1,signal2,signal3,signal4,signal5,signal6]
        longPressStart.enabled = false
    }
    
    override func viewWillAppear(animated: Bool) {
        
        buttonCover.backgroundColor = UIColor.clearColor()
        buttonCover.clipsToBounds = true
        //        buttonCover.frame = CGRectMake(0,0,imageCap.bounds.width,imageCap.bounds.height)
        let cons = NSLayoutConstraint(
            item: stackView,
            attribute: .Bottom,
            relatedBy: .Equal,
            toItem: stackView.superview,
            attribute: .Bottom,
            multiplier: 1.0,
            constant: -imageCap.bounds.height/2
        )
        let cons0 = NSLayoutConstraint(
            item: imageCap,
            attribute: .Bottom,
            relatedBy: .Equal,
            toItem: imageCap.superview,
            attribute: .Bottom,
            multiplier: 1.0,
            constant: -imageCap.bounds.height/2
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
            item: imageStart,
            attribute: .Top,
            relatedBy: .Equal,
            toItem: imageCap,
            attribute: .Top,
            multiplier: 1.0,
            constant: 0
        )
        NSLayoutConstraint.activateConstraints([cons0,cons1,cons3,cons,cons2])
        //        buttonCover.transform = CGAffineTransformMakeTranslation( 0.0, imageCap.bounds.height / 2 )
        //        buttonCover.layoutIfNeeded()
        
        imageCap.backgroundColor = UIColor.clearColor()
        setAnchorPoint(CGPoint(x: 0.5, y: 0.0), forView: self.imageCap)
        
        imageCap.layoutIfNeeded()
        imageCap.clipsToBounds = true
        
        imageStart.backgroundColor = UIColor.clearColor()
        setAnchorPoint(CGPoint(x: 0.5, y: 0.0), forView: self.imageStart)
        
        imageStart.layoutIfNeeded()
        imageStart.clipsToBounds = true
        
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
        
        imageEngineIndicator.alpha = 0
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
            //            imageStart.hidden = true
            //            imageCap.hidden = true
            //            buttonLock.hidden = true
            //            buttonUnlock.hidden = true
        }
        
        //        let swipeUp = UISwipeGestureRecognizer(target: self, action: #selector(ViewController.onSwispe(_:)))
        //        swipeUp.direction = UISwipeGestureRecognizerDirection.Up
        //        imageCap.addGestureRecognizer(swipeUp)
        //        let swipeDown = UISwipeGestureRecognizer(target: self, action: #selector(ViewController.onSwispe(_:)))
        //        swipeDown.direction = UISwipeGestureRecognizerDirection.Down
        //        imageCap.addGestureRecognizer(swipeDown)
        
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
        if indicator == 1 {
            newEngineToDoor()
        }else if indicator == 0 {
            newDoorToEngine()
        }
        
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
                        self.imageCap.hidden = true
                        self.imageStart.hidden = true
                    }else{
                        self.buttonLock.hidden = false
                        self.buttonUnlock.hidden = false
                        self.imageCap.hidden = false
                        self.imageStart.hidden = false
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
        }else{
            print("set enable")
            buttonLock.enabled = true
            buttonUnlock.enabled = true
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
        countSendTime = 0
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
            logOnScreen("\(val) : \(countSendTime)")
            countSendTime += 1
            if !receivedLock{
                receivedLock = true
                showLocked()
                AudioServicesPlayAlertSound(UInt32(kSystemSoundID_Vibrate))
            }
        }else if(val=="00000002"){
            //ack for unlocked
            logOnScreen("\(val) : \(countSendTime)")
            countSendTime += 1
            if !receivedUnlock{
                receivedUnlock = true
                showUnlocked()
                AudioServicesPlayAlertSound(SystemSoundID(kSystemSoundID_Vibrate))
            }
        }else if(val=="00000201"){
            //ack for started
            started = true
            logOnScreen("\(val) : \(countSendTime)")
            countSendTime += 1
            if !receivedStart{
                receivedStart = true
                showStarted()
            }
        }else if(val=="00000001"){
            started = false
            //ack for stopped
            logOnScreen("\(val) : \(countSendTime)")
            countSendTime += 1
            if !receivedStop{
                receivedStop = true
                showStopped()
            }
        }else if(val=="0240000f"){
            //ack for locked
            logOnScreen("\(val) : \(countSendTime)")
            showStopped()
        }else{
            logOnScreen("\(val) : \(countSendTime)")
            print("\(val) : \(countSendTime)")
            countSendTime += 1
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
    
    
    @IBAction func onLongPressStart(sender: UILongPressGestureRecognizer) {
        //        print("asdasdasd")
        switch sender.state {
        case UIGestureRecognizerState.Began:
            print("began")
            isPressing = true
            longPressCountDown = 0
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
                print("now \(self.longPressCountDown)")
                while self.isPressing && self.longPressCountDown <= 5{
                    dispatch_async(dispatch_get_main_queue(),{
                        
                        self.signal[self.longPressCountDown].setImage(UIImage(named: "Filled Arrow"), forState: .Normal)
                        self.longPressCountDown += 1
                        print("set \(self.longPressCountDown)")
                        
                        
                    })
                    usleep(150000)
                }
            })
            //            startTime = NSDate().timeIntervalSince1970
            //            longPressCountDown = 0
            break
        case UIGestureRecognizerState.Ended:
            print("ended")
            isPressing = false
            for index in 0...5 {
                signal[index].setImage(UIImage(named: "Arrow"), forState: .Normal)
            }
            
            break
        default:
            //            let timeInterval = NSDate().timeIntervalSince1970 - startTime
            //            if longPressCountDown == 6 {
            //                print("should send start")
            //                longPressCountDown = 7
            //            }else if timeInterval >= 0.2 && longPressCountDown < 6 {
            //                startTime = NSDate().timeIntervalSince1970
            //                signal[longPressCountDown].setImage(UIImage(named: "Filled Arrow"), forState: .Normal)
            //                longPressCountDown += 1
            //                print("conut + 1 : [\(longPressCountDown)]")
            //            }
            break
        }
    }
    
    @IBAction func onDown(sender: UISwipeGestureRecognizer) {
        print("swipe down")
        UIView.animateWithDuration(1, animations: {
            var transform = CATransform3DIdentity
            transform.m34 = 1.0 / -1000
            transform = CATransform3DTranslate(transform, -self.imageCap.bounds.size.height/4, 0, 0)
            transform = CATransform3DRotate(transform, CGFloat(-0.0 * M_PI / 180.0), 1,0,0)
            transform = CATransform3DTranslate(transform, self.imageCap.bounds.size.height/4, 0, 0)
            self.imageCap.layer.transform = transform
        })
        longPressStart.enabled = false
    }
    
    @IBAction func onUp(sender: UISwipeGestureRecognizer) {
        print("swipe up")
        UIView.animateWithDuration(1, animations: {
            var transform = CATransform3DIdentity
            transform.m34 = 1.0 / -1000
            transform = CATransform3DTranslate(transform, -self.imageCap.bounds.size.height/4, 0, 0)
            transform = CATransform3DRotate(transform, CGFloat(70.0 * M_PI / 180.0), 1,0,0)
            transform = CATransform3DTranslate(transform, self.imageCap.bounds.size.height/4, 0, 0)
            self.imageCap.layer.transform = transform
        })
        longPressStart.enabled = true
    }
    
    func newDoorToEngine() {
        print("start: \(self.imageIndicator.layer.position)")
        UIView.animateWithDuration(1, animations: {
            let fullRotation = CGFloat(M_PI * 2)
            var transform = CGAffineTransformIdentity
            transform = CGAffineTransformScale(transform, 1.5, 1.5)
            transform = CGAffineTransformRotate(transform, 3/4 * fullRotation)
            transform = CGAffineTransformTranslate(transform, -0,100)
            self.imageIndicator.transform = transform
            }, completion: {finished in
                // any code entered here will be applied
                // once the animation has completed
                self.imageIndicator.layoutIfNeeded()
                print("end: \(self.buttonGarage.layer.position)")
            })
        UIView.animateWithDuration(1, animations: {
            let fullRotation = CGFloat(M_PI * 2)
            var transform = CGAffineTransformIdentity
            transform = CGAffineTransformScale(transform, 1.5, 1.5)
            transform = CGAffineTransformRotate(transform, 3/4 * fullRotation)
            transform = CGAffineTransformTranslate(transform, -0,100)
            self.imageEngineIndicator.alpha = 1
            self.imageEngineIndicator.transform = transform
            }, completion: {finished in
                self.imageEngineIndicator.layoutIfNeeded()
                print("end: \(self.buttonGarage.layer.position)")
        })
        indicator = 1
    }
    
    func newEngineToDoor() {
        UIView.animateWithDuration(1, animations: {
            let transform = CGAffineTransformIdentity
            self.imageIndicator.transform = transform
            }, completion: {finished in
                self.imageIndicator.layoutIfNeeded()
        })
        UIView.animateWithDuration(1, animations: {
            let transform = CGAffineTransformIdentity
            self.imageEngineIndicator.transform = transform
            self.imageEngineIndicator.alpha = 0
            }, completion: {finished in
                self.imageEngineIndicator.layoutIfNeeded()
        })
        indicator = 0
    }
    
    func doorToEngine(){
        let fullRotation = CGFloat(M_PI * 2)
        UIView.animateKeyframesWithDuration(2, delay: 0, options: UIViewKeyframeAnimationOptions.BeginFromCurrentState, animations: {
            // each keyframe needs to be added here
            // within each keyframe the relativeStartTime and relativeDuration need to be values between 0.0 and 1.0
            UIView.addKeyframeWithRelativeStartTime(0, relativeDuration: 1, animations: {
                // start at 0.00s (5s × 0)
                // duration 1.67s (5s × 1/3)
                // end at   1.67s (0.00s + 1.67s)
                self.buttonGarage.transform = CGAffineTransformMakeScale(2.0,2.0)
            })
            UIView.addKeyframeWithRelativeStartTime(0, relativeDuration: 1, animations: {
                self.buttonGarage.transform = CGAffineTransformMakeRotation(3/4 * fullRotation)
            })
            UIView.addKeyframeWithRelativeStartTime(0, relativeDuration: 1, animations: {
                self.buttonGarage.transform = CGAffineTransformMakeTranslation(-self.buttonGarage.frame.origin.x, -self.buttonGarage.frame.origin.y)
            })
            
            }, completion: {finished in
                // any code entered here will be applied
                // once the animation has completed
                self.buttonGarage.layoutIfNeeded()
        })
    }
}

