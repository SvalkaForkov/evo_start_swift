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
    let DBG = true
    
    let ACK_door_unlocked = "00000002"
    let ACK_door_locked = "00008001"
    let ACK_trunk_unlocked = ""
    let ACK_trunk_locked = ""
    let ACK_engine_started = "00000201"
    let ACK_engine_stopped = "00000001"
    
    let tag_default_module = "defaultModule"
    let tag_last_scene = "lastScene"
    var centralManager:CBCentralManager!
    var peripheral : CBPeripheral!
    var service : CBService!
    var writeCharacteristic : CBCharacteristic!
    var notificationCharacteristic : CBCharacteristic!
    var showingBack = false
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
    
    @IBOutlet var buttonGPS: UIButton!
    @IBOutlet var imageCap: UIImageView!
    @IBOutlet var imageStart: UIImageView!
    @IBOutlet var buttonClearLog: UIButton!
    @IBOutlet var buttonCover: UIButton!
    @IBOutlet var swipeDown: UISwipeGestureRecognizer!
    @IBOutlet var swipeUp: UISwipeGestureRecognizer!
    @IBOutlet var longPressStart: UILongPressGestureRecognizer!
    @IBOutlet var imageViewDoors: UIImageView!
    @IBOutlet var imageViewEngine: UIImageView!
    @IBOutlet var imageViewTrunk: UIImageView!
    @IBOutlet var imageViewCar: UIImageView!
    @IBOutlet var labelMessage: UILabel!
    @IBOutlet var capContainerView: UIView!
    @IBOutlet var capContainerViewBack: UIView!
    
    @IBOutlet var imageViewTempretureBackground: UIImageView!
    @IBOutlet var imageViewFuelBackground: UIImageView!
    @IBOutlet var needleFuel: UIImageView!
    @IBOutlet var needleTemp: UIImageView!
    @IBOutlet var needleBatt: UIImageView!
    @IBOutlet var needleRPM: UIImageView!
    override func viewDidLoad() {
        logEvent("ViewController : viewDidLoad")
        super.viewDidLoad()
        setUpNavigationBar()
        setUpViews()
    }
    
    override func viewWillAppear(animated: Bool) {
        logEvent("ViewController : viewWillAppear")
        getDefaultModuleName()
        if module != "" {
            centralManager = CBCentralManager(delegate: self, queue:nil)
            buttonGarage.setImage(UIImage(named: "Garage"), forState: .Normal)
        }else{
            buttonGarage.setImage(UIImage(named: "Add Car"), forState: .Normal)
        }
    }
    
    func setUpViews(){
        logEvent("setupViews")
        longPressStart.enabled = false
        buttonCover.backgroundColor = UIColor.clearColor()
        buttonCover.clipsToBounds = true
        
        imageCap.backgroundColor = UIColor.clearColor()
        
        imageCap.layoutIfNeeded()
        imageCap.clipsToBounds = true
        
        imageStart.backgroundColor = UIColor.clearColor()
        imageStart.layoutIfNeeded()
        imageStart.clipsToBounds = true
        
        buttonUnlock.layer.cornerRadius = 25.0
        buttonUnlock.clipsToBounds = true
        
        buttonLock.layer.cornerRadius = 25.0
        buttonLock.clipsToBounds = true
        
        buttonGarage.clipsToBounds = true
        setAnchorPoint(CGPoint(x: 0.5, y: 0.0), forView: self.imageStart)
        setAnchorPoint(CGPoint(x: 0.5, y: 0.0), forView: self.imageCap)
    }
    
    override func viewDidAppear(animated: Bool) {
        logEvent("viewDidAppear")
        setLastScene()
        needleBatt.transform = CGAffineTransformMakeRotation(CGFloat(M_PI) * getBattAngle(0) / 180)
        needleRPM.transform = CGAffineTransformMakeRotation(CGFloat(M_PI) * getRPMAngle(0) / 180)
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        logEvent("viewWillDisappear")
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
            logEvent("CBCentralManagerState.PoweredOn")
            matchFound = false
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
                self.logEvent("dispatch_async : find matched module")
                sleep(1)
                dispatch_async(dispatch_get_main_queue(),{
                    if !self.matchFound {
                        self.logEvent("No match module found")
                    }else{
                        self.logEvent("Match module found")
                        self.buttonLock.hidden = false
                        self.buttonUnlock.hidden = false
                        self.imageCap.hidden = false
                        self.imageStart.hidden = false
                    }
                })
            })
            centralManager.scanForPeripheralsWithServices(nil, options: nil)
            logEvent("scanForPeripheralsWithServices")
            break
        case CBCentralManagerState.PoweredOff:
            logEvent("CBCentralManagerState.PoweredOff")
            centralManager.stopScan()
            break
        case CBCentralManagerState.Unauthorized:
            logEvent("CBCentralManagerState.Unauthorized")
            break
        case CBCentralManagerState.Resetting:
            logEvent("CBCentralManagerState.Resetting")
            break
        case CBCentralManagerState.Unknown:
            logEvent("CBCentralManagerState.Unknown")
            break
        case CBCentralManagerState.Unsupported:
            logEvent("CBCentralManagerState.Unsupported")
            break
        }
    }
    
    func centralManager(central: CBCentralManager, didDiscoverPeripheral peripheral: CBPeripheral, advertisementData: [String : AnyObject], RSSI: NSNumber) {
        let nameOfDeviceFound = peripheral.name as String!
        if nameOfDeviceFound != nil {
            logEvent("Did discover : \(nameOfDeviceFound)")
            logEvent("Default module is : \(module)")
            if nameOfDeviceFound == module{
                logEvent("Match and stop scan")
                matchFound = true
                centralManager.stopScan()
                self.peripheral = peripheral
                self.peripheral.delegate = self
                centralManager.connectPeripheral(self.peripheral, options: nil)
                logEvent("Connecting : \(self.peripheral.name)")
            }
        }
    }
    
    func centralManager(central: CBCentralManager, didConnectPeripheral peripheral: CBPeripheral) {
        logEvent("didConnectPeripheral")
        setDefaultModule(peripheral.name!)
        peripheral.discoverServices([CBUUID(string: "1234")])
        logEvent("DiscoverService: 1234")
    }
    
    func peripheral(peripheral: CBPeripheral, didDiscoverServices error: NSError?) {
        logEvent("Service discoverd")
        for service in peripheral.services! {
            if(service.UUID.UUIDString == "1234"){
                self.service = service
            }
            logEvent("Found service: \(service.UUID)")
            peripheral.discoverCharacteristics([CBUUID(string: "1235"),CBUUID(string: "1236")], forService: service)
        }
    }
    
    func peripheral(peripheral: CBPeripheral, didDiscoverCharacteristicsForService service: CBService, error: NSError?) {
        logEvent("Discovered characteristic")
        for characteristic in service.characteristics! {
            if(characteristic.UUID.UUIDString == "1235"){
                self.writeCharacteristic = characteristic
                logEvent("set writeCharacteristic")
            }
            if(characteristic.UUID.UUIDString == "1236"){
                self.notificationCharacteristic = characteristic
                setNotification(true)
            }
            logEvent("Found characteristic: \(characteristic.UUID)")
        }
        logEvent("Connection ready")
        showControl(true)
    }
    
    func peripheral(peripheral: CBPeripheral, didUpdateValueForCharacteristic characteristic: CBCharacteristic, error: NSError?) {
        let val = characteristic.value!.hexString
        if(val == ACK_door_locked){
            //ack for locked
            logEvent("\(val) : \(countSendTime)")
            countSendTime += 1
            if !receivedLock{
                receivedLock = true
                showLocked()            }
        }else if(val == ACK_door_unlocked){
            //ack for unlocked
            logEvent("\(val) : \(countSendTime)")
            countSendTime += 1
            if !receivedUnlock{
                receivedUnlock = true
                showUnlocked()
            }
        }else if(val == ACK_engine_started){
            //ack for started
            started = true
            logEvent("\(val) : \(countSendTime)")
            countSendTime += 1
            if !receivedStart{
                receivedStart = true
                showStarted()
            }
        }else if(val == ACK_engine_stopped){
            started = false
            //ack for stopped
            logEvent("\(val) : \(countSendTime)")
            countSendTime += 1
            if !receivedStop{
                receivedStop = true
                showStopped()
            }
        }else if(val == "0240000f"){
            //ack for locked
            logEvent("\(val) : \(countSendTime)")
            displayMessage("0240000f")
        }else{
            logEvent("\(val) : \(countSendTime)")
            logEvent("\(val) : \(countSendTime)")
            countSendTime += 1
            receivedLock = true
            receivedStop = true
            receivedStart = true
            receivedUnlock = true
        }
        logEvent("Charateristic's value has updated : \(val!)")
    }
    
    func showControl(val: Bool){
        if(!val){
            logEvent("set disable")
            buttonLock.enabled = false
            buttonUnlock.enabled = false
        }else{
            logEvent("set enable")
            buttonLock.enabled = true
            buttonUnlock.enabled = true
        }
    }
    
    @IBAction func onLock(sender: UIButton) {
        
        logEvent("onlock")
        let data = NSData(bytes: [0x30] as [UInt8], length: 1)
        sendCommend(data, action: 0)
    }
    
    
    @IBAction func onUnlock(sender: UIButton) {        logEvent("onUnlock")
        let data = NSData(bytes: [0x31] as [UInt8], length: 1)
        sendCommend(data, action: 1)
    }
    
    
    
    @IBAction func onStart(sender: UIButton) {
        logEvent("on start: started = \(started)")
        if started {
            logEvent("go stop engine")
            stopEngine()
        } else {
            logEvent("go start engine")
            startEngine()
        }
    }
    
    func startEngine() {
        logEvent("startEngine")
        let data = NSData(bytes: [0x32] as [UInt8], length: 1)
        sendCommend(data, action: 2)
        started = true
    }
    
    func stopEngine() {
        logEvent("stopEngine")
        let data = NSData(bytes: [0x33] as [UInt8], length: 1)
        receivedStop = false
        sendCommend(data, action: 3)
        started = false
    }
    
    func sendCommend(data : NSData, action : Int){
        logEvent("ViewController : sendCommend")
        if peripheral != nil && writeCharacteristic != nil {
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
                    self.logEvent("Send : 1st time")
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
                    self.logEvent("Send : 2nd time")
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
                    self.logEvent("Send : 3rd time")
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
                    self.logEvent("Send : 4th time")
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
                    self.logEvent("Send : 5th time")
                })
            })
        } else {
            logEvent("peripheral or writeCharateristic is nil")
        }
    }
    
    func setNotification(enabled: Bool){
        logEvent("setNotification = true")
        if peripheral != nil && notificationCharacteristic != nil {
            peripheral.setNotifyValue(enabled, forCharacteristic: notificationCharacteristic)
        }
    }
    
    func showStopped(){
        displayMessage("Engine shut off")
        UIView.animateWithDuration(200, animations: {
            self.imageViewEngine.image = UIImage(named: "engineoff")
        })
        
        updateRPM(0)
        updateBatt(0)
        updateFuel(0)
        updateTemperature(0)
        AudioServicesPlayAlertSound(UInt32(kSystemSoundID_Vibrate))
    }
    
    func showStarted(){
        displayMessage("Engine started")
        UIView.animateWithDuration(200, animations: {
            self.imageViewEngine.image = UIImage(named: "engineon")
        })
        updateRPM(2500)
        updateBatt(50)
        updateFuel(50)
        updateTemperature(30)
        AudioServicesPlayAlertSound(UInt32(kSystemSoundID_Vibrate))
    }
    
    func showUnlocked(){
        UIView.animateWithDuration(200, animations: {
            self.buttonLock.setImage(UIImage(named: "Lock"), forState: .Normal)
            self.buttonUnlock.setImage(UIImage(named: "Unlock_Glow"), forState: .Normal)
            self.imageViewDoors.image = UIImage(named: "doorunlocked")
        })
        AudioServicesPlayAlertSound(UInt32(kSystemSoundID_Vibrate))
        displayMessage("Door unlocked")
    }
    
    func showLocked(){
        UIView.animateWithDuration(200, animations: {
            self.buttonLock.setImage(UIImage(named: "Lock_Glow"), forState: .Normal)
            self.buttonUnlock.setImage(UIImage(named: "Unlock"), forState: .Normal)
            self.imageViewDoors.image = UIImage(named: "doorlocked")
        })
        AudioServicesPlayAlertSound(UInt32(kSystemSoundID_Vibrate))
        displayMessage("Door locked")
    }
    
    
    func setAnchorPoint(anchorPoint: CGPoint, forView view: UIView) {
        logEvent("Set anchor")
        var newPoint = CGPointMake(view.bounds.size.width * anchorPoint.x, view.bounds.size.height * anchorPoint.y)
        var oldPoint = CGPointMake(view.bounds.size.width * view.layer.anchorPoint.x, view.bounds.size.height * view.layer.anchorPoint.y)
        //        logEvent("postion \(view.layer.position)")
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
        logEvent("postion final \(view.layer.position)")
    }
    
    func centralManager(central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: NSError?) {
        logEvent("Disconnected")
        if !isManuallyDisconnected {
            central.scanForPeripheralsWithServices(nil, options: nil)
            showControl(false)
        }
    }
    
    @IBAction func onLongPressStart(sender: UILongPressGestureRecognizer) {
        switch sender.state {
        case UIGestureRecognizerState.Began:
            logEvent("UIGestureRecognizerState.Began")
            isPressing = true
            longPressCountDown = 0
            imageStart.image = UIImage(named: "Start Small")
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
                self.logEvent("now \(self.longPressCountDown)")
                while self.isPressing && self.longPressCountDown <= 5{
                    dispatch_async(dispatch_get_main_queue(),{
                        self.longPressCountDown += 1
                        self.logEvent("set \(self.longPressCountDown)")
                    })
                    usleep(150000)
                }
                if self.started {
                    self.stopEngine()
                }else {
                    self.startEngine()
                }
            })
            break
        case UIGestureRecognizerState.Ended:
            logEvent("UIGestureRecognizerState.Ended")
            isPressing = false
            imageStart.image = UIImage(named: "Start")
            break
        default:
            break
        }
    }
    
    @IBAction func onDown(sender: UISwipeGestureRecognizer) {
        logEvent("swipe down")
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
        logEvent("swipe up")
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
    
    func checkDatabase(){
        logEvent("Check database for registered vehicle")
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        let dataController = appDelegate.dataController
        let vehicles : [Vehicle] = dataController.getAllVehicles()
        if vehicles.count > 0 {
            module = vehicles[0].module!
            logEvent("use first vehicle in the database")
        }else {
            module = ""
            logEvent("no vehicle registerd")
        }
    }
    
    @IBAction func onGarageButton(sender: UIButton) {
        flipControl()
//        if module != "" {
//            logEvent("on Garage button clicked")
//            centralManager.stopScan()
//            if peripheral != nil {
//                centralManager.cancelPeripheralConnection(peripheral)
//                centralManager = nil
//                logEvent("disconnect")
//            }
//            performSegueWithIdentifier("control2garage", sender: sender)
//        }else{
//            performSegueWithIdentifier("control2scan", sender: sender)
//        }
    }
    
    
    @IBAction func onGPSButton(sender: UIButton) {
        performSegueWithIdentifier("control2map", sender: sender)
    }
    
    func removeTopbarShadow() {
        for p in navigationController!.navigationBar.subviews {
            for c in p.subviews {
                if c is UIImageView {
                    c.removeFromSuperview()
                }
            }
        }
    }
    
    func setUpNavigationBar(){
        logEvent("SetUpNavigationBar")
        navigationController?.navigationItem.leftBarButtonItem?.setTitleTextAttributes([NSFontAttributeName: UIFont(name: "Avenir Next", size: 17)!], forState: UIControlState.Normal)
        navigationController?.navigationItem.leftBarButtonItem?.setTitleTextAttributes([NSForegroundColorAttributeName:UIColor.yellowColor()], forState: UIControlState.Normal)
        navigationController?.navigationBar.setBackgroundImage(UIImage(), forBarMetrics: .Default)
        navigationController?.navigationBar.shadowImage = UIImage()
        navigationController?.navigationBar.translucent = true
        navigationController?.navigationBar.barStyle = UIBarStyle.BlackTranslucent
        navigationController?.navigationBar.tintColor = UIColor.darkGrayColor()  //set navigation item title color
        navigationController?.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName:UIColor.blueColor()]    //set Title color
        navigationController?.navigationBar.titleTextAttributes = [NSFontAttributeName: UIFont(name: "Avenir Next", size: 20)!]
        removeTopbarShadow()
    }
    
    func getColorFromHex(value: UInt) -> UIColor{
        return UIColor(
            red: CGFloat((value & 0xFF0000) >> 16) / 255.0,
            green: CGFloat((value & 0x00FF00) >> 8) / 255.0,
            blue: CGFloat(value & 0x0000FF) / 255.0,
            alpha: CGFloat(1.0)
        )
    }
    
    func displayMessage(line: String){
        labelMessage.text = line
        UIView.animateWithDuration(200, animations: {
            self.labelMessage.layer.position = CGPoint(x: 1.0,y: 1.0)
            self.labelMessage.alpha = 0.5
        })
    }
    
    func getDefaultModuleName(){
        logEvent("Get Default Module Name")
        let defaultModule = NSUserDefaults.standardUserDefaults().objectForKey(tag_default_module)
            as? String
        if defaultModule != nil {
            module = defaultModule!
            logEvent("default is not nil : \(module)")
        }else{
            logEvent("default is nil")
            module = ""
            checkDatabase()
        }
    }
    
    func setDefaultModule(value: String){
        logEvent("Set default : \(value)")
        NSUserDefaults.standardUserDefaults().setObject(value, forKey: tag_default_module)
    }
    
    func getLastScene() -> String{
        logEvent("Get Last Scene")
        let lastScene =
            NSUserDefaults.standardUserDefaults().objectForKey(tag_last_scene)
                as? String
        if lastScene != nil {
            return lastScene!
        }else{
            return ""
        }
    }
    
    func setLastScene(){
        logEvent("Set Last Scene : Control")
        NSUserDefaults.standardUserDefaults().setObject("Control", forKey: tag_last_scene)
    }
    
    func logEvent(string :String){
        if DBG {
            print("\(string)")
        }
    }
    
    func rotateViewToAngle(view:UIView, angle: CGFloat){
        UIView.animateWithDuration(1.5, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0, options: UIViewAnimationOptions.CurveEaseIn, animations: {
            view.transform = CGAffineTransformMakeRotation(CGFloat(M_PI) * angle / 180)
            }, completion: nil)
    }
    
    func getBattAngle(percentage: CGFloat) -> CGFloat{
        return 313 - percentage/10*12.5
    }
    
    func getFuelAngle(percentage: CGFloat) -> CGFloat{
        return 60 + 240 * percentage/100
    }
    
    func getTempAngle(temp: CGFloat) -> CGFloat{
        return 360 * temp / 100
    }
    
    func getRPMAngle(rpm: CGFloat) -> CGFloat{
        if rpm < 2000 {
            return 45 + rpm/500*13
        }else{
            return 45 + 52 + (rpm-2000)/1000*13
        }
    }
    
    func updateBatt(percentage: CGFloat){
        rotateViewToAngle(needleBatt, angle: getBattAngle(percentage))
    }
    
    func updateRPM(rpm : CGFloat){
        rotateViewToAngle(needleRPM, angle: getRPMAngle(rpm))
    }
    
    func updateFuel(percentage : CGFloat){
        rotateViewToAngle(needleFuel, angle: getFuelAngle(percentage))
    }
    
    func updateTemperature(temp: CGFloat){
        rotateViewToAngle(needleTemp, angle: getTempAngle(temp))
    }
    
    func animateFlip(){
            UIView.transitionFromView(capContainerView, toView: capContainerViewBack, duration: 1, options: UIViewAnimationOptions.TransitionFlipFromRight, completion: nil)
            
    }
    
    func flipControl(){
        if showingBack {
            showingBack = false
            UIView.animateWithDuration(0.5, animations: {
                self.capContainerView.alpha = 1
                self.buttonLock.alpha = 1
                self.buttonUnlock.alpha = 1
                self.capContainerViewBack.alpha = 0
                self.capContainerViewBack.center.y = self.capContainerViewBack.center.y + self.capContainerViewBack.bounds.height
                let transform = CGAffineTransformIdentity
                self.buttonGarage.transform = transform
                }, completion: { finished in
                  self.capContainerViewBack.hidden = true
            })
        }else{
            showingBack = true
            self.capContainerViewBack.alpha = 0
            self.capContainerViewBack.hidden = false
            UIView.animateWithDuration(0.5, delay: 0, options: UIViewAnimationOptions.CurveEaseInOut, animations: {
                self.capContainerViewBack.alpha = 1
                self.capContainerViewBack.center.y = self.capContainerViewBack.center.y - self.capContainerViewBack.bounds.height
                self.capContainerViewBack.hidden = false
                self.capContainerView.alpha = 0
                self.buttonLock.alpha = 0
                self.buttonUnlock.alpha = 0
                var transform = CGAffineTransformIdentity
                transform = CGAffineTransformRotate(transform, CGFloat(M_PI / 2))
                self.buttonGarage.transform = transform
                }, completion: { finished in
            })
        }
    }
}

