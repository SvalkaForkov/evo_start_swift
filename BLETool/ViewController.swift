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

class ViewController: UIViewController, CBCentralManagerDelegate, CBPeripheralDelegate, UITableViewDataSource, UITableViewDelegate {
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
    var startTime = 0.0
    var longPressCountDown = 0
    var isPressing = false
    var indicator = 0 // 0: Whole car;  1: Engine; 2: Trunk
    @IBOutlet var buttonGarage: UIButton!
    @IBOutlet var buttonLock: UIButton!
    @IBOutlet var buttonUnlock: UIButton!
    
    @IBOutlet var imageCap: UIImageView!
    @IBOutlet var imageStart: UIImageView!
    @IBOutlet var buttonClearLog: UIButton!
    @IBOutlet var textViewLog: UITextView!
    @IBOutlet var buttonCover: UIButton!
    @IBOutlet var swipeDown: UISwipeGestureRecognizer!
    @IBOutlet var swipeUp: UISwipeGestureRecognizer!
    @IBOutlet var longPressStart: UILongPressGestureRecognizer!
    
    @IBOutlet var logBackgroundView: UIView!
    @IBOutlet var capContainerView: UIView!
    
    let ACK_door_unlocked = "00000002"
    let ACK_door_locked = "00008001"
    let ACK_trunk_unlocked = ""
    let ACK_trunk_locked = ""
    let ACK_engine_started = "00000201"
    let ACK_engine_stopped = "00000001"
    
    var messages : [String] = []
    
    override func viewDidLoad() {
        print("ViewController : viewDidLoad")
        super.viewDidLoad()
        
    }
    
    override func viewWillAppear(animated: Bool) {
        setUpNavigationBar()
        setupViews()
        messages = []
        //        activateConstrains()
        
        print("ViewController : viewWillAppear")
        getDefaultModule()
        if module != "" {
            print("not nil : " + module)
            centralManager = CBCentralManager(delegate: self, queue:nil)
            buttonGarage.setImage(UIImage(named: "Garage"), forState: .Normal)
        }else{
            print("prompt image")
            buttonGarage.setImage(UIImage(named: "Add Car"), forState: .Normal)
        }
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messages.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("GarageCell", forIndexPath: indexPath) as! CustomGarageCell
        cell.mainView.layer.cornerRadius = 2.0
        cell.label1!.text = vehicles[indexPath.row].name!.capitalizedString
        cell.label2!.text = vehicles[indexPath.row].make!.capitalizedString
        cell.label3!.text = vehicles[indexPath.row].model!.capitalizedString
        
        return cell
    }
    
    func setupViews(){
        print("setupViews")
        textViewLog.text = ""
        logBackgroundView.layer.cornerRadius = 5.0
        logBackgroundView.layer.shadowOffset = CGSizeMake(2.0, 2.0)
        longPressStart.enabled = false
        buttonCover.backgroundColor = UIColor.clearColor()
        buttonCover.clipsToBounds = true
        
        
        
        imageCap.backgroundColor = UIColor.clearColor()
        
        
        imageCap.layoutIfNeeded()
        imageCap.clipsToBounds = true
        
        imageStart.backgroundColor = UIColor.clearColor()
        //        setAnchorPoint(CGPoint(x: 0.5, y: 0.0), forView: self.imageStart)
        
        imageStart.layoutIfNeeded()
        imageStart.clipsToBounds = true
        
        buttonUnlock.layer.cornerRadius = 25.0
        buttonUnlock.clipsToBounds = true
        
        buttonLock.layer.cornerRadius = 25.0
        buttonLock.clipsToBounds = true
        
        buttonGarage.layer.cornerRadius = 25.0
        buttonGarage.backgroundColor = UIColor.clearColor()
        buttonGarage.layer.borderWidth = 1
        //        buttonGarage.layer.borderColor = getColorFromHex(0x910015).CGColor
        buttonGarage.clipsToBounds = true
        setAnchorPoint(CGPoint(x: 0.5, y: 0.0), forView: self.imageStart)
        setAnchorPoint(CGPoint(x: 0.5, y: 0.0), forView: self.imageCap)
        print("\(imageCap.layer)")
    }
    
    //    func applyNewCons(){
    //        let cons = NSLayoutConstraint(
    //            item: capContainerView,
    //            attribute: .Bottom,
    //            relatedBy: .Equal,
    //            toItem: capContainerView.superview,
    //            attribute: .Bottom,
    //            multiplier: 1.0,
    //            constant: -imageCap.bounds.height/2
    //        )
    //        let cons0 = NSLayoutConstraint(
    //            item: imageCap,
    //            attribute: .Bottom,
    //            relatedBy: .Equal,
    //            toItem: imageCap.superview,
    //            attribute: .Bottom,
    //            multiplier: 1.0,
    //            constant: -imageCap.bounds.height/2
    //        )
    //        let cons1 = NSLayoutConstraint(
    //            item: buttonCover,
    //            attribute: .Top,
    //            relatedBy: .Equal,
    //            toItem: buttonCover.superview,
    //            attribute: .Top,
    //            multiplier: 1.0,
    //            constant: 0
    //        )
    //        let cons3 = NSLayoutConstraint(
    //            item: buttonCover,
    //            attribute: .Bottom,
    //            relatedBy: .Equal,
    //            toItem: buttonCover.superview,
    //            attribute: .Bottom,
    //            multiplier: 1.0,
    //            constant: 0
    //        )
    //        let cons2 = NSLayoutConstraint(
    //            item: imageStart,
    //            attribute: .Top,
    //            relatedBy: .Equal,
    //            toItem: imageStart,
    //            attribute: .Top,
    //            multiplier: 1.0,
    //            constant: 0
    //        )
    //        NSLayoutConstraint.activateConstraints([cons0,cons1,cons3,cons,cons2])
    //    }
    //
    //    func activateConstrains() {
    //        print("activateConstrains")
    //        let cons = NSLayoutConstraint(
    //            item: capContainerView,
    //            attribute: .Bottom,
    //            relatedBy: .Equal,
    //            toItem: capContainerView.superview,
    //            attribute: .Bottom,
    //            multiplier: 1.0,
    //            constant: imageCap.bounds.height/2
    //        )
    //
    //        let cons0 = NSLayoutConstraint(
    //            item: imageCap,
    //            attribute: .Bottom,
    //            relatedBy: .Equal,
    //            toItem: imageCap.superview,
    //            attribute: .Bottom,
    //            multiplier: 1.0,
    //            constant: imageCap.bounds.height/2
    //        )
    //        let cons1 = NSLayoutConstraint(
    //            item: buttonCover,
    //            attribute: .Top,
    //            relatedBy: .Equal,
    //            toItem: buttonCover.superview,
    //            attribute: .Top,
    //            multiplier: 1.0,
    //            constant: 0
    //        )
    //        let cons3 = NSLayoutConstraint(
    //            item: buttonCover,
    //            attribute: .Bottom,
    //            relatedBy: .Equal,
    //            toItem: buttonCover.superview,
    //            attribute: .Bottom,
    //            multiplier: 1.0,
    //            constant: 0
    //        )
    //        let cons2 = NSLayoutConstraint(
    //            item: imageStart,
    //            attribute: .Top,
    //            relatedBy: .Equal,
    //            toItem: imageCap,
    //            attribute: .Top,
    //            multiplier: 1.0,
    //            constant: 0
    //        )
    //
    //        NSLayoutConstraint.activateConstraints([cons, cons0,cons1,cons3,cons2])
    //        print("\(imageCap.layer)")
    //    }
    
    override func viewDidAppear(animated: Bool) {
        print("viewDidAppear")
        setLastScene()
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        print("viewWillDisappear")
        if centralManager != nil && peripheral != nil{
            centralManager.cancelPeripheralConnection(peripheral)
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func centralManagerDidUpdateState(central: CBCentralManager) {
        switch(central.state){
        case CBCentralManagerState.PoweredOn:
            print("CBCentralManagerState.PoweredOn")
            matchFound = false
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
                print("dispatch_async : find matched module")
                sleep(1)
                dispatch_async(dispatch_get_main_queue(),{
                    if !self.matchFound {
                        print("No match module found")
                        self.buttonLock.hidden = true
                        self.buttonUnlock.hidden = true
                        self.imageCap.hidden = true
                        self.imageStart.hidden = true
                    }else{
                        print("Match module found")
                        self.buttonLock.hidden = false
                        self.buttonUnlock.hidden = false
                        self.imageCap.hidden = false
                        self.imageStart.hidden = false
                    }
                })
            })
            centralManager.scanForPeripheralsWithServices(nil, options: nil)
            print("scanForPeripheralsWithServices")
            break
        case CBCentralManagerState.PoweredOff:
            print("CBCentralManagerState.PoweredOff")
            centralManager.stopScan()
            break
        case CBCentralManagerState.Unauthorized:
            print("CBCentralManagerState.Unauthorized")
            break
        case CBCentralManagerState.Resetting:
            print("CBCentralManagerState.Resetting")
            break
        case CBCentralManagerState.Unknown:
            print("CBCentralManagerState.Unknown")
            break
        case CBCentralManagerState.Unsupported:
            print("CBCentralManagerState.Unsupported")
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
        print("didConnectPeripheral")
        setDefaultModule(peripheral.name!)
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
    
    func peripheral(peripheral: CBPeripheral, didUpdateValueForCharacteristic characteristic: CBCharacteristic, error: NSError?) {
        let val = characteristic.value!.hexString
        if(val == ACK_door_locked){
            //ack for locked
            print("\(val) : \(countSendTime)")
            countSendTime += 1
            if !receivedLock{
                receivedLock = true
                showLocked()
                AudioServicesPlayAlertSound(UInt32(kSystemSoundID_Vibrate))
            }
        }else if(val == ACK_door_unlocked){
            //ack for unlocked
            print("\(val) : \(countSendTime)")
            countSendTime += 1
            if !receivedUnlock{
                receivedUnlock = true
                showUnlocked()
                AudioServicesPlayAlertSound(SystemSoundID(kSystemSoundID_Vibrate))
            }
        }else if(val == ACK_engine_started){
            //ack for started
            started = true
            print("\(val) : \(countSendTime)")
            countSendTime += 1
            if !receivedStart{
                receivedStart = true
                showStarted()
            }
        }else if(val == ACK_engine_stopped){
            started = false
            //ack for stopped
            print("\(val) : \(countSendTime)")
            countSendTime += 1
            if !receivedStop{
                receivedStop = true
                showStopped()
            }
        }else if(val == "0240000f"){
            //ack for locked
            print("\(val) : \(countSendTime)")
            logOnScreen("0240000f")
        }else{
            print("\(val) : \(countSendTime)")
            print("\(val) : \(countSendTime)")
            countSendTime += 1
            receivedLock = true
            receivedStop = true
            receivedStart = true
            receivedUnlock = true
        }
        print("Charateristic's value has updated : \(val!)")
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
        print("ViewController : sendCommend")
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
            self.peripheral.writeValue(data, forCharacteristic: self.writeCharacteristic, type: .WithResponse)
            dispatch_async(dispatch_get_main_queue(),{
                print("Send : 1st time")
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
                print("Send : 2nd time")
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
                print("Send : 3rd time")
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
                print("Send : 4th time")
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
                print("Send : 5th time")
            })
        })
    }
    
    func setNotification(enabled: Bool){
        print("setNotification = true")
        peripheral.setNotifyValue(enabled, forCharacteristic: notificationCharacteristic)
    }
    
    
    
    
    
    func showStopped(){
        //        buttonEngine.setImage(UIImage(named: "Engine"), forState: .Normal)
        logOnScreen("Engine shut off")
    }
    
    func showStarted(){
        //        buttonEngine.setImage(UIImage(named: "Engine Start"), forState: .Normal)
        logOnScreen("Engine started")
    }
    
    func showUnlocked(){
        buttonLock.setImage(UIImage(named: "Lock"), forState: .Normal)
        buttonUnlock.setImage(UIImage(named: "Unlock_Glow"), forState: .Normal)
        logOnScreen("Door unlocked")
        //        buttonDoor.setImage(UIImage(named: "Unlock"), forState: .Normal)
    }
    
    func showLocked(){
        buttonLock.setImage(UIImage(named: "Lock_Glow"), forState: .Normal)
        buttonUnlock.setImage(UIImage(named: "Unlock"), forState: .Normal)
        logOnScreen("Door locked")
        //        buttonDoor.setImage(UIImage(named: "Lock"), forState: .Normal)
    }
    
    
    func setAnchorPoint(anchorPoint: CGPoint, forView view: UIView) {
        var newPoint = CGPointMake(view.bounds.size.width * anchorPoint.x, view.bounds.size.height * anchorPoint.y)
        var oldPoint = CGPointMake(view.bounds.size.width * view.layer.anchorPoint.x, view.bounds.size.height * view.layer.anchorPoint.y)
        print("postion \(view.layer.position)")
        newPoint = CGPointApplyAffineTransform(newPoint, view.transform)
        oldPoint = CGPointApplyAffineTransform(oldPoint, view.transform)
        
        var position = view.layer.position
        position.x -= oldPoint.x
        position.x += newPoint.x
        
        position.y -= oldPoint.y
        position.y += newPoint.y
        
        view.layer.anchorPoint = anchorPoint
        view.center = oldPoint
        view.layoutIfNeeded()
        print("postion final \(view.layer.position)")
    }
    
    
    
    func centralManager(central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: NSError?) {
        print("Disconnected")
        if !isManuallyDisconnected {
            central.scanForPeripheralsWithServices(nil, options: nil)
            showControl(false)
        }
    }
    
    
    @IBOutlet var ledBlue: UIImageView!
    @IBOutlet var ledRed: UIImageView!
    @IBOutlet var ledYellow: UIImageView!
    func displayPressState(number : Int){
        switch number {
        case 0:
            ledBlue.image = UIImage(named: "LED_Red")
            break;
        case 1:
            ledYellow.image = UIImage(named: "LED_Red")
            break;
        case 2:
            ledRed.image = UIImage(named: "LED_Red")
            break;
        case 3:
            ledBlue.image = UIImage(named: "LED_Red_Bright")
            break;
        case 4:
            ledYellow.image = UIImage(named: "LED_Red_Bright")
            break;
        case 5:
            ledRed.image = UIImage(named: "LED_Red_Bright")
            break;
        default:
            ledRed.image = UIImage(named: "LED_Dark")
            ledYellow.image = UIImage(named: "LED_Dark")
            ledBlue.image = UIImage(named: "LED_Dark")
            break;
        }
    }
    
    @IBAction func onLongPressStart(sender: UILongPressGestureRecognizer) {
        switch sender.state {
        case UIGestureRecognizerState.Began:
            print("UIGestureRecognizerState.Began")
            isPressing = true
            longPressCountDown = 0
            UIView.animateWithDuration(0.2, animations: {
                var transform = CGAffineTransformIdentity
                transform = CGAffineTransformScale(transform, 0.9, 0.9)
                self.imageStart.transform = transform
            })
            
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
                print("now \(self.longPressCountDown)")
                while self.isPressing && self.longPressCountDown <= 5{
                    dispatch_async(dispatch_get_main_queue(),{
                        //                        self.dislongPressCountDown].setImage(UIImage(named: "Filled Arrow"), forState: .Normal)
                        self.displayPressState(self.longPressCountDown)
                        self.longPressCountDown += 1
                        print("set \(self.longPressCountDown)")
                    })
                    usleep(150000)
                }
            })
            break
        case UIGestureRecognizerState.Ended:
            print("UIGestureRecognizerState.Ended")
            isPressing = false
            self.displayPressState(6)
            //            for index in 0...5 {
            //                signal[index].setImage(UIImage(named: "Arrow"), forState: .Normal)
            //            }
            UIView.animateWithDuration(0.2, animations: {
                let transform = CGAffineTransformIdentity
                self.imageStart.transform = transform
            })
            break
        default:
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
    
    //    func newDoorToEngine() {
    //        print("start: \(self.imageIndicator.layer.position)")
    //        UIView.animateWithDuration(1, animations: {
    //            let fullRotation = CGFloat(M_PI * 2)
    //            var transform = CGAffineTransformIdentity
    //            transform = CGAffineTransformScale(transform, 1.5, 1.5)
    //            transform = CGAffineTransformRotate(transform, 3/4 * fullRotation)
    //            transform = CGAffineTransformTranslate(transform, 0, 4*self.imageIndicator.frame.origin.y )
    //            self.imageIndicator.transform = transform
    //            }, completion: {finished in
    //                // any code entered here will be applied
    //                // once the animation has completed
    //                self.imageIndicator.layoutIfNeeded()
    //                print("end: \(self.buttonGarage.layer.position)")
    //        })
    //        UIView.animateWithDuration(1, animations: {
    //            let fullRotation = CGFloat(M_PI * 2)
    //            var transform = CGAffineTransformIdentity
    //            transform = CGAffineTransformScale(transform, 1.5, 1.5)
    //            transform = CGAffineTransformRotate(transform, 3/4 * fullRotation)
    //            transform = CGAffineTransformTranslate(transform, -0,4*self.imageEngineIndicator.frame.origin.y )
    //            self.imageEngineIndicator.image = UIImage(named: "Stopped")
    //            self.imageEngineIndicator.alpha = 1
    //            self.imageEngineIndicator.transform = transform
    //            }, completion: {finished in
    //                self.imageEngineIndicator.layoutIfNeeded()
    //                print("end: \(self.buttonGarage.layer.position)")
    //        })
    //        indicator = 1
    //    }
    //
    //    func newEngineToDoor() {
    //        UIView.animateWithDuration(1, animations: {
    //            let transform = CGAffineTransformIdentity
    //            self.imageIndicator.transform = transform
    //            }, completion: {finished in
    //                self.imageIndicator.layoutIfNeeded()
    //        })
    //        UIView.animateWithDuration(1, animations: {
    //            let transform = CGAffineTransformIdentity
    //            self.imageEngineIndicator.transform = transform
    //            self.imageEngineIndicator.alpha = 0
    //            }, completion: {finished in
    //                self.imageEngineIndicator.layoutIfNeeded()
    //        })
    //        indicator = 0
    //    }
    //
    //    func doorToEngine(){
    //        let fullRotation = CGFloat(M_PI * 2)
    //        UIView.animateKeyframesWithDuration(3, delay: 0, options: UIViewKeyframeAnimationOptions.CalculationModeLinear, animations: {
    //            // each keyframe needs to be added here
    //            // within each keyframe the relativeStartTime and relativeDuration need to be values between 0.0 and 1.0
    //            UIView.addKeyframeWithRelativeStartTime(0, relativeDuration: 1, animations: {
    //                self.buttonGarage.transform = CGAffineTransformMakeTranslation(-self.buttonGarage.frame.origin.x * 1 / 4, -self.buttonGarage.frame.origin.y / 2)
    //            })
    //            //
    //            //            UIView.addKeyframeWithRelativeStartTime(1, relativeDuration: 1, animations: {
    //            //                // start at 0.00s (5s × 0)
    //            //                // duration 1.67s (5s × 1/3)
    //            //                // end at   1.67s (0.00s + 1.67s)
    //            //                self.buttonGarage.transform = CGAffineTransformMakeScale(2.0,2.0)
    //            //            })
    //            UIView.addKeyframeWithRelativeStartTime(2, relativeDuration: 1, animations: {
    //                self.buttonGarage.transform = CGAffineTransformMakeRotation(3/4 * fullRotation)
    //            })
    //
    //            }, completion: {finished in
    //                // any code entered here will be applied
    //                // once the animation has completed
    //                self.buttonGarage.layoutIfNeeded()
    //        })
    //    }
    
    func checkDatabase(){
        print("ViewController : checkDatabase")
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
            //            newEngineToDoor()
        }else if indicator == 0 {
            //            newDoorToEngine()
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
        for p in navigationController!.navigationBar.subviews {
            for c in p.subviews {
                if c is UIImageView {
                    c.removeFromSuperview()
                }
            }
        }
    }
    func setUpNavigationBar(){
        print("setUpNavigationBar")
//        navigationController?.navigationBar.barTintColor = UIColor.whiteColor() // Set top bar color
        
        navigationController?.navigationItem.leftBarButtonItem?.setTitleTextAttributes([NSFontAttributeName: UIFont(name: "Avenir Next", size: 17)!], forState: UIControlState.Normal)
        navigationController?.navigationItem.leftBarButtonItem?.setTitleTextAttributes([NSForegroundColorAttributeName:UIColor.yellowColor()], forState: UIControlState.Normal)
        navigationController?.navigationBar.setBackgroundImage(UIImage(), forBarMetrics: .Default)
        navigationController?.navigationBar.shadowImage = UIImage()
        navigationController?.navigationBar.translucent = true
        navigationController?.navigationBar.barStyle = UIBarStyle.BlackTranslucent
        navigationController?.navigationBar.tintColor = UIColor.greenColor()
        navigationController?.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName:UIColor.redColor()]    //set Title color
        navigationController?.navigationBar.titleTextAttributes = [NSFontAttributeName: UIFont(name: "Avenir Next", size: 20)!]
        removeBorderFromBar()
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
    
    func getDefaultModule(){
        print("ViewController : getDefaultModule")
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
    
    
    func setDefaultModule(value: String){
        print("set default : \(value)")
        NSUserDefaults.standardUserDefaults().setObject(value, forKey: "defaultModule")
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
        print("getLsetLastScene : Control")
        NSUserDefaults.standardUserDefaults().setObject("Control", forKey: "lastScene")
    }
}

