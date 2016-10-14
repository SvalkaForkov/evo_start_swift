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
}

class ViewController: UIViewController, CBCentralManagerDelegate, CBPeripheralDelegate {
    let DBG = true
    
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
    
    var checkingValetState = true
    var checkingTrunkEvent = true
    var ackCount = 0
    var lastIntValue : UInt64?
    var isTimerRunning = false
    
    let mask9lock : UInt32 =        0x00008000
    let mask9doors : UInt32 =       0x00004000
    let mask9trunk : UInt32 =       0x00002000
    let mask9hood : UInt32 =        0x00001000
    let mask9ignition : UInt32 =    0x00000800
    let mask9engine : UInt32 =      0x00000400
    let mask9remote : UInt32 =      0x00000200
    let mask9valet : UInt32 =       0x00000100
    let mask9event : UInt32 =       0x0000000f
    let mask4header : UInt64 =      0xffff00000000
    
    let tag_default_module = "defaultModule"
    let tag_last_scene = "lastScene"
    let fontName = "NeuropolXRg-Regular"
    
    var isPanelDispalyed = false
    var module = ""
    
    var longPressCountDown = 0
    var isPressing = false
    
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
    
    var isFirstACK = true
    var isMatchFound = false
    var isConnected = false
    let defaultCountdown = 90
    var countdown = 90
    var timer : NSTimer?
    var currentAngleTemp : CGFloat = 0
    var waitingList : [UInt8] = []
    
    override func viewDidLoad() {
        printLog("ViewController : viewDidLoad")
        super.viewDidLoad()
        appDelegate = UIApplication.sharedApplication().delegate as? AppDelegate
        dataController = appDelegate!.dataController
        setUpNavigationBar()
        setUpStaticViews()
        needleBatt.transform = CGAffineTransformMakeRotation(CGFloat(M_PI) * getBattAngle(0) / 180)
        needleRPM.transform = CGAffineTransformMakeRotation(CGFloat(M_PI) * getRPMAngle(0) / 180)
        needleFuel.transform = CGAffineTransformMakeRotation(CGFloat(M_PI) * getFuelAngle(0) / 180)
        needleTemp.transform = CGAffineTransformMakeRotation(CGFloat(M_PI) * getTempAngle(-40) / 180)
    }
    
    override func viewWillAppear(animated: Bool) {
        printLog("ViewController : viewWillAppear")
//        isFirstACK = true
//        module = getDefaultModuleName()
//        if module != "" {
//            coverEmptyGarage.hidden = true
//            centralManager = CBCentralManager(delegate: self, queue:nil)
//        }else{
//            coverEmptyGarage.hidden = false
//        }
        requestJSON()
    }
    
    override func viewDidAppear(animated: Bool) {
        printLog("viewDidAppear")
//        setLastScene()
//        setupNotification()
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
                self.printLog("starting to find matched module")
                sleep(2)
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
            printLog("scanForPeripheralsWithServices")
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
            printLog("Did discover : \(nameOfDeviceFound)")
            printLog("Default module is : \(module)")
            if nameOfDeviceFound == module{
                printLog("Match and stop scan")
                isMatchFound = true
                if centralManager != nil {
                    centralManager.stopScan()
                    self.peripheral = peripheral
                    self.peripheral.delegate = self
                    centralManager.connectPeripheral(self.peripheral, options: nil)
                }
                printLog("Connecting : \(self.peripheral.name)")
            }
        }
    }
    
    func centralManager(central: CBCentralManager, didConnectPeripheral peripheral: CBPeripheral) {
        printLog("didConnectPeripheral")
        isConnected = true
        self.coverLostConnection.hidden = true
        setDefaultModule(peripheral.name!)
        peripheral.discoverServices([CBUUID(string: "1234")])
        printLog("DiscoverService: 1234")
    }
    
    func centralManager(central: CBCentralManager, didFailToConnectPeripheral peripheral: CBPeripheral, error: NSError?) {
        printLog("failed to connect")
    }
    
    func centralManager(central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: NSError?) {
        printLog("Disconnected")
        isConnected = false
        coverLostConnection.hidden = false
        central.scanForPeripheralsWithServices(nil, options: nil)
        enableControl(false)
    }
    
    func peripheral(peripheral: CBPeripheral, didDiscoverServices error: NSError?) {
        printLog("Service discoverd")
        for service in peripheral.services! {
            if(service.UUID.UUIDString == "1234"){
                self.service = service
            }
            printLog("Found service: \(service.UUID)")
            peripheral.discoverCharacteristics([CBUUID(string: "1235"),CBUUID(string: "1236")], forService: service)
        }
    }
    
    func peripheral(peripheral: CBPeripheral, didDiscoverCharacteristicsForService service: CBService, error: NSError?) {
        
        for characteristic in service.characteristics! {
            printLog("Discovered characteristic \(characteristic.UUID.UUIDString)")
            if(characteristic.UUID.UUIDString == "1235"){
                self.writeCharacteristic = characteristic
                printLog("set writeCharacteristic")
            }
            if(characteristic.UUID.UUIDString == "1236"){
                stateCharacteristic = characteristic
                printLog("set stateCharacteristic")
                enableNotification(true)
            }
            printLog("Found characteristic: \(characteristic.UUID)")
        }
        printLog("Connection ready")
        enableControl(true)
    }
    
    func peripheral(peripheral: CBPeripheral, didUpdateValueForCharacteristic characteristic: CBCharacteristic, error: NSError?) {
        switch characteristic {
        case stateCharacteristic:
            handleRawAcknowledge(characteristic.value!)
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
            printLog("set disable")
            buttonLock.enabled = false
            buttonUnlock.enabled = false
        }else{
            printLog("set enable")
            buttonLock.enabled = true
            buttonUnlock.enabled = true
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
                sleep(1)
                self.requestStatus()
                sleep(1)
                self.onUpdateTemp(self.buttonTemperature)
                dispatch_async(dispatch_get_main_queue(),{
//                    self.requestStatus()
//                    self.onUpdateTemp(self.buttonTemperature)
                })
            })
        }
    }
    
    func enableNotification(enabled: Bool){
        printLog("enableNotification : \(enabled)")
        if peripheral != nil && stateCharacteristic != nil {
            peripheral.setNotifyValue(enabled, forCharacteristic: stateCharacteristic)
        }
    }
    
    func showIgnitionOn(){
        updateRPM(8000)
        updateBatt(100)
        updateFuel(100)
        sleep(1)
        updateRPM(0)
        updateBatt(0)
        updateFuel(0)
    }
    
    func showIgnitionOff(){
        updateRPM(0)
        updateBatt(0)
        updateFuel(0)
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
                    self.buttonTrunk.setImage(UIImage(named: "Button Trunk On"), forState: .Normal)
                    AudioServicesPlayAlertSound(UInt32(kSystemSoundID_Vibrate))
                    if !self.isFirstACK {
                        self.displayMessage("Trunk Released")
                    }
                    
            })
        }else{
            buttonTrunk.setImage(UIImage(named: "Button Trunk On"), forState: .Normal)
            AudioServicesPlayAlertSound(UInt32(kSystemSoundID_Vibrate))
            if !isFirstACK {
                displayMessage("Trunk Released")
            }
            
        }
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
                    self.imageViewTrunk.image = UIImage(named: "Trunk Opened")
                    self.buttonTrunk.setImage(UIImage(named: "Button Trunk On"), forState: .Normal)
                    AudioServicesPlayAlertSound(UInt32(kSystemSoundID_Vibrate))
                    if !self.isFirstACK {
                        self.displayMessage("Trunk opened")
                    }
            })
        }else{
            imageViewTrunk.image = UIImage(named: "Trunk Opened")
            buttonTrunk.setImage(UIImage(named: "Button Trunk On"), forState: .Normal)
            AudioServicesPlayAlertSound(UInt32(kSystemSoundID_Vibrate))
            if !isFirstACK {
                displayMessage("Trunk opened")
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
                    self.buttonTrunk.setImage(UIImage(named: "Button Trunk"), forState: .Normal)
                    if !self.isFirstACK {
                        self.displayMessage("Trunk closed")
                    }
                    
            })
        }else{
            imageViewTrunk.image = nil
            buttonTrunk.setImage(UIImage(named: "Button Trunk"), forState: .Normal)
            if !isFirstACK {
                displayMessage("Trunk closed")
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
                    self.updateRPM(0)
                    self.updateBatt(0)
                    self.updateFuel(0)
            })
        }else{
            updateRPM(0)
            updateBatt(0)
            updateFuel(0)
        }
        AudioServicesPlayAlertSound(UInt32(kSystemSoundID_Vibrate))
        stopTimer()
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
                    self.updateRPM(1100)
                    self.updateBatt(95)
                    self.updateFuel(50)
                    self.onUpdateTemp(self.buttonTemperature)
            })
        }else{
            updateRPM(1100)
            updateBatt(95)
            updateFuel(50)
            onUpdateTemp(self.buttonTemperature)
        }
        if !stateEngine {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
                AudioServicesPlayAlertSound(UInt32(kSystemSoundID_Vibrate))
                usleep(1000 * 500)
                AudioServicesPlayAlertSound(UInt32(kSystemSoundID_Vibrate))
                usleep(1000 * 500)
                AudioServicesPlayAlertSound(UInt32(kSystemSoundID_Vibrate))
            })
        }
        requestRuntime()
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
            updateRPM(0)
            updateBatt(0)
            updateFuel(0)
        }
    }
    
    @IBAction func onUpdateTemp(sender: UIButton) {
        printLog("onUpdateTemp")
        let data = NSData(bytes: [0x73] as [UInt8], length: 1)
        sendCommand(data, actionId: 0x73, retry: 2)
    }
    
    func requestRuntime(){
        printLog("requestRuntime")
        let data = NSData(bytes: [0xAE] as [UInt8], length: 1)
        sendCommand(data, actionId: 0xAE, retry: 2)
    }
    func showUnlocked(){
        printLog("show locked")
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
                    self.buttonLock.setImage(UIImage(named: "Button Lock Off"), forState: .Normal)
                    self.buttonUnlock.setImage(UIImage(named: "Button Unlock On"), forState: .Normal)
                    AudioServicesPlayAlertSound(UInt32(kSystemSoundID_Vibrate))
                    self.displayMessage("Door unlocked")
                    self.stateLock = false
            })
        }else{
            self.buttonLock.setImage(UIImage(named: "Button Lock Off"), forState: .Normal)
            self.buttonUnlock.setImage(UIImage(named: "Button Unlock On"), forState: .Normal)
            AudioServicesPlayAlertSound(UInt32(kSystemSoundID_Vibrate))
            self.displayMessage("Door unlocked")
            stateLock = false
        }
    }
    
    func showLocked(){
        printLog("show locked")
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
                    self.showDoorClosed()
                    self.buttonLock.setImage(UIImage(named: "Button Lock On"), forState: .Normal)
                    self.buttonUnlock.setImage(UIImage(named: "Button Unlock Off"), forState: .Normal)
                    AudioServicesPlayAlertSound(UInt32(kSystemSoundID_Vibrate))
                    self.stateLock = true
            })
        }else{
            buttonLock.setImage(UIImage(named: "Button Lock On"), forState: .Normal)
            buttonUnlock.setImage(UIImage(named: "Button Unlock Off"), forState: .Normal)
            AudioServicesPlayAlertSound(UInt32(kSystemSoundID_Vibrate))
            stateLock = true
        }
    }
    
    func showDoorOpened(){
        printLog("show door opened")
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
                    self.imageViewDoors.image = UIImage(named: "Door Opened")
                    AudioServicesPlayAlertSound(UInt32(kSystemSoundID_Vibrate))
                    self.showUnlocked()
                    self.stateLock = false
            })
        }else{
            imageViewDoors.image = UIImage(named: "Door Opened")
            AudioServicesPlayAlertSound(UInt32(kSystemSoundID_Vibrate))
            self.showUnlocked()
            stateLock = false
        }
    }
    
    func showDoorClosed(){
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
                    AudioServicesPlayAlertSound(UInt32(kSystemSoundID_Vibrate))
            })
        }else{
            self.imageViewDoors.image = nil
            AudioServicesPlayAlertSound(UInt32(kSystemSoundID_Vibrate))
        }
    }
    
    func showHoodOpened(){
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
                    self.imageViewHood.image = UIImage(named: "Hood On")
                    AudioServicesPlayAlertSound(UInt32(kSystemSoundID_Vibrate))
            })
        }else{
            imageViewHood.image = UIImage(named: "Hood On")
            AudioServicesPlayAlertSound(UInt32(kSystemSoundID_Vibrate))        }
    }
    
    func showHoodClosed(){
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
                    self.displayMessage("Valet activated")
            })
        }else{
            displayMessage("Valet activated")
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
                    self.displayMessage("Valet disactivated")
            })
        }else{
            displayMessage("Valet disactivated")
        }
    }
    
    func setAnchorPoint(anchorPoint: CGPoint, forView view: UIView) {
        printLog("Set anchor")
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
        printLog("postion final \(view.layer.position)")
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
                dispatch_async(dispatch_get_main_queue(),{
                    AudioServicesPlayAlertSound(UInt32(kSystemSoundID_Vibrate))
                })
                if self.longPressCountDown>5{
                    self.isPressing = false
                    dispatch_async(dispatch_get_main_queue(),{
                        
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
                        if self.stateEngine {
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
        for p in navigationController!.navigationBar.subviews {
            for c in p.subviews {
                if c is UIImageView {
                    c.removeFromSuperview()
                }
            }
        }
    }
    
    func setUpNavigationBar(){
        printLog("SetUpNavigationBar")
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
    
    func printFontFamily(){
        for name in UIFont.familyNames() {
            printLog("\(name)\n")
            printLog("\(UIFont.fontNamesForFamilyName(name))")
        }
    }
    
    func getDefaultModuleName() -> String{
        printLog("Get Default Module Name")
        let defaultModule = NSUserDefaults.standardUserDefaults().objectForKey(tag_default_module)
            as? String
        if defaultModule != nil {
            printLog("default is not nil : \(defaultModule!)")
            return defaultModule!
        }else{
            printLog("default is nil")
            return checkDatabase()
        }
    }
    
    func setDefaultModule(value: String){
        printLog("Set default : \(value)")
        NSUserDefaults.standardUserDefaults().setObject(value, forKey: tag_default_module)
    }
    
    func getLastScene() -> String{
        printLog("Get Last Scene")
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
        printLog("Set Last Scene : Control")
        NSUserDefaults.standardUserDefaults().setObject("Control", forKey: tag_last_scene)
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
    
    func updateTemperature(tempa: Int){
        let temp = CGFloat(tempa)
        printLog("temp=\(tempa)")
        printLog("currentAngleTemp=\(currentAngleTemp)")
        rotateViewToAngle(needleTemp, angle: getTempAngle(temp)/2-currentAngleTemp)
        rotateViewToAngle(needleTemp, angle: getTempAngle(temp))
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
    
    func setUpStaticViews(){
        printLog("setupViews")
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
        
    }
    
    @IBAction func onValet(sender: UIButton) {
        printLog("onValet A8")
        checkingValetState = true
        requestStatus()
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
            self.printLog("Wait for state update for valet")
            sleep(1)
            dispatch_async(dispatch_get_main_queue(),{
                self.checkingValetState = false
                if self.stateValet {
                    self.showActionSheetValet()
                }else{
                    let data = NSData(bytes: [0xA8] as [UInt8], length: 1)
                    self.sendCommand(data, actionId: 0x01, retry: 0)
                }
            })
        })
    }
    
    @IBAction func onTrunk(sender: UIButton) {
        printLog("onTrunk 34")
        if !stateTrunk {
            checkingTrunkEvent = true
            let data = NSData(bytes: [0x34] as [UInt8], length: 1)
            sendCommand(data, actionId: 0x20, retry: 2)
        }
    }
    
    @IBAction func onLock(sender: UIButton) {
        printLog("onlock 30")
        let data = NSData(bytes: [0x30] as [UInt8], length: 1)
        sendCommand(data, actionId: 0x80, retry: 2)
    }
    
    @IBAction func onUnlock(sender: UIButton) {
        printLog("onUnlock 31")
        let data = NSData(bytes: [0x31] as [UInt8], length: 1)
        sendCommand(data, actionId: 0x80, retry: 2)
    }
    
    @IBAction func onDown(sender: UISwipeGestureRecognizer) {
        printLog("swipe down")
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
        printLog("swipe up")
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
        printLog("requestStatus")
        let data = NSData(bytes: [0xAA] as [UInt8], length: 1)
        if peripheral != nil && writeCharacteristic != nil {
            sendCommand(data, actionId: 0xAA, retry: 2)
        }
    }
    
    func startEngine() {
        printLog("startEngine")
        let data = NSData(bytes: [0x32] as [UInt8], length: 1)
        sendCommand(data, actionId: 0x04, retry: 2)
    }
    
    func stopEngine() {
        printLog("stopEngine")
        let data = NSData(bytes: [0x33] as [UInt8], length: 1)
        sendCommand(data, actionId: 0x04, retry: 2)
    }
    
    func setNotification(enabled: Bool){
        printLog("setNotification = true")
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
                printLog("Send 1 time :\(data.hexString)")
            }else{
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
                    var sendCount = 1
                    while sendCount <= retry + 1 {
                        self.peripheral.writeValue(data, forCharacteristic: self.writeCharacteristic, type: .WithResponse)
                        if self.DBG {
                            self.printLog("Send \(sendCount) time :\(data.hexString)")
                        }
                        sleep(1)
                        if !self.waitingList.contains(actionId) {
                            break
                        }
                        sendCount += 1
                    }
                    if sendCount == 3 {
                        if self.waitingList.contains(actionId){
                            let index = self.waitingList.indexOf(actionId)
                            self.waitingList.removeAtIndex(index!)
                        }
                    }
                })
            }
        }
    }
    
    var messageStack : [String] = []
    
    func displayMessage(line: String){
        //        if self.messageStack.count != 0 {
        //            messageStack.append(line)
        //        }else{
        //            messageStack.append(line)
        //            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
        //                while self.messageStack.count != 0 {
        //                    dispatch_async(dispatch_get_main_queue(),{
        //                        self.showUpdate(self.messageStack[0])
        //                        self.messageStack.removeAtIndex(0)
        //                    })
        //                    usleep(50000)
        //                }
        //            })
        //        }
        self.labelMessage.text = line
    }
    
    func showUpdate(line: String){
        UIView.animateWithDuration(0.2, animations: {
            self.labelMessage.alpha = 0
            self.labelMessage.center.y = self.labelMessage.center.y - self.labelMessage.bounds.height
            }, completion: { finished in
                UIView.animateWithDuration(0.1, animations: {
                    self.labelMessage.text = line
                    self.labelMessage.center.y = self.labelMessage.center.y + 1.5 * self.labelMessage.bounds.height
                    }, completion: { fininshed in
                        UIView.animateWithDuration(0.2, animations: {
                            self.labelMessage.alpha = 1
                            self.labelMessage.center.y = self.labelMessage.center.y - 0.5 * self.labelMessage.bounds.height
                            }, completion: { finished in
                                self.labelMessage.layoutIfNeeded()
                        })
                })
        })
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
    
    func setupNotification(){
        let notification = UILocalNotification()
        notification.alertBody = "Engine start : timeout"
        notification.alertAction = "open"
        notification.fireDate = NSDate(timeIntervalSinceNow: 5)
        notification.soundName = UILocalNotificationDefaultSoundName
        notification.userInfo = ["UUID": "testuuid"]
        printLog("add notification")
        UIApplication.sharedApplication().scheduleLocalNotification(notification)
    }
    
    func checkValet(intValue : UInt32){
        printLog("Valet :\(intValue.hexString)")
        if checkingValetState {
            if intValue & mask9valet == 0 {
                if stateValet {
                    showValetOff()
                }
                if waitingList.contains(0x01){
                    let index = waitingList.indexOf(0x01)
                    waitingList.removeAtIndex(index!)
                }
                stateValet = false
            }else{
                if !stateValet {
                    showValetOn()
                }
                if waitingList.contains(0x01){
                    let index = waitingList.indexOf(0x01)
                    waitingList.removeAtIndex(index!)
                }
                stateValet = true
            }
        }else{
            printLog("valet intValue:\(intValue.hexString)")
            let value = intValue & mask9event
            if value == 2 {
                showValetOff()
                if waitingList.contains(0x01){
                    let index = waitingList.indexOf(0x01)
                    waitingList.removeAtIndex(index!)
                }
                stateValet = false
            }else if value == 1{
                showValetOn()
                if waitingList.contains(0x01){
                    let index = waitingList.indexOf(0x01)
                    waitingList.removeAtIndex(index!)
                }
                stateValet = true
            }
            checkingValetState = true
        }
        
    }
    
    func checkRemote(intValue : UInt32){
        if intValue & mask9remote != 0 {
            if !stateRemote {
            }
            stateRemote = true
            printLog("remote on")
        }else{
            if stateRemote {
            }
            stateRemote = false
            printLog("remote off")
        }
    }
    
    func checkIgnition(intValue : UInt32){
        if intValue & mask9ignition != 0 {
            if waitingList.contains(0x08){
                let index = waitingList.indexOf(0x08)
                waitingList.removeAtIndex(index!)
                showIgnitionOn()
                printLog("ignition on")
            }
            stateIgnition = true
        }else{
            if stateIgnition {
            }
            if waitingList.contains(0x08){
                let index = waitingList.indexOf(0x08)
                waitingList.removeAtIndex(index!)
            }
            stateIgnition = false
        }
    }
    
    func checkEngine(intValue : UInt32){
        if intValue & mask9engine != 0 {
            if !stateEngine || isFirstACK{
                showStarted()
                if !isFirstACK {
                    displayMessage("Engine started")
                }
            }
            if waitingList.contains(0x04){
                let index = waitingList.indexOf(0x04)
                waitingList.removeAtIndex(index!)
            }
            stateEngine = true
        }else{
            if stateEngine || isFirstACK{
                showStopped()
                if !isFirstACK {
                    displayMessage("Engine stopped")
                }
            }
            if waitingList.contains(0x04){
                let index = waitingList.indexOf(0x04)
                waitingList.removeAtIndex(index!)
            }
            stateEngine = false
        }
    }
    
    func checkHood(intValue : UInt32){
        if intValue & mask9hood != 0 {
            if !stateHood || isFirstACK{
                showHoodOpened()
                if !isFirstACK {
                    displayMessage("Hood opened")
                }
            }
            if waitingList.contains(0x10){
                let index = waitingList.indexOf(0x10)
                waitingList.removeAtIndex(index!)
            }
            stateHood = true
        }else{
            if stateHood || isFirstACK{
                showHoodClosed()
                if !isFirstACK {
                    displayMessage("Hood closed")
                }
            }
            if waitingList.contains(0x10){
                let index = waitingList.indexOf(0x10)
                waitingList.removeAtIndex(index!)
            }
            stateHood = false
        }
    }
    
    func checkTrunk(intValue : UInt32){
        printLog("Trunk : \(intValue.hexString)")
        if checkingTrunkEvent {
            let value = intValue & mask9event
            print("trunk event: \(value)")
            if value == 4{
                showTrunkReleased()
                if waitingList.contains(0x20){
                    let index = waitingList.indexOf(0x20)
                    waitingList.removeAtIndex(index!)
                }
            }
            checkingTrunkEvent = false
        }else{
            if intValue & mask9trunk != 0 {
                if !stateTrunk || isFirstACK{
                    showTrunkOpened()
                }
                stateTrunk = true
            }else{
                if stateTrunk || isFirstACK{
                    showTrunkClosed()
                }
                stateTrunk = false
            }
        }
    }
    
    func checkDoor(intValue : UInt32){
        if intValue & mask9doors != 0 {
            if !stateDoor || isFirstACK{
                showDoorOpened()
                if !isFirstACK {
                    displayMessage("Door opened")
                }
            }
            if waitingList.contains(0x40){
                let index = waitingList.indexOf(0x40)
                waitingList.removeAtIndex(index!)
            }
            stateDoor = true
        }else{
            if stateDoor || isFirstACK{
                showDoorClosed()
                if !isFirstACK {
                    displayMessage("Door closed")
                }
            }
            if waitingList.contains(0x40){
                let index = waitingList.indexOf(0x40)
                waitingList.removeAtIndex(index!)
            }
            stateDoor = false
        }
    }
    
    func checkLock(intValue : UInt32){
        if intValue & mask9lock != 0 {
            if waitingList.contains(0x80){
                let index = waitingList.indexOf(0x80)
                waitingList.removeAtIndex(index!)
            }
            if !stateLock || isFirstACK{
                showLocked()
                if !isFirstACK {
                    displayMessage("Door locked")
                }
            }
        }else{
            if waitingList.contains(0x80){
                let index = waitingList.indexOf(0x80)
                waitingList.removeAtIndex(index!)
            }
            if stateLock || isFirstACK{
                showUnlocked()
                if !isFirstACK {
                    displayMessage("Door unlocked")
                }
            }
        }
    }
    
    func handleStateAcknowledge(intValue : UInt32){
        printLog("handle State Acknowledge")
        if waitingList.isEmpty {
            printLog("Notified")
            checkValet(intValue)
            checkRemote(intValue)
            checkIgnition(intValue)
            checkHood(intValue)
            checkTrunk(intValue)
            checkDoor(intValue)
            checkLock(intValue)
            checkEngine(intValue)
        }else{
            if waitingList.contains(0xAA) {
                printLog("AA")
                checkValet(intValue)
                checkRemote(intValue)
                checkIgnition(intValue)
                checkHood(intValue)
                checkTrunk(intValue)
                checkDoor(intValue)
                checkLock(intValue)
                checkEngine(intValue)
                let index = waitingList.indexOf(0xAA)
                waitingList.removeAtIndex(index!)
            }
            if waitingList.contains(0x01) {
                checkValet(intValue)
            }
            if waitingList.contains(0x02) {
                checkRemote(intValue)
            }
            if waitingList.contains(0x04) {
                checkEngine(intValue)
            }
            if waitingList.contains(0x08) {
                checkIgnition(intValue)
            }
            if waitingList.contains(0x10) {
                checkHood(intValue)
            }
            if waitingList.contains(0x20) {
                checkTrunk(intValue)
            }
            if waitingList.contains(0x40) {
                checkDoor(intValue)
            }
            if waitingList.contains(0x80) {
                checkLock(intValue)
            }
        }
        if isFirstACK {
            isFirstACK = false
        }
    }
    
    func getValueFromInt(src :Int) -> Int{
        return src >> 16
    }
    
    func getTypeFromInt(src :Int) -> Int{
        return src & 0x00000000ffff
    }
    
    
    
    func handleRawAcknowledge(data: NSData){
        printLog("Raw hex: \(data.hexString)")
        let intValue = getIntFromNSData(data)
        for ey in waitingList {
            printLog(ey.hexString)
        }
        if lastIntValue == nil{
            handleIntValue(intValue, data: data)
        }else if intValue != lastIntValue! {
            handleIntValue(intValue, data: data)
        }
        lastIntValue = intValue
    }
    
    func handleIntValue(intValue: UInt64, data: NSData){
        let type = intValue >> 32
        switch type {
        case 0x1236:// state
            let hex = data.hexString
            let int32str = hex.substringWithRange(hex.startIndex..<hex.endIndex.advancedBy(-4))
            let int32value = getInt32FromHexString(int32str)
            handleStateAcknowledge(int32value)
            break
        case 0x123C:// temp
            printLog("handle temperature")
            let int32fromCroppedHex = getInt32FromHexString(intValue.hexString)
            var temperature = int32fromCroppedHex
            if temperature > 120 {
                temperature = 120
            }else if temperature < 4 {
                temperature = 4
            }
            updateTemperature(Int(temperature)-44)
            if waitingList.contains(0x73){
                let index = waitingList.indexOf(0x73)
                waitingList.removeAtIndex(index!)
            }
            break
        case 0x1237:// runtime
            let runtimeCountdown = getInt32FromHexString(intValue.hexString)
            printLog("handle runtime: \(runtimeCountdown) seconds")
            if runtimeCountdown != 0 {
                countdown = Int(runtimeCountdown)
                if isTimerRunning {
                    resetNotification(countdown)
                    reSyncTimer(countdown)
                }else{
                    startTimerFrom(countdown)
                }
            }else{
                showStopped()
            }
            if waitingList.contains(0xAE){
                let index = waitingList.indexOf(0xAE)
                waitingList.removeAtIndex(index!)
            }
            break
        default:
            break
        }
    }
    
    func showActionSheetValet(){
        let actionSheet = UIAlertController(title: "Warning", message: "Are you sure about disabling valet mode?", preferredStyle: .ActionSheet)
        actionSheet.addAction(UIAlertAction(title: "Confirm", style: .Default,handler: {
            action in
            let data = NSData(bytes: [0xA8] as [UInt8], length: 1)
            self.sendCommand(data, actionId: 0x01, retry: 0)
        }))
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: nil))
        self.presentViewController(actionSheet, animated: true, completion: nil)
    }
    
    func showRemoteStartDisabledFromValet(){
        let actionSheet = UIAlertController(title: "Remote start is disabled", message: "Turn off valet mode to enable remote start", preferredStyle: .ActionSheet)
        
        actionSheet.addAction(UIAlertAction(title: "OK", style: .Cancel, handler: nil))
        self.presentViewController(actionSheet, animated: true, completion: nil)
    }
    
    
    
    func requestJSON(){
        requestMake()
        
    }
    
    func requestModel(make: String, id: Int){
        print("request model")
        var makeAndModels : Array<Array<String>> = []
        let requestURL: NSURL = NSURL(string: "http://fortin.ca/js/models.json?makeid=\(id)")!
        let urlRequest: NSMutableURLRequest = NSMutableURLRequest(URL: requestURL)
        let session = NSURLSession.sharedSession()
        let task = session.dataTaskWithRequest(urlRequest) {
            (data, response, error) -> Void in
            
            let httpResponse = response as! NSHTTPURLResponse
            let statusCode = httpResponse.statusCode
            
            if (statusCode == 200) {
                print("fetch model successfully.")
                do{
                    let json = try NSJSONSerialization.JSONObjectWithData(data!, options:.AllowFragments)
                    if let models : [[String: AnyObject]] = json["models"] as? [[String: AnyObject]] {    //[[String: AnyObject]]
                        for model in models {
                            if let name = model["name"] as? String {
                                makeAndModels.append([name, make])
                            }
                        }
                    }
                    print("\(makeAndModels)")
                    
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
            
            let httpResponse = response as! NSHTTPURLResponse
            let statusCode = httpResponse.statusCode
            
            if (statusCode == 200) {
                print("fetch makes successfully.")
                do{
                    let json = try NSJSONSerialization.JSONObjectWithData(data!, options:.AllowFragments)
                    if let makes : [[String: AnyObject]] = json["makes"] as? [[String: AnyObject]] {    //[[String: AnyObject]]
                        for make in makes {
                            if let name = make["name"] as? String {
                                if let id = make["makeid"] as? Int {
                                    let makename : String = name
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
                }
            }
        }
        
        task.resume()
    }
}

