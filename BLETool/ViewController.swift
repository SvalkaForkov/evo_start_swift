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
    
    let mask9lock : UInt32 = 0x00008000
    let mask9doors : UInt32 = 0x00004000
    let mask9trunk : UInt32 = 0x00002000
    let mask9hood : UInt32 = 0x00001000
    let mask9ignition : UInt32 = 0x00000800
    let mask9engine : UInt32 = 0x00000400
    let mask9remote : UInt32 = 0x00000200
    let mask9valet : UInt32 = 0x00000100
    
    let tag_default_module = "defaultModule"
    let tag_last_scene = "lastScene"
    let fontName = "NeuropolXRg-Regular"
    
    var centralManager:CBCentralManager!
    var peripheral : CBPeripheral!
    var service : CBService!
    var writeCharacteristic : CBCharacteristic!
    var notificationCharacteristic : CBCharacteristic!
    
    var paneSlidedUp = false
    var module = ""
    
    var longPressCountDown = 0
    var isPressing = false
    
    @IBOutlet var buttonLock: UIButton!
    @IBOutlet var buttonUnlock: UIButton!
    @IBOutlet var buttonMore: UIButton!
    
    @IBOutlet var coverEmptyGarage: UIView!
    @IBOutlet var buttonGarage: UIButton!
    @IBOutlet var buttonTrunk: UIButton!
    @IBOutlet var buttonValet: UIButton!
    
    @IBOutlet var coverLostConnection: UIView!
    @IBOutlet var stateView: UIView!
    @IBOutlet var buttonGPS: UIButton!
    @IBOutlet var imageCap: UIImageView!
    @IBOutlet var imageStart: UIImageView!
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
    
    @IBOutlet var slideUpView: UIView!
    
    @IBOutlet var buttonAddFromEmpty: UIButton!
    @IBOutlet var imageViewTempretureBackground: UIImageView!
    @IBOutlet var imageViewFuelBackground: UIImageView!
    @IBOutlet var needleFuel: UIImageView!
    @IBOutlet var needleTemp: UIImageView!
    @IBOutlet var needleBatt: UIImageView!
    @IBOutlet var needleRPM: UIImageView!
    
    var stateLock = false
    var stateDoor = false
    var stateTrunk = false
    var stateHood = false
    var stateEngine = false
    var stateIgnition = false
    var stateRemote = false
    var stateValet = false
    
    var stateBattery = 0
    var stateTemperature = 0
    var stateRPM = 0
    var stateFuel = 0
    
    var isMatchFound = false
    var isConnected = false
    
    override func viewDidLoad() {
        logEvent("ViewController : viewDidLoad")
        super.viewDidLoad()
        setUpNavigationBar()
        setUpStaticViews()
    }
    
    override func viewWillAppear(animated: Bool) {
        logEvent("ViewController : viewWillAppear")
        module = getDefaultModuleName()
        if module != "" {
            coverEmptyGarage.hidden = true
            centralManager = CBCentralManager(delegate: self, queue:nil)
            buttonMore.setImage(UIImage(named: "More Control"), forState: .Normal)
        }else{
            coverEmptyGarage.hidden = false
        }
    }
    
    override func viewDidAppear(animated: Bool) {
        logEvent("viewDidAppear")
        setLastScene()
        needleBatt.transform = CGAffineTransformMakeRotation(CGFloat(M_PI) * getBattAngle(0) / 180)
        needleRPM.transform = CGAffineTransformMakeRotation(CGFloat(M_PI) * getRPMAngle(0) / 180)
        needleFuel.transform = CGAffineTransformMakeRotation(CGFloat(M_PI) * getFuelAngle(0) / 180)
        needleTemp.transform = CGAffineTransformMakeRotation(CGFloat(M_PI) * getTempAngle(-40) / 180)
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        logEvent("viewWillDisappear")
        if centralManager != nil && peripheral != nil{
            centralManager.cancelPeripheralConnection(peripheral)
            centralManager = nil
            isConnected = false
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func centralManagerDidUpdateState(central: CBCentralManager) {
        switch(central.state){
        case CBCentralManagerState.PoweredOn:
            logEvent("CBCentralManagerState.PoweredOn")
            isMatchFound = false
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
                self.logEvent("dispatch_async : find matched module")
                sleep(2)
                dispatch_async(dispatch_get_main_queue(),{
                    if !self.isMatchFound {
                        self.logEvent("No match module found")
                        self.coverLostConnection.hidden = false
                    }else{
                        self.logEvent("Match module found")
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
                isMatchFound = true
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
        isConnected = true
        self.coverLostConnection.hidden = true
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
    
    func centralManager(central: CBCentralManager, didFailToConnectPeripheral peripheral: CBPeripheral, error: NSError?) {
        print("failed to connect")
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
    
    func nsdataToInt(data: NSData) -> UInt32 {
        var result : UInt32 = 0
        data.getBytes(&result, length: sizeof(UInt32))
        //        let hex = data.hexString
        return result
    }
    
    func hexStringToInt(hex: String) -> UInt32 {
        return UInt32(strtoul(hex, nil, 16))
    }
    
    func peripheral(peripheral: CBPeripheral, didUpdateValueForCharacteristic characteristic: CBCharacteristic, error: NSError?) {
        
        let intValue = hexStringToInt(characteristic.value!.hexString)
        //        let masks9 : [UInt32] = [mask9lock, mask9doors, mask9trunk, mask9hood, mask9ignition, mask9engine, mask9remote, mask9valet]
        
        if intValue & mask9lock != 0 {
            if waitingList.contains(0x71){
                let index = waitingList.indexOf(0x71)
                waitingList.removeAtIndex(index!)
                showLocked()
            }
            stateLock = true
        }else{
            if waitingList.contains(0x70){
                let index = waitingList.indexOf(0x70)
                waitingList.removeAtIndex(index!)
                showUnlocked()
            }
            stateLock = false
        }
        if intValue & mask9doors != 0 {
            if !stateDoor {
                showDoorOpened()
            }
            if waitingList.contains(0x61){
                let index = waitingList.indexOf(0x61)
                waitingList.removeAtIndex(index!)
            }
            stateDoor = true
        }else{
            if stateDoor {
                showDoorClosed()
            }
            if waitingList.contains(0x60){
                let index = waitingList.indexOf(0x60)
                waitingList.removeAtIndex(index!)
            }
            stateDoor = false
        }
        if intValue & mask9trunk != 0 {
            if !stateTrunk {
showTrunkOpened()
            }
            if waitingList.contains(0x51){
                let index = waitingList.indexOf(0x51)
                waitingList.removeAtIndex(index!)
            }
            stateTrunk = true
        }else{
            if stateTrunk {
showTrunkClosed()
            }
            if waitingList.contains(0x50){
                let index = waitingList.indexOf(0x50)
                waitingList.removeAtIndex(index!)
            }
            stateTrunk = false
        }
        if intValue & mask9hood != 0 {
            if !stateHood {
showHoodOpened()
            }
            if waitingList.contains(0x41){
                let index = waitingList.indexOf(0x41)
                waitingList.removeAtIndex(index!)
            }
            stateHood = true
        }else{
            if stateHood {
                showHoodClosed()
            }
            if waitingList.contains(0x40){
                let index = waitingList.indexOf(0x40)
                waitingList.removeAtIndex(index!)
            }
            stateHood = false
        }
        if intValue & mask9ignition != 0 {
            if waitingList.contains(0x31){
                let index = waitingList.indexOf(0x31)
                waitingList.removeAtIndex(index!)
                showIgnitionOn()
                print("ignition on")
            }
            stateIgnition = true
        }else{
            if stateIgnition {
//                showUnlocked()
            }
            if waitingList.contains(0x30){
                let index = waitingList.indexOf(0x30)
                waitingList.removeAtIndex(index!)
            }
            stateIgnition = false
        }
        if intValue & mask9engine != 0 {
            if !stateEngine {
                showStarted()
            }
            if waitingList.contains(0x21){
                let index = waitingList.indexOf(0x21)
                waitingList.removeAtIndex(index!)
            }
            stateEngine = true
        }else{
            if stateEngine {
                showStopped()
            }
            if waitingList.contains(0x20){
                let index = waitingList.indexOf(0x20)
                waitingList.removeAtIndex(index!)
            }
            stateEngine = false
        }
        if intValue & mask9remote != 0 {
            if !stateRemote {
//                showLocked()
            }
            if waitingList.contains(0x11){
                let index = waitingList.indexOf(0x11)
                waitingList.removeAtIndex(index!)
            }
            stateRemote = true
        }else{
            if stateRemote {
//                showUnlocked()
            }
            if waitingList.contains(0x10){
                let index = waitingList.indexOf(0x10)
                waitingList.removeAtIndex(index!)
            }
            stateRemote = false
        }
        if intValue & mask9valet != 0 {
            if !stateValet {
//                showLocked()
            }
            if waitingList.contains(0x01){
                let index = waitingList.indexOf(0x01)
                waitingList.removeAtIndex(index!)
            }
            stateValet = true
        }else{
            if stateValet {
//                showUnlocked()
            }
            if waitingList.contains(0x00){
                let index = waitingList.indexOf(0x00)
                waitingList.removeAtIndex(index!)
            }
            stateValet = false
        }
        print(characteristic.value!.hexString)
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
        sendCommand(data, actionId: 0x71)
    }
    
    
    @IBAction func onUnlock(sender: UIButton) {
        logEvent("onUnlock")
        let data = NSData(bytes: [0x31] as [UInt8], length: 1)
        sendCommand(data, actionId: 0x70)
    }
    
    
    
    @IBAction func onStart(sender: UIButton) {
        logEvent("on start: started = \(stateEngine)")
        if stateEngine {
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
        sendCommand(data, actionId: 0x21)
    }
    
    func stopEngine() {
        logEvent("stopEngine")
        let data = NSData(bytes: [0x33] as [UInt8], length: 1)
        sendCommand(data, actionId: 0x20)
    }
    
    var waitingList : [UInt8] = []
    
    func sendCommand(data : NSData, actionId: UInt8){
        if peripheral != nil && writeCharacteristic != nil {
            if !waitingList.contains(actionId){
                waitingList.append(actionId)
            }
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
                self.peripheral.writeValue(data, forCharacteristic: self.writeCharacteristic, type: .WithResponse)
                if self.DBG {
                    print("1st time")
                }
                sleep(1)
                if !self.waitingList.contains(actionId) {
                    return
                }
                
                self.peripheral.writeValue(data, forCharacteristic: self.writeCharacteristic, type: .WithResponse)
                if self.DBG {
                    print("2nd time")
                }
                sleep(1)
                if !self.waitingList.contains(actionId) {
                    return
                }
                
                self.peripheral.writeValue(data, forCharacteristic: self.writeCharacteristic, type: .WithResponse)
                if self.DBG {
                    print("3rd time")
                }
                sleep(1)
                if !self.waitingList.contains(actionId) {
                    return
                }
                
                self.peripheral.writeValue(data, forCharacteristic: self.writeCharacteristic, type: .WithResponse)
                if self.DBG {
                    print("4th time")
                }
                sleep(1)
                if !self.waitingList.contains(actionId) {
                    return
                }
                
                self.peripheral.writeValue(data, forCharacteristic: self.writeCharacteristic, type: .WithResponse)
                if self.DBG {
                    print("5th time")
                }
            })
        }
    }
    
    /*func sendCommend(data : NSData, action : Int){
        logEvent("SendCommend")
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
    */
    func setNotification(enabled: Bool){
        logEvent("setNotification = true")
        if peripheral != nil && notificationCharacteristic != nil {
            peripheral.setNotifyValue(enabled, forCharacteristic: notificationCharacteristic)
        }
    }
    
    func showIgnitionOn(){
        updateRPM(8000)
        updateBatt(100)
        updateFuel(100)
        updateTemperature(60)
        sleep(1)
        updateRPM(0)
        updateBatt(0)
        updateFuel(0)
        updateTemperature(-40)
    }
    
    func showIgnitionOff(){
        updateRPM(0)
        updateBatt(0)
        updateFuel(0)
        updateTemperature(-40)
    }
    
    func showTrunkOpened(){
        displayMessage("Trunk Opened")
        UIView.animateWithDuration(200, animations: {
            self.imageViewEngine.image = UIImage(named: "Trunk Opened")
        })
        
        AudioServicesPlayAlertSound(UInt32(kSystemSoundID_Vibrate))
    }
    
    func showTrunkClosed(){
        displayMessage("Trunk closed")
        UIView.animateWithDuration(200, animations: {
            self.imageViewEngine.image = nil
        })
        
        AudioServicesPlayAlertSound(UInt32(kSystemSoundID_Vibrate))
    }
    
    func showStopped(){
        displayMessage("Engine shut off")
//        UIView.animateWithDuration(200, animations: {
//            self.imageViewEngine.image = nil
//        })
        
        updateRPM(0)
        updateBatt(0)
        updateFuel(0)
        updateTemperature(-40)
        AudioServicesPlayAlertSound(UInt32(kSystemSoundID_Vibrate))
    }
    
    func showStarted(){
        displayMessage("Engine started")
//        UIView.animateWithDuration(200, animations: {
//            self.imageViewEngine.image = UIImage(named: "Engine On")
//        })
        updateRPM(2500)
        updateBatt(50)
        updateFuel(50)
        updateTemperature(30)
        AudioServicesPlayAlertSound(UInt32(kSystemSoundID_Vibrate))
    }
    
    
    
    func showUnlocked(){
        UIView.animateWithDuration(200, animations: {
            self.buttonLock.setImage(UIImage(named: "Button Lock Off"), forState: .Normal)
            self.buttonUnlock.setImage(UIImage(named: "Button Unlock On"), forState: .Normal)
//            self.imageViewDoors.image = UIImage(named: "Door Unlocked")
        })
        AudioServicesPlayAlertSound(UInt32(kSystemSoundID_Vibrate))
        displayMessage("Door unlocked")
    }
    
    func showLocked(){
        print("SHOW LOCKED")
        UIView.animateWithDuration(200, animations: {
            self.buttonLock.setImage(UIImage(named: "Button Lock On"), forState: .Normal)
            self.buttonUnlock.setImage(UIImage(named: "Button Unlock Off"), forState: .Normal)
//            self.imageViewDoors.image = UIImage(named: "Door Locked")
        })
        AudioServicesPlayAlertSound(UInt32(kSystemSoundID_Vibrate))
        displayMessage("Door locked")
    }
    
    func showDoorOpened(){
        print("SHOW LOCKED")
        UIView.animateWithDuration(200, animations: {
            self.imageViewDoors.image = UIImage(named: "Door Opened")
        })
        AudioServicesPlayAlertSound(UInt32(kSystemSoundID_Vibrate))
        displayMessage("Door opened")
    }
    
    func showDoorClosed(){
        UIView.animateWithDuration(200, animations: {
            self.imageViewDoors.image = nil
        })
        AudioServicesPlayAlertSound(UInt32(kSystemSoundID_Vibrate))
        displayMessage("Door closed")
    }
    
    func showHoodOpened(){
        UIView.animateWithDuration(200, animations: {
            self.imageViewEngine.image = UIImage(named: "Engine On")
        })
        AudioServicesPlayAlertSound(UInt32(kSystemSoundID_Vibrate))
        displayMessage("Hood opened")
    }
    
    func showHoodClosed(){
        UIView.animateWithDuration(200, animations: {
            self.imageViewEngine.image = nil
        })
        AudioServicesPlayAlertSound(UInt32(kSystemSoundID_Vibrate))
        displayMessage("Hood closed")
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
        isConnected = false
        coverLostConnection.hidden = false
        central.scanForPeripheralsWithServices(nil, options: nil)
        showControl(false)    }
    
    @IBAction func onLongPressStart(sender: UILongPressGestureRecognizer) {
        switch sender.state {
        case UIGestureRecognizerState.Began:
            logEvent("UIGestureRecognizerState.Began")
            isPressing = true
            longPressCountDown = 0
            imageStart.image = UIImage(named: "Button Start")
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
                self.logEvent("now \(self.longPressCountDown)")
                while self.isPressing && self.longPressCountDown <= 5{
                    dispatch_async(dispatch_get_main_queue(),{
                        self.longPressCountDown += 1
                        self.logEvent("set \(self.longPressCountDown)")
                    })
                    usleep(150000)
                }
                if self.longPressCountDown>5{
                    if self.stateEngine {
                        self.stopEngine()
                    }else {
                        self.startEngine()
                    }
                }
            })
            break
        case UIGestureRecognizerState.Ended:
            logEvent("UIGestureRecognizerState.Ended")
            isPressing = false
            imageStart.image = UIImage(named: "Button Start Frame")
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
    
    
    @IBAction func onButtonMore(sender: UIButton) {
        flipControl()
    }
    
    @IBAction func onGPSButton(sender: UIButton) {
        if paneSlidedUp {
            paneSlidedUp = false
            UIView.animateWithDuration(0.5, animations: {
                self.capContainerView.alpha = 1
                self.buttonLock.alpha = 1
                self.buttonUnlock.alpha = 1
                self.slideUpView.alpha = 0
                self.slideUpView.center.y = self.slideUpView.center.y + self.slideUpView.bounds.height
                let transform = CGAffineTransformIdentity
                self.buttonMore.transform = transform
                }, completion: { finished in
                    self.slideUpView.hidden = true
                    self.performSegueWithIdentifier("control2map", sender: sender)
            })
        }else{
            performSegueWithIdentifier("control2map", sender: sender)
        }
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
        navigationController?.navigationBar.setBackgroundImage(UIImage(), forBarMetrics: .Default)
        navigationController?.navigationBar.topItem?.backBarButtonItem?.setTitleTextAttributes([NSFontAttributeName: UIFont(name: fontName, size: 20)!], forState: .Normal)
        navigationController?.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName:UIColor.greenColor()]    //set Title color
        navigationController?.navigationBar.titleTextAttributes = [NSFontAttributeName: UIFont(name: fontName, size: 20)!]
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
    
//    func printFontFamily(){
//        for name in UIFont.familyNames() {
//            print("\(name)\n")
//            if let nameString = name
//                as? String {
//                print(UIFont.fontNamesForFamilyName(nameString))
//            }
//        }
//    }
    
    func getDefaultModuleName() -> String{
        logEvent("Get Default Module Name")
        let defaultModule = NSUserDefaults.standardUserDefaults().objectForKey(tag_default_module)
            as? String
        if defaultModule != nil {
            logEvent("default is not nil : \(defaultModule)")
            return defaultModule!
        }else{
            logEvent("default is nil")
            return checkDatabase()
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
        return 50 + 260 * percentage/100
    }
    
    func getTempAngle(temp: CGFloat) -> CGFloat{
        return 50 + 260 * (temp+40) / 100
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
    
    var currentAngleTemp : CGFloat = 0
    
    func updateTemperature(temp: CGFloat){
        rotateViewToAngle(needleTemp, angle: getTempAngle(temp)/2-currentAngleTemp)
        rotateViewToAngle(needleTemp, angle: getTempAngle(temp))
        currentAngleTemp = getTempAngle(temp)
    }
    
    func animateFlip(){
        UIView.transitionFromView(capContainerView, toView: slideUpView, duration: 1, options: UIViewAnimationOptions.TransitionFlipFromRight, completion: nil)
        
    }
    
    func flipControl(){
        if paneSlidedUp {
            paneSlidedUp = false
            UIView.animateWithDuration(0.5, animations: {
                self.capContainerView.alpha = 1
                self.buttonLock.alpha = 1
                self.buttonUnlock.alpha = 1
                self.slideUpView.alpha = 0
                self.slideUpView.center.y = self.slideUpView.center.y + self.slideUpView.bounds.height
                let transform = CGAffineTransformIdentity
                self.buttonMore.transform = transform
                }, completion: { finished in
                    self.slideUpView.hidden = true
            })
        }else{
            paneSlidedUp = true
            self.slideUpView.alpha = 0
            self.slideUpView.hidden = false
            UIView.animateWithDuration(0.5, delay: 0, options: UIViewAnimationOptions.CurveEaseInOut, animations: {
                self.slideUpView.alpha = 1
                self.slideUpView.center.y = self.slideUpView.center.y - self.slideUpView.bounds.height
                self.slideUpView.hidden = false
                self.capContainerView.alpha = 0
                self.buttonLock.alpha = 0
                self.buttonUnlock.alpha = 0
                var transform = CGAffineTransformIdentity
                transform = CGAffineTransformRotate(transform, CGFloat(M_PI / 2))
                self.buttonMore.transform = transform
                }, completion: { finished in
            })
        }
    }
    
    func setUpStaticViews(){
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
        
        buttonMore.clipsToBounds = true
        setAnchorPoint(CGPoint(x: 0.5, y: 0.0), forView: self.imageStart)
        setAnchorPoint(CGPoint(x: 0.5, y: 0.0), forView: self.imageCap)
    }
    
    func checkDatabase() -> String {
        logEvent("Check database for registered vehicle")
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        let dataController = appDelegate.dataController
        let vehicles : [Vehicle] = dataController.getAllVehicles()
        if vehicles.count > 0 {
            logEvent("Use first vehicle in the database")
            return vehicles[0].module!
        }else {
            logEvent("no vehicle registerd")
            return ""
        }
    }
    
    @IBAction func onAddFromEmpty(sender: UIButton) {
        performSegueWithIdentifier("control2scan", sender: sender)
    }
    
    @IBAction func onGarage(sender: UIButton) {
        if paneSlidedUp {
            paneSlidedUp = false
            UIView.animateWithDuration(0.5, animations: {
                self.capContainerView.alpha = 1
                self.buttonLock.alpha = 1
                self.buttonUnlock.alpha = 1
                self.slideUpView.alpha = 0
                self.slideUpView.center.y = self.slideUpView.center.y + self.slideUpView.bounds.height
                let transform = CGAffineTransformIdentity
                self.buttonMore.transform = transform
                }, completion: { finished in
                    self.slideUpView.hidden = true
                    self.performSegueWithIdentifier("control2garage", sender: sender)
            })
        }else{
            performSegueWithIdentifier("control2garage", sender: sender)
        }
    }
    @IBAction func onTrunk(sender: UIButton) {
        if !stateTrunk {
            print("open trunk")
        }else{
            print("close trunk")
        }
    }
    @IBAction func onValet(sender: UIButton) {
        if !stateValet {
            print("activate valet")
        }else{
            print("disactivate valet")
        }
    }
    
    @IBAction func onGoToGarage(sender: UIButton) {
        performSegueWithIdentifier("control2garage", sender: sender)
    }
    
    @IBAction func onRetry(sender: UIButton) {
        
    }
    
    func displayMessage(line: String){
        UIView.animateWithDuration(0.5, animations: {
            self.labelMessage.alpha = 0
            self.labelMessage.center.y = self.labelMessage.center.y - self.labelMessage.bounds.height
            }, completion: { finished in
                UIView.animateWithDuration(0.1, animations: {
                    self.labelMessage.text = line
                    self.labelMessage.center.y = self.labelMessage.center.y + 1.5 * self.labelMessage.bounds.height
                    }, completion: { fininshed in
                        UIView.animateWithDuration(0.5, animations: {
                            self.labelMessage.alpha = 1
                            self.labelMessage.center.y = self.labelMessage.center.y - 0.5 * self.labelMessage.bounds.height
                            }, completion: { finished in
                                self.labelMessage.layoutIfNeeded()
                        })
                })
        })
    }
    
    func printMessage(line: String){
        labelMessage.text = line
    }
}

