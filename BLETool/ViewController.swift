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
        let result = NSString(bytesNoCopy: p, length: length*2, encoding: NSUTF8StringEncoding, freeWhenDone: true) as! String
        return result
    }
}

extension Int {
    var data: NSData {
        var int = self
        let result = NSData(bytes: &int, length: sizeof(Int))
        return result
    }
    
    var hexString : String! {
        return String(format:"%2x", self)
    }
}

extension UInt64 {
    var hexString : String! {
        return String(format:"%2x", self)
    }
}

extension UInt32 {
    var hexString : String! {
        return String(format:"%2x", self)
    }
}

extension UInt8 {
    var hexString : String! {
        return String(format:"%2x", self)
    }
}

extension String {
    var last4 : String! {
        return self.substringFromIndex(self.endIndex.advancedBy(-4))
    }
    
    var first8 : String! {
        return self.substringToIndex(self.endIndex.advancedBy(-4))
    }
}

class ViewController: UIViewController, CBCentralManagerDelegate, CBPeripheralDelegate {
    let DBG = true
    
    let msgRemoteStarted =  "Remote Started"
    let msgRemoteStopped =  "Remote Stopped"
    let msgDoorOpenned =    "Door Openned"
    let msgDoorClosed =     "Door Closed"
    let msgDoorLocked =     "Door Locked"
    let msgDoorUnlocked =   "Door Unlocked"
    let msgTrunkOpened =    "Trunk Opened"
    let msgTrunkClosed =    "Trunk Closed"
    let msgTrunkReleased =  "Trunk Released"
    let msgHoodOpened =     "Hood Opened"
    let msgHoodClosed =     "Hood Closed"
    let msgValetOn =        "Valet mode: On"
    let msgValetOff =       "Valet mode: Off"
    @IBOutlet var labelCountDown: UILabel!
    @IBOutlet var labelMessage: UILabel!
    
    @IBOutlet var buttonAddFromEmpty: UIButton!
    @IBOutlet var buttonGarage: UIButton!
    @IBOutlet var buttonUnlock: UIButton!
    @IBOutlet var buttonLock: UIButton!
    @IBOutlet var buttonMore: UIButton!
    @IBOutlet var buttonTrunk: UIButton!
    @IBOutlet var buttonValet: UIButton!
    @IBOutlet var buttonCover: UIButton!
    @IBOutlet var buttonGPS: UIButton!
    
    @IBOutlet var topView: UIStackView!
    @IBOutlet var controlPanel: UIView!
    @IBOutlet var coverLostConnection: UIView!
    @IBOutlet var stateView: UIView!
    @IBOutlet var coverEmptyGarage: UIView!
    @IBOutlet var capContainerView: UIView!
    @IBOutlet var rightView: UIView!
    @IBOutlet var leftView: UIView!
    @IBOutlet var slideUpView: UIView!
    @IBOutlet var buttonTemperature: UIButton!
    
    
    @IBOutlet var imageViewTempretureBackground: UIImageView!
    @IBOutlet var imageViewFuelBackground: UIImageView!
    @IBOutlet var imageButtonStart: UIImageView!
    @IBOutlet var imageStartFrame: UIImageView!
    @IBOutlet var imageViewHood: UIImageView!
    @IBOutlet var imageHourGlass: UIImageView!
    @IBOutlet var imageViewDoors: UIImageView!
    @IBOutlet var imageViewTrunk: UIImageView!
    @IBOutlet var imageGlowing: UIImageView!
    @IBOutlet var imageViewCar: UIImageView!
    @IBOutlet var needleFuel: UIImageView!
    @IBOutlet var needleTemp: UIImageView!
    @IBOutlet var needleBatt: UIImageView!
    @IBOutlet var needleRPM: UIImageView!
    @IBOutlet var imageCap: UIImageView!
    
    @IBOutlet var longPressStart: UILongPressGestureRecognizer!
    @IBOutlet var swipeDown: UISwipeGestureRecognizer!
    @IBOutlet var swipeUp: UISwipeGestureRecognizer!
    
    
    var appDelegate : AppDelegate?
    var dataController : DataController?
    var centralManager:CBCentralManager!
    var peripheral : CBPeripheral!
    var service : CBService!
    var writeCharacteristic : CBCharacteristic!
    var stateCharacteristic : CBCharacteristic!
    var temperatureCharacteristic : CBCharacteristic!
    var runtimeCharacteristic : CBCharacteristic!
    
    var checkingValetState = false
    var checkingValetEvent = false
    var checkingTrunkEvent = false
    var startingEngine = false
    var ackCount = 0
    var lastIntValue : UInt64?
    var lastRaw : String?
    var isTimerRunning = false
    var ifNeedVibration = false
    let mask9lock : UInt8 =        0x80
    let mask9doors : UInt8 =       0x40
    let mask9trunk : UInt8 =       0x20
    let mask9hood : UInt8 =        0x10
    let mask9ignition : UInt8 =    0x08
    let mask9engine : UInt8 =      0x04
    let mask9remote : UInt8 =      0x02
    let mask9valet : UInt8 =       0x01
    
    let tag_default_module = "defaultModule"
    let tag_last_scene = "lastScene"
    let fontName = "NeuropolXRg-Regular"
    
    var isPanelDispalyed = false
    var module = ""
    
    var longPressCountDown = 0
    var isPressing = false
    
    var stateLocked = false
    var stateDoorOpened = false
    var stateTrunkOpened = false
    var stateHoodOpened = false
    var stateEngineStarted = false
    var stateIgnition = false
    var stateRemote = false
    var stateValet = false
    
    var stateBattery = 0
    var stateTemperature = 0
    var stateRPM = 0
    var stateFuel = 0
    
    var isFirstACK = true
    var isMatchFound = false
    var isConnected = false
    let defaultCountdown = 90
    var countdown = 90
    var timer : NSTimer?
    var currentAngleTemp : CGFloat = 0
    var waitingList : [UInt8] = []
    var changedStatus : [UInt8] = []
    
    override func viewDidLoad() {
        printLog("ViewController : viewDidLoad")
        super.viewDidLoad()
        appDelegate = UIApplication.sharedApplication().delegate as? AppDelegate
        dataController = appDelegate!.dataController
        initializeUIComponents()
    }
    
    override func viewWillAppear(animated: Bool) {
        printLog("ViewController : viewWillAppear")
        isFirstACK = true
        module = getDefaultModule()
        if module != "" {
            coverEmptyGarage.hidden = true
            centralManager = CBCentralManager(delegate: self, queue:nil)
        }else{
            coverEmptyGarage.hidden = false
            self.title = "Control"
        }
//        resetNotification(10)
    }
    
    override func viewDidAppear(animated: Bool) {
        printLog("viewDidAppear")
        setLastScene()
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        printLog("viewWillDisappear")
        if centralManager != nil && peripheral != nil{
            centralManager.cancelPeripheralConnection(peripheral)
            printLog("cancel connection")
            centralManager = nil
            isConnected = false
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func centralManagerDidUpdateState(central: CBCentralManager) {
        switch(central.state){
        case .PoweredOn:
            printLog("CBCentralManagerState.PoweredOn")
            isMatchFound = false
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
                self.printLog("Finding matched module")
                sleep(1)
                dispatch_async(dispatch_get_main_queue(),{
                    if !self.isMatchFound {
                        self.printLog("No match module found")
                        self.coverLostConnection.hidden = false
                    }else{
                        self.printLog("Match module found")
                    }
                })
            })
            centralManager.scanForPeripheralsWithServices(nil, options: nil)
            printLog("Scan for peripherals with services")
            break
        case .PoweredOff:
            printLog("CBCentralManagerState.PoweredOff")
            centralManager.stopScan()
            break
        case .Unauthorized:
            printLog("CBCentralManagerState.Unauthorized")
            break
        case .Resetting:
            printLog("CBCentralManagerState.Resetting")
            break
        case .Unknown:
            printLog("CBCentralManagerState.Unknown")
            break
        case .Unsupported:
            printLog("CBCentralManagerState.Unsupported")
            break
        }
    }
    
    func centralManager(central: CBCentralManager, didDiscoverPeripheral peripheral: CBPeripheral, advertisementData: [String : AnyObject], RSSI: NSNumber) {
        let nameOfDeviceFound = peripheral.name as String!
        if nameOfDeviceFound != nil {
            printLog("Discovered device : \(nameOfDeviceFound)")
            printLog("Default module is : \(module)")
            if nameOfDeviceFound == module{
                isMatchFound = true
                if centralManager != nil {
                    centralManager.stopScan()
                    printLog("Stop scan")
                    self.peripheral = peripheral
                    self.peripheral.delegate = self
                    centralManager.connectPeripheral(self.peripheral, options: nil)
                    printLog("Connecting : \(self.peripheral.name)")
                }
            }
        }
    }
    
    func centralManager(central: CBCentralManager, didConnectPeripheral peripheral: CBPeripheral) {
        printLog("Did connect peripheral \(peripheral.name)")
        isConnected = true
        self.coverLostConnection.hidden = true
        peripheral.discoverServices([CBUUID(string: "1234")])
        printLog("Discovering service: 1234")
    }
    
    func centralManager(central: CBCentralManager, didFailToConnectPeripheral peripheral: CBPeripheral, error: NSError?) {
        printLog("Failed to connect")
    }
    
    func centralManager(central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: NSError?) {
        printLog("Disconnected")
        isConnected = false
        coverLostConnection.hidden = false
        enableControl(false)
        central.scanForPeripheralsWithServices(nil, options: nil)
        printLog("Scan for peripherals with services, after disconnected")
        
    }
    
    func peripheral(peripheral: CBPeripheral, didDiscoverServices error: NSError?) {
        printLog("Service discoverd")
        for service in peripheral.services! {
            if(service.UUID.UUIDString == "1234"){
                self.service = service
            }
            printLog("Found service: \(service.UUID)")
            peripheral.discoverCharacteristics([CBUUID(string: "1235"),CBUUID(string: "1236")], forService: service)
            printLog("Discovering characteristic: 1235, 1236")
        }
    }
    
    func peripheral(peripheral: CBPeripheral, didDiscoverCharacteristicsForService service: CBService, error: NSError?) {
        
        for characteristic in service.characteristics! {
            printLog("Found characteristic: \(characteristic.UUID.UUIDString)")
            if(characteristic.UUID.UUIDString == "1235"){
                writeCharacteristic = characteristic
                printLog("Set write characteristic")
            }
            if(characteristic.UUID.UUIDString == "1236"){
                stateCharacteristic = characteristic
                printLog("Set state characteristic")
                enableNotification(true)
            }
        }
        printLog("Ble characteristics are ready")
        enableControl(true)
    }
    
    func peripheral(peripheral: CBPeripheral, didUpdateValueForCharacteristic characteristic: CBCharacteristic, error: NSError?) {
        switch characteristic {
        case stateCharacteristic:
            handleRawData(characteristic.value!)
            break
        default:
            break
        }
    }
    
    func getIntFromNSData(data: NSData) -> UInt64 {
        var result : UInt64 = 0
        data.getBytes(&result, length: sizeof(UInt64))
        return result
    }
    
    func getInt16FromHexString(hex: String) -> Int {
        return Int(strtoul(hex, nil, 16))
    }
    
    func getIntFromHexString(hex: String) -> Int {
        return Int(strtoul(hex, nil, 16))
    }
    
    func getInt32FromHexString(hex: String) -> UInt32 {
        return UInt32(strtoul(hex, nil, 16))
    }
    
    func getInt64FromHexString(hex: String) -> Int {
        return Int(strtoul(hex, nil, 64))
    }
    
    func enableControl(val: Bool){
        if !val {
            printLog("Control disabled")
            buttonLock.enabled = false
            buttonUnlock.enabled = false
        }else{
            printLog("Control enabled")
            buttonLock.enabled = true
            buttonUnlock.enabled = true
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
                sleep(1)
                dispatch_async(dispatch_get_main_queue(),{
                    self.requestStatus()
                })
                sleep(1)
                dispatch_async(dispatch_get_main_queue(),{
                    self.findVehicleNameFromPeripheral()
                })
            })
        }
    }
    
    func findVehicleNameFromPeripheral(){
        printLog("Find vehicle name for connected module")
        let vehicleList = dataController?.getAllVehicles()
        for vehicle in vehicleList! {
            if vehicle.module == self.peripheral.name!{
                self.title = "Control / \(vehicle.name!)"
            }
        }
    }
    
    func enableNotification(enabled: Bool){
        printLog("Enable notification : \(enabled)")
        if peripheral != nil && stateCharacteristic != nil {
            peripheral.setNotifyValue(enabled, forCharacteristic: stateCharacteristic)
        }
    }
    
    func showIgnitionOn(){
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
            dispatch_async(dispatch_get_main_queue(),{
                self.updateUIRPM(8000)
                self.updateUIBattery(100)
                self.updateUIFuel(100)
            })
            sleep(1)
            dispatch_async(dispatch_get_main_queue(),{
                self.updateUIRPM(0)
                self.updateUIBattery(0)
                self.updateUIFuel(0)
            })
        })
    }
    
    func showIgnitionOff(){
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
            dispatch_async(dispatch_get_main_queue(),{
                self.updateUIRPM(0)
                self.updateUIBattery(0)
                self.updateUIFuel(0)
            })
        })
    }
    
    func showTrunkReleased(){
        if isPanelDispalyed {
            isPanelDispalyed = false
            UIView.animateWithDuration(0.3, animations: {
                self.capContainerView.alpha = 1
                self.buttonLock.alpha = 1
                self.buttonUnlock.alpha = 1
                self.slideUpView.alpha = 0
                self.slideUpView.center.y = self.slideUpView.center.y + self.slideUpView.bounds.height
                let transform = CGAffineTransformIdentity
                self.buttonMore.transform = transform
                }, completion: { finished in
                    self.buttonTrunk.setImage(UIImage(named: "ButtonTrunkReleased"), forState: .Normal)
                    self.displayMessage(self.msgTrunkReleased)
            })
        }else{
            buttonTrunk.setImage(UIImage(named: "ButtonTrunkReleased"), forState: .Normal)
            displayMessage(msgTrunkReleased)
        }
        AudioServicesPlayAlertSound(UInt32(kSystemSoundID_Vibrate))
        ifNeedVibration = false
    }
    
    func showTrunkOpened(){
        if isPanelDispalyed {
            isPanelDispalyed = false
            UIView.animateWithDuration(0.3, animations: {
                self.capContainerView.alpha = 1
                self.buttonLock.alpha = 1
                self.buttonUnlock.alpha = 1
                self.slideUpView.alpha = 0
                self.slideUpView.center.y = self.slideUpView.center.y + self.slideUpView.bounds.height
                let transform = CGAffineTransformIdentity
                self.buttonMore.transform = transform
                }, completion: { finished in
                    self.imageViewTrunk.image = UIImage(named: "StateTrunkOpened")
                    self.buttonTrunk.setImage(UIImage(named: "ButtonTrunkOn"), forState: .Normal)
                    AudioServicesPlayAlertSound(UInt32(kSystemSoundID_Vibrate))
                    self.ifNeedVibration = false
                    if !self.isFirstACK {
                        self.displayMessage(self.msgTrunkOpened)
                    }
            })
        }else{
            imageViewTrunk.image = UIImage(named: "StateTrunkOpened")
            buttonTrunk.setImage(UIImage(named: "ButtonTrunkOn"), forState: .Normal)
            if ifNeedVibration{
                AudioServicesPlayAlertSound(UInt32(kSystemSoundID_Vibrate))
                ifNeedVibration = false
            }
            if !isFirstACK {
                displayMessage(msgTrunkOpened)
            }
        }
    }
    
    func showTrunkClosed(){
        if isPanelDispalyed {
            isPanelDispalyed = false
            UIView.animateWithDuration(0.3, animations: {
                self.capContainerView.alpha = 1
                self.buttonLock.alpha = 1
                self.buttonUnlock.alpha = 1
                self.slideUpView.alpha = 0
                self.slideUpView.center.y = self.slideUpView.center.y + self.slideUpView.bounds.height
                let transform = CGAffineTransformIdentity
                self.buttonMore.transform = transform
                }, completion: { finished in
                    self.imageViewTrunk.image = nil
                    self.buttonTrunk.setImage(UIImage(named: "ButtonTrunk"), forState: .Normal)
                    if !self.isFirstACK {
                        self.displayMessage(self.msgTrunkClosed)
                    }
                    
            })
        }else{
            imageViewTrunk.image = nil
            buttonTrunk.setImage(UIImage(named: "ButtonTrunk"), forState: .Normal)
            if !isFirstACK {
                displayMessage(msgTrunkClosed)
            }
        }
    }
    
    func showStopped(){
        if isPanelDispalyed {
            isPanelDispalyed = false
            UIView.animateWithDuration(0.3, animations: {
                self.capContainerView.alpha = 1
                self.buttonLock.alpha = 1
                self.buttonUnlock.alpha = 1
                self.slideUpView.alpha = 0
                self.slideUpView.center.y = self.slideUpView.center.y + self.slideUpView.bounds.height
                let transform = CGAffineTransformIdentity
                self.buttonMore.transform = transform
                }, completion: { finished in
                    self.updateUIRPM(0)
                    self.updateUIBattery(0)
                    self.updateUIFuel(0)
            })
        }else{
            updateUIRPM(0)
            updateUIBattery(0)
            updateUIFuel(0)
        }
        if ifNeedVibration {
            AudioServicesPlayAlertSound(UInt32(kSystemSoundID_Vibrate))
            ifNeedVibration = false
        }
        if timer != nil {
            stopTimer()
        }
        
    }
    
    func showStartFailed(){
        if isPanelDispalyed {
            isPanelDispalyed = false
            UIView.animateWithDuration(0.3, animations: {
                self.capContainerView.alpha = 1
                self.buttonLock.alpha = 1
                self.buttonUnlock.alpha = 1
                self.slideUpView.alpha = 0
                self.slideUpView.center.y = self.slideUpView.center.y + self.slideUpView.bounds.height
                let transform = CGAffineTransformIdentity
                self.buttonMore.transform = transform
                }, completion: { finished in
                    self.updateUIRPM(0)
                    self.updateUIBattery(0)
                    self.updateUIFuel(0)
            })
        }else{
            updateUIRPM(0)
            updateUIBattery(0)
            updateUIFuel(0)
        }
        if !isFirstACK {
            displayMessage("Started failed")
        }
        if timer != nil {
            stopTimer()
        }
        AudioServicesPlayAlertSound(UInt32(kSystemSoundID_Vibrate))
        ifNeedVibration = false
        startingEngine = false
    }
    
    func showStarted(){
        if isPanelDispalyed {
            isPanelDispalyed = false
            UIView.animateWithDuration(0.3, animations: {
                self.capContainerView.alpha = 1
                self.buttonLock.alpha = 1
                self.buttonUnlock.alpha = 1
                self.slideUpView.alpha = 0
                self.slideUpView.center.y = self.slideUpView.center.y + self.slideUpView.bounds.height
                let transform = CGAffineTransformIdentity
                self.buttonMore.transform = transform
                }, completion: { finished in
                    self.updateUIRPM(1100)
                    self.updateUIBattery(95)
                    self.updateUIFuel(50)
                    self.onUpdateTemp(self.buttonTemperature)
            })
        }else{
            updateUIRPM(1100)
            updateUIBattery(95)
            updateUIFuel(50)
            onUpdateTemp(self.buttonTemperature)
        }
        if !stateRemote {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
                for _ in 1...3 {
                    dispatch_async(dispatch_get_main_queue(),{
                        AudioServicesPlayAlertSound(UInt32(kSystemSoundID_Vibrate))
                        self.ifNeedVibration = false
                    })
                    usleep(1000 * 500)
                }
            })
        }
        startingEngine = false
    }
    
    func startTimerFrom(value: Int){
        countdown = value
        if timer != nil {
            stopTimer()
        }
        timer = NSTimer.scheduledTimerWithTimeInterval(1, target: self, selector: #selector(ViewController.updateCountDown), userInfo: nil, repeats: true)
        labelCountDown.textColor = UIColor.whiteColor()
        labelCountDown.text = stringValueOfHoursMinutesSeconds(countdown)
        imageHourGlass.hidden = false
        imageHourGlass.image = UIImage(named: "Hourglass-100")
        isTimerRunning = true
    }
    
    func stopTimer(){
        timer?.invalidate()
        labelCountDown.text = ""
        imageHourGlass.hidden = true
        isTimerRunning = false
    }
    
    func reSyncTimer(seconds: Int){
        countdown = seconds
    }
    
    func resetNotification(countdown: Int){
        let application = UIApplication.sharedApplication()
        let scheduledNotifications = application.scheduledLocalNotifications!
        for notification in scheduledNotifications {
            application.cancelLocalNotification(notification)
        }
        let notification = UILocalNotification()
        notification.alertBody = "Engine shutdown : Timeout"
        notification.alertAction = "open"
        notification.fireDate = NSDate(timeIntervalSinceNow: NSTimeInterval(countdown))
        notification.soundName = UILocalNotificationDefaultSoundName
        printLog("add notification")
        application.scheduleLocalNotification(notification)
    }
    
    func secondsToHoursMinutesSeconds (seconds : Int) -> (Int, Int, Int) {
        return (seconds / 3600, (seconds % 3600) / 60, (seconds % 3600) % 60)
    }
    
    func stringValueOfHoursMinutesSeconds (seconds:Int) -> String {
        let (h, m, s) = secondsToHoursMinutesSeconds (seconds)
        var hours = "\(h) : "
        if h == 0 {
            hours = ""
        }
        var minutes = "\(m) : "
        if m < 10 {
            minutes = "0\(m) : "
        }
        var seconds = "\(s)"
        if s < 10 {
            seconds = "0\(s)"
        }
        return (hours+minutes+seconds)
    }
    
    func updateCountDown() {
        if countdown > 0 {
            countdown = countdown - 1
            if !isPanelDispalyed {
                labelCountDown.text =
                    stringValueOfHoursMinutesSeconds(self.countdown)
            }
            if countdown < defaultCountdown * 3 / 10 {
                imageHourGlass.image = UIImage(named: "Hourglass-20")
            }else if countdown < defaultCountdown * 5 / 10{
                imageHourGlass.image = UIImage(named: "Hourglass-40")
            }else if countdown < defaultCountdown * 7 / 10{
                imageHourGlass.image = UIImage(named: "Hourglass-60")
            }else if countdown < defaultCountdown * 9 / 10{
                imageHourGlass.image = UIImage(named: "Hourglass-80")
            }
        }else if countdown == 0 {
            labelCountDown.textColor = UIColor.redColor()
            imageHourGlass.image = UIImage(named: "Hourglass-0")
            updateUIRPM(0)
            updateUIBattery(0)
            updateUIFuel(0)
        }
    }
    
    @IBAction func onUpdateTemp(sender: UIButton) {
        printLog("On update temperatrure")
    }
    
    func showUnlocked(){
        printLog("Show door unlocked")
        if isPanelDispalyed {
            isPanelDispalyed = false
            UIView.animateWithDuration(0.3, animations: {
                self.capContainerView.alpha = 1
                self.buttonLock.alpha = 1
                self.buttonUnlock.alpha = 1
                self.slideUpView.alpha = 0
                self.slideUpView.center.y = self.slideUpView.center.y + self.slideUpView.bounds.height
                let transform = CGAffineTransformIdentity
                self.buttonMore.transform = transform
                }, completion: { finished in
                    self.buttonLock.setImage(UIImage(named: "ButtonLockOff"), forState: .Normal)
                    self.buttonUnlock.setImage(UIImage(named: "ButtonUnlockOn"), forState: .Normal)
            })
        }else{
            buttonLock.setImage(UIImage(named: "ButtonLockOff"), forState: .Normal)
            buttonUnlock.setImage(UIImage(named: "ButtonUnlockOn"), forState: .Normal)
        }
        if ifNeedVibration{
            if !isFirstACK {
                displayMessage(msgDoorUnlocked)
            }
            AudioServicesPlayAlertSound(UInt32(kSystemSoundID_Vibrate))
            ifNeedVibration = false
        }
    }
    
    func showLocked(){
        printLog("Show door locked")
        if isPanelDispalyed {
            isPanelDispalyed = false
            UIView.animateWithDuration(0.3, animations: {
                self.capContainerView.alpha = 1
                self.buttonLock.alpha = 1
                self.buttonUnlock.alpha = 1
                self.slideUpView.alpha = 0
                self.slideUpView.center.y = self.slideUpView.center.y + self.slideUpView.bounds.height
                let transform = CGAffineTransformIdentity
                self.buttonMore.transform = transform
                self.imageViewDoors.image = nil
                }, completion: { finished in
                    self.buttonLock.setImage(UIImage(named: "ButtonLockOn"), forState: .Normal)
                    self.buttonUnlock.setImage(UIImage(named: "ButtonUnlockOff"), forState: .Normal)
            })
        }else{
            buttonLock.setImage(UIImage(named: "ButtonLockOn"), forState: .Normal)
            buttonUnlock.setImage(UIImage(named: "ButtonUnlockOff"), forState: .Normal)
        }
        if ifNeedVibration{
            if !isFirstACK {
                displayMessage(msgDoorLocked)
            }
            AudioServicesPlayAlertSound(UInt32(kSystemSoundID_Vibrate))
            ifNeedVibration = false
        }
    }
    
    func showDoorOpened(){
        printLog("Show door opened")
        if isPanelDispalyed {
            isPanelDispalyed = false
            UIView.animateWithDuration(0.3, animations: {
                self.capContainerView.alpha = 1
                self.buttonLock.alpha = 1
                self.buttonUnlock.alpha = 1
                self.slideUpView.alpha = 0
                self.slideUpView.center.y = self.slideUpView.center.y + self.slideUpView.bounds.height
                let transform = CGAffineTransformIdentity
                self.buttonMore.transform = transform
                }, completion: { finished in
                    self.imageViewDoors.image = UIImage(named: "StateDoorOpened")
            })
        }else{
            imageViewDoors.image = UIImage(named: "StateDoorOpened")
        }
        if ifNeedVibration{
            AudioServicesPlayAlertSound(UInt32(kSystemSoundID_Vibrate))
            ifNeedVibration = false
        }
    }
    
    func showDoorClosed(){
        printLog("Show door closed")
        if isPanelDispalyed {
            isPanelDispalyed = false
            UIView.animateWithDuration(0.3, animations: {
                self.capContainerView.alpha = 1
                self.buttonLock.alpha = 1
                self.buttonUnlock.alpha = 1
                self.slideUpView.alpha = 0
                self.slideUpView.center.y = self.slideUpView.center.y + self.slideUpView.bounds.height
                let transform = CGAffineTransformIdentity
                self.buttonMore.transform = transform
                }, completion: { finished in
                    self.imageViewDoors.image = nil
            })
        }else{
            self.imageViewDoors.image = nil
        }
        if ifNeedVibration{
            AudioServicesPlayAlertSound(UInt32(kSystemSoundID_Vibrate))
            ifNeedVibration = false
        }
    }
    
    func showHoodOpened(){
        printLog("Show hood opened")
        if isPanelDispalyed {
            isPanelDispalyed = false
            UIView.animateWithDuration(0.3, animations: {
                self.capContainerView.alpha = 1
                self.buttonLock.alpha = 1
                self.buttonUnlock.alpha = 1
                self.slideUpView.alpha = 0
                self.slideUpView.center.y = self.slideUpView.center.y + self.slideUpView.bounds.height
                let transform = CGAffineTransformIdentity
                self.buttonMore.transform = transform
                }, completion: { finished in
                    self.imageViewHood.image = UIImage(named: "StateHoodOn")
            })
        }else{
            imageViewHood.image = UIImage(named: "StateHoodOn")
        }
        if ifNeedVibration{
            AudioServicesPlayAlertSound(UInt32(kSystemSoundID_Vibrate))
            ifNeedVibration = false
        }
    }
    
    func showHoodClosed(){
        printLog("Show hood closed")
        if isPanelDispalyed {
            isPanelDispalyed = false
            UIView.animateWithDuration(0.3, animations: {
                self.capContainerView.alpha = 1
                self.buttonLock.alpha = 1
                self.buttonUnlock.alpha = 1
                self.slideUpView.alpha = 0
                self.slideUpView.center.y = self.slideUpView.center.y + self.slideUpView.bounds.height
                let transform = CGAffineTransformIdentity
                self.buttonMore.transform = transform
                }, completion: { finished in
                    self.imageViewHood.image = nil
            })
        }else{
            imageViewHood.image = nil
        }
    }
    
    func showValetOn(){
        if isPanelDispalyed {
            isPanelDispalyed = false
            UIView.animateWithDuration(0.3, animations: {
                self.capContainerView.alpha = 1
                self.buttonLock.alpha = 1
                self.buttonUnlock.alpha = 1
                self.slideUpView.alpha = 0
                self.slideUpView.center.y = self.slideUpView.center.y + self.slideUpView.bounds.height
                let transform = CGAffineTransformIdentity
                self.buttonMore.transform = transform
                }, completion: { finished in
                    self.displayMessage(self.msgValetOn)
            })
        }else{
            displayMessage(msgValetOn)
        }
        if ifNeedVibration{
            AudioServicesPlayAlertSound(UInt32(kSystemSoundID_Vibrate))
            ifNeedVibration = false
        }
    }
    
    func showValetOff(){
        if isPanelDispalyed {
            isPanelDispalyed = false
            UIView.animateWithDuration(0.3, animations: {
                self.capContainerView.alpha = 1
                self.buttonLock.alpha = 1
                self.buttonUnlock.alpha = 1
                self.slideUpView.alpha = 0
                self.slideUpView.center.y = self.slideUpView.center.y + self.slideUpView.bounds.height
                let transform = CGAffineTransformIdentity
                self.buttonMore.transform = transform
                }, completion: { finished in
                    self.displayMessage(self.msgValetOff)
            })
        }else{
            displayMessage(msgValetOff)
        }
        if ifNeedVibration{
            AudioServicesPlayAlertSound(UInt32(kSystemSoundID_Vibrate))
            ifNeedVibration = false
        }
    }
    
    func setAnchorPoint(anchorPoint: CGPoint, forView view: UIView) {
        printLog("Set anchor : \(view.layer.position)")
        var newPoint = CGPointMake(view.bounds.size.width * anchorPoint.x, view.bounds.size.height * anchorPoint.y)
        var oldPoint = CGPointMake(view.bounds.size.width * view.layer.anchorPoint.x, view.bounds.size.height * view.layer.anchorPoint.y)
        
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
    }
    
    @IBAction func onLongPressStart(sender: UILongPressGestureRecognizer) {
        switch sender.state {
        case UIGestureRecognizerState.Began:
            printLog("UIGestureRecognizerState.Began")
            isPressing = true
            longPressCountDown = 0
            var glowtransform = CGAffineTransformIdentity
            UIView.animateWithDuration(0.3, animations: {
                glowtransform = CGAffineTransformScale(glowtransform,1.3, 1)
                self.imageGlowing.alpha = 1.0
                self.imageGlowing.transform = glowtransform
            })
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
                self.printLog("now \(self.longPressCountDown)")
                while self.isPressing && self.longPressCountDown <= 5{
                    dispatch_async(dispatch_get_main_queue(),{
                        self.longPressCountDown += 1
                        self.printLog("set \(self.longPressCountDown)")
                    })
                    usleep(150000)
                }
                
                if self.longPressCountDown>5{
                    self.isPressing = false
                    dispatch_async(dispatch_get_main_queue(),{
                        AudioServicesPlayAlertSound(UInt32(kSystemSoundID_Vibrate))
                        UIView.animateWithDuration(0.1, animations: {
                            self.imageGlowing.alpha = 0.0
                            },completion: {
                                finished in
                                UIView.animateWithDuration(0.1, animations: {
                                    self.imageGlowing.alpha = 1.0
                                    },completion: {
                                        finished in
                                        UIView.animateWithDuration(0.1, animations: {
                                            self.imageGlowing.alpha = 0.0
                                            },completion: {
                                                finished in
                                                UIView.animateWithDuration(0.1, animations: {
                                                    self.imageGlowing.alpha = 1.0
                                                    },completion: {
                                                        finished in
                                                        UIView.animateWithDuration(0.1, animations: {
                                                            self.imageGlowing.alpha = 0.0
                                                        })
                                                })
                                        })
                                })
                        })
                    })
                    if self.stateValet {
                        self.showRemoteStartDisabledFromValet()
                    }else{
                        if self.stateRemote {
                            self.stopEngine()
                        }else {
                            self.startEngine()
                        }
                    }
                }
            })
            break
        case UIGestureRecognizerState.Ended:
            if isPressing {
                UIView.animateWithDuration(0.3, animations: {
                    let glowtransform = CGAffineTransformIdentity
                    self.imageGlowing.transform = glowtransform
                    self.imageGlowing.alpha = 0.0
                })
                
                isPressing = false
            }
            printLog("UIGestureRecognizerState.Ended")
            break
        default:
            break
        }
    }
    
    func removeTopbarShadow() {
        printLog("Remove navigation bar shadow")
        for p in navigationController!.navigationBar.subviews {
            for c in p.subviews {
                if c is UIImageView {
                    c.removeFromSuperview()
                }
            }
        }
    }
    
    func setUpNavigationBar(){
        printLog("Set up navigation bar : background, font, text color")
        navigationController?.navigationBar.setBackgroundImage(UIImage(named: "AppBackground"), forBarMetrics: .Default)
        //        navigationController?.navigationBar.topItem?.backBarButtonItem?.setTitleTextAttributes([NSFontAttributeName: UIFont(name: fontName, size: 20)!], forState: .Normal)
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title:"", style:.Plain, target:nil, action:nil)
        
        navigationController?.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName:UIColor.greenColor()]    //set Title color
        navigationController?.navigationBar.titleTextAttributes = [NSFontAttributeName: UIFont(name: fontName, size: 20)!]
        removeTopbarShadow()
    }
    
    func getColorFromHex(value: UInt) -> UIColor{
        printLog("Get UIColor from hex value")
        return UIColor(
            red: CGFloat((value & 0xFF0000) >> 16) / 255.0,
            green: CGFloat((value & 0x00FF00) >> 8) / 255.0,
            blue: CGFloat(value & 0x0000FF) / 255.0,
            alpha: CGFloat(1.0)
        )
    }
    
    func printFontFamily(){
        printLog("Print font family")
        for name in UIFont.familyNames() {
            printLog("\(name)\n")
            printLog("\(UIFont.fontNamesForFamilyName(name))")
        }
    }
    
    func getDefaultModule() -> String{
        printLog("Get default module")
        let defaultModule = NSUserDefaults.standardUserDefaults().objectForKey(tag_default_module)
            as? String
        if defaultModule != nil {
            printLog("Default module is : \(defaultModule!)")
            return defaultModule!
        }else{
            printLog("Default module is nil")
            return checkDatabase()
        }
    }
    
    
    
    func getLastScene() -> String{
        printLog("Get last scene")
        let lastScene =
            NSUserDefaults.standardUserDefaults().objectForKey(tag_last_scene)
                as? String
        if lastScene != nil {
            printLog("Found last scene: \(lastScene!)")
            return lastScene!
        }else{
            printLog("No last scene found")
            return ""
        }
    }
    
    func setLastScene(){
        printLog("Set last scene : Control")
        NSUserDefaults.standardUserDefaults().setObject("Control", forKey: tag_last_scene)
    }
    
    func rotateNeedle(view:UIView, angle: CGFloat){
        printLog("Rotate UIView angle by :\(angle)")
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
    
    func updateUIBattery(percentage: CGFloat){
        rotateNeedle(needleBatt, angle: getBattAngle(percentage))
    }
    
    func updateUIRPM(rpm : CGFloat){
        rotateNeedle(needleRPM, angle: getRPMAngle(rpm))
    }
    
    func updateUIFuel(percentage : CGFloat){
        rotateNeedle(needleFuel, angle: getFuelAngle(percentage))
    }
    
    func updateUITemperature(temperature: Int){
        printLog("Update temperature: \(temperature)º")
        let temp = CGFloat(temperature)
        printLog("currentAngleTemp=\(currentAngleTemp)")
        rotateNeedle(needleTemp, angle: getTempAngle(temp)/2-currentAngleTemp)
        rotateNeedle(needleTemp, angle: getTempAngle(temp))
        currentAngleTemp = getTempAngle(temp)
    }
    
    func displayPanel(){
        if isPanelDispalyed {
            isPanelDispalyed = false
            UIView.animateWithDuration(0.5, animations: {
                self.capContainerView.alpha = 1
                self.buttonLock.alpha = 1
                self.buttonUnlock.alpha = 1
                self.slideUpView.alpha = 0
                self.slideUpView.center.y = self.slideUpView.center.y + self.slideUpView.bounds.height
                let transform = CGAffineTransformIdentity
                self.buttonMore.transform = transform
                }, completion: { finished in
                    self.slideUpView.hidden = false
            })
        }else{
            isPanelDispalyed = true
            self.slideUpView.alpha = 0
            slideUpView.hidden = false
            buttonValet.hidden = false
            buttonGarage.hidden = false
            buttonTrunk.hidden = false
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
    
    func initializeUIComponents(){
        printLog("Initialize UI components")
        setUpNavigationBar()
        longPressStart.enabled = false
        buttonCover.backgroundColor = UIColor.clearColor()
        buttonCover.clipsToBounds = true
        
        imageCap.backgroundColor = UIColor.clearColor()
        imageCap.layoutIfNeeded()
        imageCap.clipsToBounds = true
        
        imageStartFrame.backgroundColor = UIColor.clearColor()
        imageStartFrame.layoutIfNeeded()
        imageStartFrame.clipsToBounds = true
        
        buttonUnlock.layer.cornerRadius = 25.0
        buttonUnlock.clipsToBounds = true
        
        buttonLock.layer.cornerRadius = 25.0
        buttonLock.clipsToBounds = true
        
        buttonMore.clipsToBounds = true
        setAnchorPoint(CGPoint(x: 0.5, y: 0.0), forView: self.imageStartFrame)
        setAnchorPoint(CGPoint(x: 0.5, y: 0.0), forView: self.imageCap)
        setAnchorPoint(CGPoint(x: 0.5, y: 0.0), forView: self.imageButtonStart)
        setAnchorPoint(CGPoint(x: 0.5, y: 0.0), forView: self.imageGlowing)
        
        needleBatt.transform = CGAffineTransformMakeRotation(CGFloat(M_PI) * getBattAngle(0) / 180)
        needleRPM.transform = CGAffineTransformMakeRotation(CGFloat(M_PI) * getRPMAngle(0) / 180)
        needleFuel.transform = CGAffineTransformMakeRotation(CGFloat(M_PI) * getFuelAngle(0) / 180)
        needleTemp.transform = CGAffineTransformMakeRotation(CGFloat(M_PI) * getTempAngle(-40) / 180)
    }
    
    func checkDatabase() -> String {
        printLog("Check database for registered vehicle")
        
        let vehicles : [Vehicle] = dataController!.getAllVehicles()
        if vehicles.count > 0 {
            printLog("Use first vehicle in the database")
            return vehicles[0].module!
        }else {
            printLog("no vehicle registerd")
            return ""
        }
    }
    
    @IBAction func onAddFromEmpty(sender: UIButton) {
        performSegueWithIdentifier("control2scan", sender: sender)
    }
    
    @IBAction func onGarage(sender: UIButton) {
        if isPanelDispalyed {
            isPanelDispalyed = false
            UIView.animateWithDuration(0.5, animations: {
                self.capContainerView.alpha = 1
                self.buttonLock.alpha = 1
                self.buttonUnlock.alpha = 1
                self.slideUpView.alpha = 0
                self.slideUpView.center.y = self.slideUpView.center.y + self.slideUpView.bounds.height
                let transform = CGAffineTransformIdentity
                self.buttonMore.transform = transform
                }, completion: { finished in
                    self.performSegueWithIdentifier("control2garage", sender: sender)
            })
        }else{
            performSegueWithIdentifier("control2garage", sender: sender)
        }
    }
    
    @IBAction func onButtonMore(sender: UIButton) {
        displayPanel()
    }
    
    
    
    @IBAction func onGPSButton(sender: UIButton) {
        if isPanelDispalyed {
            isPanelDispalyed = false
            UIView.animateWithDuration(0.5, animations: {
                self.capContainerView.alpha = 1
                self.buttonLock.alpha = 1
                self.buttonUnlock.alpha = 1
                self.slideUpView.alpha = 0
                self.slideUpView.center.y = self.slideUpView.center.y + self.slideUpView.bounds.height
                let transform = CGAffineTransformIdentity
                self.buttonMore.transform = transform
                }, completion: { finished in
                    //                    self.slideUpView.hidden = true
                    self.performSegueWithIdentifier("control2map", sender: sender)
            })
        }else{
            performSegueWithIdentifier("control2map", sender: sender)
        }
    }
    
    @IBAction func onGoToGarage(sender: UIButton) {
        performSegueWithIdentifier("control2garage", sender: sender)
    }
    
    @IBAction func onRetry(sender: UIButton) {
        if !isConnected {
            if centralManager != nil {
                centralManager.scanForPeripheralsWithServices(nil, options: nil)
            }
        }
    }
    
    @IBAction func onValet(sender: UIButton) {
        printLog("On valet")
        checkingValetState = true
        printLog("set checkingValetState = true")
        requestStatus()
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
            self.printLog("Wait for state update for valet")
            sleep(2)
            self.ifNeedVibration = true
            if self.stateValet {
                dispatch_async(dispatch_get_main_queue(),{
                    self.showActionSheetValet()
                })
            }else{
                dispatch_async(dispatch_get_main_queue(),{
                    self.checkingValetEvent = true
                    self.printLog("set checkingValetEvent = true")
                    let data = NSData(bytes: [0xA8] as [UInt8], length: 1)
                    self.sendCommand(data, actionId: 0x01, retry: 0)
                    self.printLog("Wait for valet event... from off")
                })
            }
        })
    }
    
    @IBAction func onTrunk(sender: UIButton) {
        printLog("onTrunk 34")
        if !stateTrunkOpened {
            waitingList.removeAll()
            lastRaw = nil
            checkingTrunkEvent = true
            let data = NSData(bytes: [0x34] as [UInt8], length: 1)
            sendCommand(data, actionId: 0x20, retry: 2)
            ifNeedVibration = true
        }
    }
    
    @IBAction func onLock(sender: UIButton) {
        printLog("onlock 30")
        waitingList.removeAll()
        lastRaw = nil
        let data = NSData(bytes: [0x30] as [UInt8], length: 1)
        sendCommand(data, actionId: 0x80, retry: 2)
        ifNeedVibration = true
    }
    
    @IBAction func onUnlock(sender: UIButton) {
        printLog("onUnlock 31")
        waitingList.removeAll()
        lastRaw = nil
        let data = NSData(bytes: [0x31] as [UInt8], length: 1)
        sendCommand(data, actionId: 0x80, retry: 2)
        ifNeedVibration = true
    }
    
    @IBAction func onDown(sender: UISwipeGestureRecognizer) {
        printLog("On swipe down")
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
        printLog("On swipe up")
        UIView.animateWithDuration(1, animations: {
            var transform = CATransform3DIdentity
            transform.m34 = 1.0 / -1000
            transform = CATransform3DTranslate(transform, -self.imageCap.bounds.size.height/4, 0, 0)
            transform = CATransform3DRotate(transform, CGFloat(70.0 * M_PI / 180.0), 1,0,0)
            transform = CATransform3DTranslate(transform, self.imageCap.bounds.size.height/4, 0, 0)
            self.imageCap.layer.transform = transform
        })
        longPressStart.enabled = true
        if stateValet {
            showRemoteStartDisabledFromValet()
        }
    }
    
    
    
    func requestStatus(){
        printLog("Request status")
        let data = NSData(bytes: [0xAA] as [UInt8], length: 1)
        if peripheral != nil && writeCharacteristic != nil {
            sendCommand(data, actionId: 0xAA, retry: 0)
            ifNeedVibration = true
        }
    }
    
    func startEngine() {
        printLog("Start engine")
        let data = NSData(bytes: [0x32] as [UInt8], length: 1)
        sendCommand(data, actionId: 0x02, retry: 2)
        startingEngine = true
    }
    
    func stopEngine() {
        printLog("Stop engine")
        let data = NSData(bytes: [0x33] as [UInt8], length: 1)
        sendCommand(data, actionId: 0x02, retry: 2)
    }
    
    func setNotification(enabled: Bool){
        printLog("Set notification: \(enabled)")
        if peripheral != nil && stateCharacteristic != nil {
            peripheral.setNotifyValue(enabled, forCharacteristic: stateCharacteristic)
        }
    }
    
    func sendCommand(data : NSData, actionId: UInt8, retry: Int){
        if peripheral != nil && writeCharacteristic != nil {
            if !waitingList.contains(actionId){
                waitingList.append(actionId)
            }
            lastIntValue = nil
            if retry == 0 {
                peripheral.writeValue(data, forCharacteristic: self.writeCharacteristic, type: .WithResponse)
                printLog("Send command: 0x\(data.hexString)")
            }else{
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
                    var sendCount = 0
                    while sendCount < retry + 1 {
                        self.peripheral.writeValue(data, forCharacteristic: self.writeCharacteristic, type: .WithResponse)
                        if self.DBG {
                            self.printLog("Send command: \(sendCount): 0x\(data.hexString)")
                        }
                        sleep(3)
                        if !self.waitingList.contains(actionId) {
                            break
                        }
                        sendCount = sendCount + 1
                    }
                    if sendCount == retry + 1 {
                        let index = self.waitingList.indexOf(actionId)
                        self.waitingList.removeAtIndex(index!)
                        self.lastRaw = nil
                        self.printLog("Auto removing \(actionId)")
                        if self.waitingList.contains(actionId){let actionSheet = UIAlertController(title: "Action \(actionId.hexString) timed out", message: nil, preferredStyle: .ActionSheet)
                            actionSheet.addAction(UIAlertAction(title: "OK", style: .Cancel, handler: nil))
                            dispatch_async(dispatch_get_main_queue(),{
                                self.presentViewController(actionSheet, animated: true, completion: nil)
                            })
                        }
                    }
                })
            }
        }
    }
    
    var messageStack : [String] = []
    
    func displayMessage(line: String){
        self.labelMessage.text = line
    }
    
    
    func displayCountDown(show: Bool, string: String){
        if show {
            labelCountDown.hidden = false
            labelCountDown.text = string
        }else{
            labelCountDown.hidden = true
        }
    }
    
    func printLog(string :String){
        if DBG {
            print("\(string)")
        }
    }
    
    func checkValet(intValue : UInt8){
        if intValue & mask9valet == 0 {
            stateValet = false
        }else{
            stateValet = true
        }
    }
    
    func checkRemote(intValue : UInt8){
        if intValue & mask9remote != 0 {
            stateRemote = true
        }else{
            stateRemote = false
        }
    }
    
    func checkIgnition(intValue : UInt8){
        if intValue & mask9ignition != 0 {
            stateIgnition = true
        }else{
            stateIgnition = false
        }
    }
    
    func checkEngine(intValue : UInt8){
        if intValue & mask9engine != 0 {
            stateEngineStarted = true
        }else{
            stateEngineStarted = false
        }
    }
    
    func checkHood(intValue : UInt8){
        if intValue & mask9hood != 0 {
            if !stateHoodOpened || isFirstACK{
                showHoodOpened()
                if !isFirstACK {
                    displayMessage(msgHoodOpened)
                }
            }
            stateHoodOpened = true
        }else{
            if stateHoodOpened || isFirstACK{
                showHoodClosed()
                if !isFirstACK {
                    displayMessage(msgHoodClosed)
                }
            }
            stateHoodOpened = false
        }
    }
    
    func checkTrunk(intValue : UInt8, event: UInt8){
        if checkingTrunkEvent {
            printLog("Trunk event: 0x\(intValue.hexString)")
            if event == 4{
                showTrunkReleased()
                if waitingList.contains(0x20){
                    let index = waitingList.indexOf(0x20)
                    waitingList.removeAtIndex(index!)
                    lastRaw = nil
                }
            }
            checkingTrunkEvent = false
        }else{
            if intValue & mask9trunk != 0 {
                if !stateTrunkOpened || isFirstACK{
                    showTrunkOpened()
                }
                stateTrunkOpened = true
            }else{
                if stateTrunkOpened || isFirstACK{
                    showTrunkClosed()
                }
                stateTrunkOpened = false
            }
        }
    }
    
    func checkDoor(intValue : UInt8){
        if intValue & mask9doors != 0 {
            if !stateDoorOpened || isFirstACK{
                showDoorOpened()
                if !isFirstACK {
                    displayMessage(msgDoorOpenned)
                }
            }
            stateDoorOpened = true
        }else{
            if stateDoorOpened || isFirstACK{
                showDoorClosed()
                if !isFirstACK {
                    displayMessage(msgDoorClosed)
                }
            }
            stateDoorOpened = false
        }
    }
    
    func checkLock(intValue : UInt8){
        if intValue & mask9lock != 0 {
            if !stateLocked || isFirstACK{
                showLocked()
                
            }
            stateLocked = true
        }else{
            if stateLocked || isFirstACK{
                showUnlocked()
                
            }
            stateLocked = false
        }
        if waitingList.contains(0x80){
            let index = waitingList.indexOf(0x80)
            waitingList.removeAtIndex(index!)
            lastRaw = nil
        }
    }
    
    func getValueFromInt(src :Int) -> Int{
        return src >> 16
    }
    
    func handleRawData(data: NSData){
        let rawHex = data.hexString
        
        if lastRaw == nil || rawHex != lastRaw{
            printLog("Raw: [\(rawHex)]")
            handleData(data)
        }
        
        lastRaw = rawHex
    }
    
    func handleData(data :NSData){
        let count = data.length / sizeof(UInt8)
        var array = [UInt8](count: count, repeatedValue: 0)
        data.getBytes(&array, length: count * sizeof(UInt8))
        if array.count == 6 {
            for index in 0...5 {
                print("\(index+1): \(array[index])")
            }
            var result = Dictionary<String,Int!>()
            result["runtime"] = Int(array[0]) + 256 * Int(array[1])
            result["event"] = Int(array[3])
            result["status"] = Int(array[2])
            result["temperature"] = Int(array[4])
            for key in result.keys{
                print("\(key): \(result[key]!.hexString)")
            }
            
            
            //handle temperature
            var temperature = Int(array[4])
            if temperature != 0 {
                if temperature > 120 {
                    temperature = 120
                }else if temperature < 4 {
                    temperature = 4
                }
                updateUITemperature(temperature-44)
            }
            
            
            //handle status and event
            handleStatusAndEvent(array[2], event:array[3])
            
            
            //handle runtime countdown
            let runtimeCountdown = result["runtime"]!
            
            printLog("Handle runtime countdown: \(runtimeCountdown) seconds")
            if runtimeCountdown != 0 && runtimeCountdown != 65535{
                countdown = runtimeCountdown
                if isTimerRunning {
                    resetNotification(countdown)
                    reSyncTimer(countdown)
                }else{
                    if stateEngineStarted && stateRemote{
                        startTimerFrom(countdown)
                    }
                }
            }else{
                let event = Int(array[3])
                if event == 1 || event == 2 || event == 4 {
                    showStopped()
                }
            }
            if waitingList.contains(0xAE){
                let index = waitingList.indexOf(0xAE)
                waitingList.removeAtIndex(index!)
            }
        }else{
            print("Array count : \(array.count)")
        }
    }
    
    func handleStatusAndEvent(status : UInt8, event: UInt8){
        printLog("Handle state ACK")
        checkHood(status)
        
        checkDoor(status)
        checkLock(status)
        
        if checkingValetState {
            printLog("Check valet mode before commmand")
            if checkingValetEvent {
                printLog("Check valet mode after command")
                checkingValetState = false
                
                if waitingList.contains(0x01){
                    let index = waitingList.indexOf(0x01)
                    waitingList.removeAtIndex(index!)
                }
                if status & mask9valet != 0{
                    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
                        dispatch_async(dispatch_get_main_queue(),{
                            self.showValetOn()
                        })
                    })
                    stateValet = true
                }else{
                    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
                        dispatch_async(dispatch_get_main_queue(),{
                            self.showValetOff()
                        })
                    })
                    stateValet = false
                }
                printLog("state valet    : \(stateValet)")
                printLog("state remote   : \(stateRemote)")
                printLog("state ignition : \(stateIgnition)")
                printLog("state engine   : \(stateEngineStarted)")
                printLog("state hood     : \(stateHoodOpened)")
                printLog("state trunk    : \(stateTrunkOpened)")
                printLog("state door     : \(stateDoorOpened)")
                printLog("state lock     : \(stateLocked)")
                return
            }
            checkValet(status)
            if waitingList.contains(0xAA){
                let index = waitingList.indexOf(0xAA)
                waitingList.removeAtIndex(index!)
            }
            return
        }
        
        if startingEngine {
            if event == 7 {
                print("777777777")
                showStartFailed()
            }else if event == 6{
                showStarted()
                if !isFirstACK {
                    displayMessage(msgRemoteStarted)
                }
            }
        }
        
        
        checkValet(status)
        checkTrunk(status, event: event)
        
        
        
        if !stateEngineStarted {
            checkIgnition(status)
            checkRemote(status)
            checkEngine(status)
            //            if !stateEngineStarted  {
            //                showStarted()
            //            }
        }else{
            if stateEngineStarted {
                
                checkIgnition(status)
                checkRemote(status)
                checkEngine(status)
                
                if event == 7 {
                    print("----777777777")
                    showStartFailed()
                }else if !stateEngineStarted{
                    showStopped()
                    displayMessage("Engine Stopped")
                }
            }
        }
        
        if waitingList.contains(0xAA){
            let index = waitingList.indexOf(0xAA)
            waitingList.removeAtIndex(index!)
        }
        
        printLog("state valet    : \(stateValet)")
        printLog("state remote   : \(stateRemote)")
        printLog("state ignition : \(stateIgnition)")
        printLog("state engine   : \(stateEngineStarted)")
        printLog("state hood     : \(stateHoodOpened)")
        printLog("state trunk    : \(stateTrunkOpened)")
        printLog("state door     : \(stateDoorOpened)")
        printLog("state lock     : \(stateLocked)")
        
        if isFirstACK {
            isFirstACK = false
        }
    }
    
    func showActionSheetValet(){
        let actionSheet = UIAlertController(title: "Warning", message: "Are you sure about disabling valet mode?", preferredStyle: .ActionSheet)
        actionSheet.addAction(UIAlertAction(title: "Confirm", style: .Default,handler: {
            action in
            self.checkingValetEvent = true
            self.printLog("set event  = true")
            let data = NSData(bytes: [0xA8] as [UInt8], length: 1)
            self.sendCommand(data, actionId: 0x01, retry: 0)
            self.printLog("Wait for valet event... from on")
        }))
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: nil))
        self.presentViewController(actionSheet, animated: true, completion: nil)
    }
    
    func showRemoteStartDisabledFromValet(){
        let actionSheet = UIAlertController(title: "Remote start is disabled", message: "Turn off valet mode to enable remote start", preferredStyle: .ActionSheet)
        
        actionSheet.addAction(UIAlertAction(title: "OK", style: .Cancel, handler: nil))
        self.presentViewController(actionSheet, animated: true, completion: nil)
    }
}

