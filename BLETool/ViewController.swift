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
        print("hexString from NSData: \(result)")
        return result
    }
}

extension Int {
    var data: NSData {
        var int = self
        let result = NSData(bytes: &int, length: sizeof(Int))
        print("Int value from NSData: \(result)")
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
class ViewController: UIViewController, CBCentralManagerDelegate, CBPeripheralDelegate {
    let DBG = true
    
    var centralManager:CBCentralManager!
    var peripheral : CBPeripheral!
    var service : CBService!
    var writeCharacteristic : CBCharacteristic!
    var stateCharacteristic : CBCharacteristic!
    var temperatureCharacteristic : CBCharacteristic!
    var runtimeCharacteristic : CBCharacteristic!
    
    let mask9lock : UInt32 = 0x00008000
    let mask9doors : UInt32 = 0x00004000
    let mask9trunk : UInt32 = 0x00002000
    let mask9hood : UInt32 = 0x00001000
    let mask9ignition : UInt32 = 0x00000800
    let mask9engine : UInt32 = 0x00000400
    let mask9remote : UInt32 = 0x00000200
    let mask9valet : UInt32 = 0x00000100
    let mask4header : UInt64 = 0xFFFF00000000
    
    let tag_default_module = "defaultModule"
    let tag_last_scene = "lastScene"
    let fontName = "NeuropolXRg-Regular"
    
    var isPanelDispalyed = false
    var module = ""
    
    var longPressCountDown = 0
    var isPressing = false
    
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
    let defaultCountdown = 90
    var countdown = 90
    var timer : NSTimer?
    var currentAngleTemp : CGFloat = 0
    var waitingList : [UInt8] = []
    
    override func viewDidLoad() {
        printLog("ViewController : viewDidLoad")
        super.viewDidLoad()
        setUpNavigationBar()
        setUpStaticViews()
        needleBatt.transform = CGAffineTransformMakeRotation(CGFloat(M_PI) * getBattAngle(0) / 180)
        needleRPM.transform = CGAffineTransformMakeRotation(CGFloat(M_PI) * getRPMAngle(0) / 180)
        needleFuel.transform = CGAffineTransformMakeRotation(CGFloat(M_PI) * getFuelAngle(0) / 180)
        needleTemp.transform = CGAffineTransformMakeRotation(CGFloat(M_PI) * getTempAngle(-40) / 180)
    }
    
    override func viewWillAppear(animated: Bool) {
        printLog("ViewController : viewWillAppear")
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
        printLog("viewDidAppear")
        setLastScene()
        setupNotification()
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
        case CBCentralManagerState.PoweredOn:
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
        case CBCentralManagerState.PoweredOff:
            printLog("CBCentralManagerState.PoweredOff")
            centralManager.stopScan()
            break
        case CBCentralManagerState.Unauthorized:
            printLog("CBCentralManagerState.Unauthorized")
            break
        case CBCentralManagerState.Resetting:
            printLog("CBCentralManagerState.Resetting")
            break
        case CBCentralManagerState.Unknown:
            printLog("CBCentralManagerState.Unknown")
            break
        case CBCentralManagerState.Unsupported:
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
                centralManager.stopScan()
                self.peripheral = peripheral
                self.peripheral.delegate = self
                centralManager.connectPeripheral(self.peripheral, options: nil)
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
            peripheral.discoverCharacteristics([CBUUID(string: "1235"),CBUUID(string: "1236"),CBUUID(string: "1237"),CBUUID(string: "123C")], forService: service)
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
            }
            if(characteristic.UUID.UUIDString == "1237"){
                runtimeCharacteristic = characteristic
                printLog("set runtimeCharacteristic")
            }
            if(characteristic.UUID.UUIDString == "123C"){
                temperatureCharacteristic = characteristic
                printLog("set temperatureCharacteristic")
            }
            enableNotification(true)
            printLog("Found characteristic: \(characteristic.UUID)")
        }
        printLog("Connection ready")
        enableControl(true)
    }
    
    func peripheral(peripheral: CBPeripheral, didUpdateValueForCharacteristic characteristic: CBCharacteristic, error: NSError?) {
        switch characteristic {
        case stateCharacteristic:
            let hexstring = characteristic.value!.hexString
        
//            printLog("stateCharacteristic \(characteristic.value!.hexString)")
//            handleStateACK(intValue)
            handle64value(characteristic.value!)
            printLog(characteristic.value!.hexString)
            break
        case runtimeCharacteristic:
            printLog("runtimeCharacteristic \(characteristic.value!.hexString)")
            break
        case temperatureCharacteristic:
            printLog("temperatureCharacteristic \(characteristic.value!.hexString)")
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
    
    func getInt32FromHexString(hex: String) -> Int {
        return Int(strtoul(hex, nil, 32))
    }
    
    func getInt64FromHexString(hex: String) -> Int {
        return Int(strtoul(hex, nil, 64))
    }
    func enableControl(val: Bool){
        if(!val){
            printLog("set disable")
            buttonLock.enabled = false
            buttonUnlock.enabled = false
        }else{
            printLog("set enable")
            buttonLock.enabled = true
            buttonUnlock.enabled = true
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
                    self.showUpdate("Trunk Opened")
            })
        }else{
            imageViewTrunk.image = UIImage(named: "Trunk Opened")
            buttonTrunk.setImage(UIImage(named: "Button Trunk On"), forState: .Normal)
            AudioServicesPlayAlertSound(UInt32(kSystemSoundID_Vibrate))
            showUpdate("Trunk Opened")
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
                    AudioServicesPlayAlertSound(UInt32(kSystemSoundID_Vibrate))
                    self.showUpdate("Trunk closed")
            })
        }else{
            imageViewTrunk.image = nil
            buttonTrunk.setImage(UIImage(named: "Button Trunk"), forState: .Normal)
            AudioServicesPlayAlertSound(UInt32(kSystemSoundID_Vibrate))
            showUpdate("Trunk closed")
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
                    self.showUpdate("Engine shut off")
                    self.updateRPM(0)
                    self.updateBatt(0)
                    self.updateFuel(0)
                    self.updateTemperature(-40)
            })
        }else{
            showUpdate("Engine shut off")
            updateRPM(0)
            updateBatt(0)
            updateFuel(0)
            updateTemperature(-40)
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
                    self.showUpdate("Engine started")
                    self.updateRPM(1100)
                    self.updateBatt(95)
                    self.updateFuel(50)
                    self.updateTemperature(0)
            })
        }else{
            showUpdate("Engine started")
            updateRPM(1100)
            updateBatt(95)
            updateFuel(50)
            updateTemperature(0)
        }
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
            AudioServicesPlayAlertSound(UInt32(kSystemSoundID_Vibrate))
            usleep(1000 * 500)
            AudioServicesPlayAlertSound(UInt32(kSystemSoundID_Vibrate))
            usleep(1000 * 500)
            AudioServicesPlayAlertSound(UInt32(kSystemSoundID_Vibrate))
        })
        
        startTimerFrom(defaultCountdown)
    }
    
    func startTimerFrom(value: Int){
        countdown = value
        timer = NSTimer.scheduledTimerWithTimeInterval(1, target: self, selector: #selector(ViewController.updateCountDown), userInfo: nil, repeats: true)
        labelCountDown.textColor = UIColor.whiteColor()
        labelCountDown.text = stringValueOfHoursMinutesSeconds(countdown)
        imageHourGlass.hidden = false
        imageHourGlass.image = UIImage(named: "Hourglass-100")
    }
    
    func stopTimer(){
        timer?.invalidate()
        labelCountDown.text = ""
        imageHourGlass.hidden = true
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
        notification.alertBody = "new Engine start : timeout"
        notification.alertAction = "new open"
        notification.fireDate = NSDate(timeIntervalSinceNow: NSTimeInterval(countdown))
        notification.soundName = UILocalNotificationDefaultSoundName
        print("add notification")
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
        }
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
                    self.showUpdate("Door unlocked")
            })
        }else{
            self.buttonLock.setImage(UIImage(named: "Button Lock Off"), forState: .Normal)
            self.buttonUnlock.setImage(UIImage(named: "Button Unlock On"), forState: .Normal)
            AudioServicesPlayAlertSound(UInt32(kSystemSoundID_Vibrate))
            self.showUpdate("Door unlocked")
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
                    self.buttonLock.setImage(UIImage(named: "Button Lock On"), forState: .Normal)
                    self.buttonUnlock.setImage(UIImage(named: "Button Unlock Off"), forState: .Normal)
                    AudioServicesPlayAlertSound(UInt32(kSystemSoundID_Vibrate))
                    self.showUpdate("Door opened")
            })
        }else{
            self.buttonLock.setImage(UIImage(named: "Button Lock On"), forState: .Normal)
            self.buttonUnlock.setImage(UIImage(named: "Button Unlock Off"), forState: .Normal)
            AudioServicesPlayAlertSound(UInt32(kSystemSoundID_Vibrate))
            self.showUpdate("Door opened")
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
                    self.showUpdate("Door opened")
            })
        }else{
            imageViewDoors.image = UIImage(named: "Door Opened")
            AudioServicesPlayAlertSound(UInt32(kSystemSoundID_Vibrate))
            showUpdate("Door opened")
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
                    self.showUpdate("Door closed")
            })
        }else{
            self.imageViewDoors.image = nil
            AudioServicesPlayAlertSound(UInt32(kSystemSoundID_Vibrate))
            showUpdate("Door closed")
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
                    self.imageViewHood.image = UIImage(named: "Engine On")
                    AudioServicesPlayAlertSound(UInt32(kSystemSoundID_Vibrate))
                    self.showUpdate("Engine On")
            })
        }else{
            imageViewHood.image = UIImage(named: "Engine On")
            AudioServicesPlayAlertSound(UInt32(kSystemSoundID_Vibrate))
            showUpdate("Hood opened")
        }
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
                    AudioServicesPlayAlertSound(UInt32(kSystemSoundID_Vibrate))
                    self.showUpdate("Engine Off")
            })
        }else{
            imageViewHood.image = nil
            AudioServicesPlayAlertSound(UInt32(kSystemSoundID_Vibrate))
            showUpdate("Hood closed")
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
                    AudioServicesPlayAlertSound(UInt32(kSystemSoundID_Vibrate))
                    self.showUpdate("Valet activated")
            })
        }else{
            AudioServicesPlayAlertSound(UInt32(kSystemSoundID_Vibrate))
            showUpdate("Valet activated")
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
                    AudioServicesPlayAlertSound(UInt32(kSystemSoundID_Vibrate))
                    self.showUpdate("Valet disactivated")
            })
        }else{
            AudioServicesPlayAlertSound(UInt32(kSystemSoundID_Vibrate))
            showUpdate("Valet disactivated")
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
                    if self.stateEngine {
                        self.stopEngine()
                    }else {
                        self.startEngine()
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
    
    func updateTemperature(temp: CGFloat){
        printLog("\(currentAngleTemp)")
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
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        let dataController = appDelegate.dataController
        let vehicles : [Vehicle] = dataController.getAllVehicles()
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
        //        printLog("startEngine")
        //        let data = NSData(bytes: [0xAE] as [UInt8], length: 1)
        //        sendCommand(data, actionId: 0x21)
        //        resetNotification()
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
//        printLog("startEngine")
//        let data = NSData(bytes: [0x73] as [UInt8], length: 1)
//        sendCommand(data, actionId: 0x21)
    }
    
    @IBAction func onRetry(sender: UIButton) {
        
    }
    
    @IBAction func onValet(sender: UIButton) {
        printLog("onValet A8")
        let data = NSData(bytes: [0xA8] as [UInt8], length: 1)
        sendCommand(data, actionId: 0x01)
    }
    
    @IBAction func onTrunk(sender: UIButton) {
        printLog("onTrunk 34")
        let data = NSData(bytes: [0x34] as [UInt8], length: 1)
        sendCommand(data, actionId: 0x21)
    }
    
    @IBAction func onLock(sender: UIButton) {
        printLog("onlock 30")
        let data = NSData(bytes: [0x30] as [UInt8], length: 1)
        sendCommand(data, actionId: 0x71)
        
    }
    
    @IBAction func onUnlock(sender: UIButton) {
        printLog("onUnlock 31")
        let data = NSData(bytes: [0x31] as [UInt8], length: 1)
        sendCommand(data, actionId: 0x70)
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
    }
    
    func requestTemperature(){
        printLog("requestTemperature")
        let data = NSData(bytes: [0xAE] as [UInt8], length: 1)
        sendCommand(data, actionId: 0xAE)
    }
    
    func requestRuntime(){
        printLog("requestRuntime")
        let data = NSData(bytes: [0x73] as [UInt8], length: 1)
        sendCommand(data, actionId: 0x73)
    }
    
    func requestStatus(){
        printLog("requestStatus")
        let data = NSData(bytes: [0xAA] as [UInt8], length: 1)
        sendCommand(data, actionId: 0xAA)
    }
    
    func startEngine() {
        printLog("startEngine")
        let data = NSData(bytes: [0x32] as [UInt8], length: 1)
        sendCommand(data, actionId: 0x21)
    }
    
    func stopEngine() {
        printLog("stopEngine")
        let data = NSData(bytes: [0x33] as [UInt8], length: 1)
        sendCommand(data, actionId: 0x20)
    }
    //    func sendCommand(data : NSData, actionId: UInt8){
    //        if peripheral != nil && writeCharacteristic != nil {
    //            if !waitingList.contains(actionId){
    //                waitingList.append(actionId)
    //            }
    //            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
    //                self.peripheral.writeValue(data, forCharacteristic: self.writeCharacteristic, type: .WithResponse)
    //                if self.DBG {
    //                    print("1st time")
    //                }
    //                sleep(1)
    //                if !self.waitingList.contains(actionId) {
    //                    return
    //                }
    //
    //                self.peripheral.writeValue(data, forCharacteristic: self.writeCharacteristic, type: .WithResponse)
    //                if self.DBG {
    //                    print("2nd time")
    //                }
    //                sleep(1)
    //                if !self.waitingList.contains(actionId) {
    //                    return
    //                }
    //
    //                self.peripheral.writeValue(data, forCharacteristic: self.writeCharacteristic, type: .WithResponse)
    //                if self.DBG {
    //                    print("3rd time")
    //                }
    //                sleep(1)
    //                if !self.waitingList.contains(actionId) {
    //                    return
    //                }
    //
    //                self.peripheral.writeValue(data, forCharacteristic: self.writeCharacteristic, type: .WithResponse)
    //                if self.DBG {
    //                    print("4th time")
    //                }
    //                sleep(1)
    //                if !self.waitingList.contains(actionId) {
    //                    return
    //                }
    //
    //                self.peripheral.writeValue(data, forCharacteristic: self.writeCharacteristic, type: .WithResponse)
    //                if self.DBG {
    //                    print("5th time")
    //                }
    //            })
    //        }
    //    }
    
    func setNotification(enabled: Bool){
        print("setNotification = true")
        if peripheral != nil && stateCharacteristic != nil {
            peripheral.setNotifyValue(enabled, forCharacteristic: stateCharacteristic)
        }
    }
    
    func sendCommand(data : NSData, actionId: UInt8){
        if peripheral != nil && writeCharacteristic != nil {
            if !waitingList.contains(actionId){
                waitingList.append(actionId)
            }
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
                var sendCount = 1
                while sendCount <= 5 {
                    self.peripheral.writeValue(data, forCharacteristic: self.writeCharacteristic, type: .WithResponse)
                    if self.DBG {
                        self.printLog("Send \(sendCount) time")
                    }
                    sleep(1)
                    if !self.waitingList.contains(actionId) {
                        break
                    }
                    sendCount += 1
                }
            })
        }
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
        print("add notification")
        UIApplication.sharedApplication().scheduleLocalNotification(notification)
    }
    
    func handleStateACK(intValue : UInt32){
        printLog("handleStateACK")
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
                printLog("ignition on")
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
                showValetOn()
            }
            if waitingList.contains(0x01){
                let index = waitingList.indexOf(0x01)
                waitingList.removeAtIndex(index!)
            }
            stateValet = true
        }else{
            if stateValet {
                showValetOff()
            }
            if waitingList.contains(0x00){
                let index = waitingList.indexOf(0x00)
                waitingList.removeAtIndex(index!)
            }
            stateValet = false
        }
    }

    func getValueFromInt(src :Int) -> Int{
        return src >> 16
    }
    
    func getTypeFromInt(src :Int) -> Int{
        return src & 0x00000000ffff
    }
    
    func handle64value(data: NSData){
        let hex = data.hexString
        let intvalue = getIntFromNSData(data)
        print("hex----\(hex)")
        print("Int----\(intvalue)")
        print("Inthex----\(intvalue.hexString)")
        print("type----\((intvalue >> 32).hexString)")
        print("value----\((intvalue & 0x00000000ffff).hexString)")
//        switch header {
//        case 0x1236:// state
//            let intValue = UInt32(data & 0x0000ffffffff)
//            handleStateACK(intValue)
//            break
//        case 0x123C:// temp
//            let temp = UInt32(data & 0x0000ffffffff)
//            print("\(temp)")
//            break
//        case 0x1237:// runtime
//            let runtime = UInt32(data & 0x0000ffffffff)
//            print("\(runtime)")
//            countdown = Int(runtime)
//            resetNotification(countdown)
//            break
//        case 0x0004:
//            break
//        default:
//            break
//        }
    }
    
}

