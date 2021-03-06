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
    let VDBG = true
    
    var flagDemo = false
    
    let msgRemoteStarted =  "Remote Started"
    let msgRemoteStopped =  "Remote Stopped"
    let msgRemoteFailed =   "Start Failed"
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
    
    @IBOutlet var labelColon: UILabel!
    
    @IBOutlet var labelSeconds: UILabel!
    @IBOutlet var labelMinutes: UILabel!
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
    @IBOutlet var buttonDemoOnEmpty: UIButton!
    @IBOutlet var buttonDemoOnLostConnection: UIButton!
    @IBOutlet var buttonGoToGarage: UIButton!
    @IBOutlet var buttonReconnect: UIButton!
    
    
    var appDelegate : AppDelegate?
    var dataController : DataController?
    var centralManager:CBCentralManager!
    var peripheral : CBPeripheral!
    var service : CBService!
    var writeCharacteristic : CBCharacteristic!
    var stateCharacteristic : CBCharacteristic!
    var temperatureCharacteristic : CBCharacteristic!
    var runtimeCharacteristic : CBCharacteristic!
    
    var checkingLock = false
    var checkingValetState = false
    var checkingValetEvent = false
    var checkingTrunkEvent = false
    var checkingStart = false
    var checkingStop = false
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
    let tag_selected_module = "selectedModule"
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
    var originalCountdown = 90
    var countdown = 90
    var timer : NSTimer?
    var currentAngleTemp : CGFloat = 0
    var waitingList : [UInt8] = []
    var changedStatus : [UInt8] = []
    
    override func viewDidLoad() {
        printVDBG("ViewController : viewDidLoad")
        super.viewDidLoad()
        
        appDelegate = UIApplication.sharedApplication().delegate as? AppDelegate
        dataController = appDelegate!.dataController
        
        setDemoFlag(false)
        
        initializeUIComponents()
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(ViewController.willEnterForeground(_:)), name: UIApplicationWillEnterForegroundNotification, object: nil)
    }
    
    func willEnterForeground(notification: NSNotification!) {
        printDBG("Do whatever you want when the app is brought back to the foreground")
        if !flagDemo {
            sendRequestStatus()
        }
    }
    
    deinit {
        printVDBG("Remove Observer")
        NSNotificationCenter.defaultCenter().removeObserver(self, name: nil, object: nil)
    }
    
    override func viewWillAppear(animated: Bool) {
        printVDBG("ViewController : viewWillAppear")
        if !flagDemo {
            isFirstACK = true
            let selectedModule = getSelectedModule()
            if selectedModule != "" {
                module = selectedModule
            }else{
                module = getDefaultModule()
            }
            NSUserDefaults.standardUserDefaults().setObject("", forKey: tag_selected_module)
            if module != "" {
                coverEmptyGarage.hidden = true
                centralManager = CBCentralManager(delegate: self, queue:nil)
                printVDBG("Initialize CBCentralManager")
            }else{
                coverEmptyGarage.hidden = false
                self.title = "Control"
            }
            
        }else{
            coverLostConnection.hidden = true
            coverEmptyGarage.hidden = true
        }
    }
    
    override func viewDidAppear(animated: Bool) {
        printVDBG("viewDidAppear")
        setLastScene()
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        printVDBG("viewWillDisappear")
        if !flagDemo {
            if centralManager != nil && peripheral != nil{
                centralManager.cancelPeripheralConnection(peripheral)
                printVDBG("Cancel BLE connection")
                centralManager = nil
                isConnected = false
            }
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func centralManagerDidUpdateState(central: CBCentralManager) {
        switch(central.state){
        case .PoweredOn:
            printVDBG("CBCentralManagerState.PoweredOn")
            isMatchFound = false
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
                self.printDBG("Finding matched module")
                sleep(1)
                dispatch_async(dispatch_get_main_queue(),{
                    if !self.isMatchFound {
                        self.printDBG("No match module found")
                        self.coverLostConnection.hidden = false
                    }else{
                        self.printDBG("Match module found")
                    }
                })
            })
            centralManager.scanForPeripheralsWithServices(nil, options: nil)
            printVDBG("Scan for peripherals with services")
            break
        case .PoweredOff:
            printVDBG("CBCentralManagerState.PoweredOff")
            centralManager.stopScan()
            break
        case .Unauthorized:
            printVDBG("CBCentralManagerState.Unauthorized")
            break
        case .Resetting:
            printVDBG("CBCentralManagerState.Resetting")
            break
        case .Unknown:
            printVDBG("CBCentralManagerState.Unknown")
            break
        case .Unsupported:
            printVDBG("CBCentralManagerState.Unsupported")
            break
        }
    }
    
    func centralManager(central: CBCentralManager, didDiscoverPeripheral peripheral: CBPeripheral, advertisementData: [String : AnyObject], RSSI: NSNumber) {
        let nameOfDeviceFound = peripheral.name as String!
        if nameOfDeviceFound != nil {
            printVDBG("Discovered device : \(nameOfDeviceFound)")
            printVDBG("Default module is : \(module)")
            if nameOfDeviceFound == module{
                isMatchFound = true
                if centralManager != nil {
                    centralManager.stopScan()
                    printDBG("Found module and stop scan")
                    self.peripheral = peripheral
                    self.peripheral.delegate = self
                    centralManager.connectPeripheral(self.peripheral, options: nil)
                    printDBG("Connecting : \(self.peripheral.name)")
                }
            }
        }
    }
    
    func centralManager(central: CBCentralManager, didConnectPeripheral peripheral: CBPeripheral) {
        printVDBG("Did connect peripheral \(peripheral.name)")
        isConnected = true
        setDemoFlag(false)
        self.coverLostConnection.hidden = true
        peripheral.discoverServices([CBUUID(string: "1234")])
        printVDBG("Discovering service: 1234")
        
        enableControl(true)
    }
    
    func centralManager(central: CBCentralManager, didFailToConnectPeripheral peripheral: CBPeripheral, error: NSError?) {
        printVDBG("Failed to connect")
    }
    
    func centralManager(central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: NSError?) {
        printVDBG("Disconnected")
        isConnected = false
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
            sleep(3)
            if !self.isConnected{
                dispatch_async(dispatch_get_main_queue(),{
                    self.coverLostConnection.hidden = false
                    self.enableControl(false)
                })
            }
        })
        
        central.scanForPeripheralsWithServices(nil, options: nil)
        printDBG("Scan for peripherals with services, after disconnected")
        
    }
    
    func peripheral(peripheral: CBPeripheral, didDiscoverServices error: NSError?) {
        printVDBG("Service discoverd")
        for service in peripheral.services! {
            if(service.UUID.UUIDString == "1234"){
                self.service = service
            }
            printVDBG("Found service: \(service.UUID)")
            peripheral.discoverCharacteristics([CBUUID(string: "1235"),CBUUID(string: "1236")], forService: service)
            printVDBG("Discovering characteristic: 1235, 1236")
        }
    }
    
    func peripheral(peripheral: CBPeripheral, didDiscoverCharacteristicsForService service: CBService, error: NSError?) {
        
        for characteristic in service.characteristics! {
            printVDBG("Found characteristic: \(characteristic.UUID.UUIDString)")
            if(characteristic.UUID.UUIDString == "1235"){
                writeCharacteristic = characteristic
                printVDBG("Set write characteristic")
            }
            if(characteristic.UUID.UUIDString == "1236"){
                stateCharacteristic = characteristic
                printVDBG("Set state characteristic")
                enableNotification(true)
            }
        }
        printDBG("Ble characteristics are ready")
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
    
    func enableControl(val: Bool){
        if !val {
            printVDBG("Control disabled")
            buttonLock.enabled = false
            buttonUnlock.enabled = false
        }else{
            printVDBG("Control enabled")
            buttonLock.enabled = true
            buttonUnlock.enabled = true
            checkingLock = false
            checkingStart = false
            checkingStop = false
            checkingValetState = false
            checkingValetEvent = false
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
                sleep(1)
                dispatch_async(dispatch_get_main_queue(),{
                    self.sendRequestStatus()
                })
                sleep(1)
                dispatch_async(dispatch_get_main_queue(),{
                    self.findVehicleNameFromPeripheral()
                })
            })
        }
    }
    
    func findVehicleNameFromPeripheral(){
        printVDBG("Find vehicle name for connected module")
        let vehicleList = dataController?.getAllVehicles()
        for vehicle in vehicleList! {
            if vehicle.module == self.module{
                self.title = "Control / \(vehicle.name!)"
            }
        }
    }
    
    func enableNotification(enabled: Bool){
        printVDBG("Enable notification : \(enabled)")
        if peripheral != nil && stateCharacteristic != nil {
            peripheral.setNotifyValue(enabled, forCharacteristic: stateCharacteristic)
        }
    }
    
    func startTimerFrom(value: Int){
        countdown = value
        originalCountdown = value
        stopTimer()
        timer = NSTimer.scheduledTimerWithTimeInterval(1, target: self, selector: #selector(ViewController.updateCountDown), userInfo: nil, repeats: true)
        labelMinutes.textColor = UIColor.whiteColor()
        labelSeconds.textColor = UIColor.whiteColor()
        labelColon.textColor = UIColor.whiteColor()
        let (m,s) = secondsToMinutesSeconds(countdown)
        displayCountDown(m,second: s)
        imageHourGlass.hidden = false
        imageHourGlass.image = UIImage(named: "Hourglass-100")
        isTimerRunning = true
    }
    
    func stopTimer(){
        if timer != nil {
            timer?.invalidate()
            displayCountDown("",second: "")
            imageHourGlass.hidden = true
            isTimerRunning = false
        }
    }
    
    func reSyncTimer(seconds: Int){
        countdown = seconds
    }
    
    func resetNotification(countdown: Int){
        printDBG("Reset notification")
        let application = UIApplication.sharedApplication()
        let scheduledNotifications = application.scheduledLocalNotifications!
        for notification in scheduledNotifications {
            application.cancelLocalNotification(notification)
        }
        let notification = UILocalNotification()
        notification.alertBody = "Engine shutdown"
        notification.alertAction = "Shutdown"
        notification.fireDate = NSDate(timeIntervalSinceNow: NSTimeInterval(countdown))
        notification.soundName = UILocalNotificationDefaultSoundName
        if countdown > 180 {
            let notification3min = UILocalNotification()
            notification3min.alertBody = "Engine will shutdown in 3 minutes"
            notification3min.alertAction = "3min"
            notification3min.fireDate = NSDate(timeIntervalSinceNow: NSTimeInterval(countdown-180))
            notification3min.soundName = UILocalNotificationDefaultSoundName
            application.scheduleLocalNotification(notification3min)
        }
        application.scheduleLocalNotification(notification)
    }
    
    func secondsToMinutesSeconds (seconds : Int) -> (String, String) {
        let minute = seconds % 3600 / 60
        let second = seconds % 3600 % 60
        var m = "\(minute)"
        if minute < 10 {
            m = "0\(minute)"
        }
        var s = "\(second)"
        if second < 10 {
            s = "0\(second)"
        }
        return (m, s)
    }
    
    func displayCountDown(minute: String , second :String){
        if minute != "" && second != ""{
            labelMinutes.text = minute
            labelSeconds.text = second
            labelColon.text = ":"
            if minute == "00" && second == "00"{
                labelMinutes.textColor = UIColor.redColor()
                labelSeconds.textColor = UIColor.redColor()
                labelColon.textColor = UIColor.redColor()
            }
        }else{
            labelMinutes.text = ""
            labelSeconds.text = ""
            labelColon.text = ""
            labelMinutes.textColor = UIColor.whiteColor()
            labelSeconds.textColor = UIColor.whiteColor()
            labelColon.textColor = UIColor.whiteColor()
        }
    }
    
    func updateCountDown() {
        if countdown > 0 {
            countdown = countdown - 1
            if !isPanelDispalyed {
                let (m,s) = secondsToMinutesSeconds(countdown)
                displayCountDown(m,second: s)
            }
            if countdown < originalCountdown * 3 / 10 {
                imageHourGlass.image = UIImage(named: "Hourglass-20")
            }else if countdown < originalCountdown * 5 / 10{
                imageHourGlass.image = UIImage(named: "Hourglass-40")
            }else if countdown < originalCountdown * 7 / 10{
                imageHourGlass.image = UIImage(named: "Hourglass-60")
            }else if countdown < originalCountdown * 9 / 10{
                imageHourGlass.image = UIImage(named: "Hourglass-80")
            }
        }else if countdown == 0 {
            let (m,s) = secondsToMinutesSeconds(countdown)
            displayCountDown(m,second: s)
            imageHourGlass.image = UIImage(named: "Hourglass-0")
            updateUIRPM(0)
            updateUIBattery(0)
            updateUIFuel(0)
            if flagDemo {
                displayMessage("Engine shutdown")
            }
        }
    }
    
    func setAnchorPoint(anchorPoint: CGPoint, forView view: UIView) {
        printVDBG("Set anchor : \(view.layer.position)")
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
    
    func initializeNavigationBarUI(){
        printVDBG("Set up navigation bar : background, font, text color")
        navigationController?.navigationBar.setBackgroundImage(UIImage(named: "AppBackground"), forBarMetrics: .Default)
        navigationItem.backBarButtonItem = UIBarButtonItem(title:"", style:.Plain, target:nil, action:nil)
        navigationController?.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName:UIColor.greenColor()]    //set Title color
        navigationController?.navigationBar.titleTextAttributes = [NSFontAttributeName: UIFont(name: fontName, size: 20)!]
        printVDBG("Remove navigation bar shadow")
        for p in navigationController!.navigationBar.subviews {
            for c in p.subviews {
                if c is UIImageView {
                    c.removeFromSuperview()
                }
            }
        }
    }
    
    func getColorFromHex(value: UInt) -> UIColor{
        printVDBG("Get UIColor from hex value")
        return UIColor(
            red: CGFloat((value & 0xFF0000) >> 16) / 255.0,
            green: CGFloat((value & 0x00FF00) >> 8) / 255.0,
            blue: CGFloat(value & 0x0000FF) / 255.0,
            alpha: CGFloat(1.0)
        )
    }
    
    func printFontFamily(){
        printVDBG("Print font family")
        for name in UIFont.familyNames() {
            printVDBG("\(name)\n")
            printVDBG("\(UIFont.fontNamesForFamilyName(name))")
        }
    }
    
    func getSelectedModule() -> String{
        printVDBG("Get selected module")
        let selectedModule = NSUserDefaults.standardUserDefaults().objectForKey(tag_selected_module)
            as? String
        if selectedModule != nil && selectedModule != ""{
            printDBG("Selected module is : \(selectedModule!)")
            return selectedModule!
        }else{
            printDBG("Default module is nil")
            return ""
        }
    }
    
    
    func getDefaultModule() -> String{
        printVDBG("Get default module")
        let defaultModule = NSUserDefaults.standardUserDefaults().objectForKey(tag_default_module)
            as? String
        if defaultModule != nil {
            printDBG("Default module is : \(defaultModule!)")
            return defaultModule!
        }else{
            printDBG("Default module is nil")
            return checkDatabase()
        }
    }
    
    func setDemoFlag(flag : Bool){
        printDBG("Set demo flag : \(flag)")
        flagDemo = flag
        NSUserDefaults.standardUserDefaults().setObject(flag, forKey: "flagDemo")
    }
    
    func getLastScene() -> String{
        printVDBG("Get last scene")
        let lastScene =
            NSUserDefaults.standardUserDefaults().objectForKey(tag_last_scene)
                as? String
        if lastScene != nil {
            printDBG("Found last scene: \(lastScene!)")
            return lastScene!
        }else{
            printDBG("No last scene found")
            return ""
        }
    }
    
    func setLastScene(){
        printVDBG("Set last scene : Control")
        NSUserDefaults.standardUserDefaults().setObject("Control", forKey: tag_last_scene)
    }
    
    func rotateNeedle(view:UIView, angle: CGFloat){
        printVDBG("Rotate UIView angle by :\(angle)")
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
        printVDBG("Update temperature: \(temperature)º")
        let temp = CGFloat(temperature)
        printVDBG("currentAngleTemp=\(currentAngleTemp)")
        rotateNeedle(needleTemp, angle: getTempAngle(temp)/2-currentAngleTemp)
        rotateNeedle(needleTemp, angle: getTempAngle(temp))
        currentAngleTemp = getTempAngle(temp)
    }
    
    func slideDownPanel(){
        capContainerView.alpha = 1
        buttonLock.alpha = 1
        buttonUnlock.alpha = 1
        slideUpView.alpha = 0
        slideUpView.center.y = self.slideUpView.center.y + self.slideUpView.bounds.height
        let transform = CGAffineTransformIdentity
        buttonMore.transform = transform
    }
    
    func initializeUIComponents(){
        printVDBG("Initialize UI components")
        initializeNavigationBarUI()
        labelMinutes.text = ""
        labelSeconds.text = ""
        labelColon.text = ""
        
        longPressStart.enabled = false
        buttonCover.backgroundColor = UIColor.clearColor()
        buttonCover.clipsToBounds = true
        
        imageCap.backgroundColor = UIColor.clearColor()
        imageCap.layoutIfNeeded()
        imageCap.clipsToBounds = true
        
        imageStartFrame.backgroundColor = UIColor.clearColor()
        imageStartFrame.layoutIfNeeded()
        imageStartFrame.clipsToBounds = true
        
        buttonUnlock.clipsToBounds = true
        buttonLock.clipsToBounds = true
        buttonMore.clipsToBounds = true
        
        buttonDemoOnEmpty.clipsToBounds = true
        buttonDemoOnEmpty.layer.cornerRadius = 20.0
        buttonDemoOnEmpty.layer.backgroundColor = UIColor.whiteColor().CGColor
        
        buttonDemoOnLostConnection.clipsToBounds = true
        buttonDemoOnLostConnection.layer.cornerRadius = 20
        buttonDemoOnLostConnection.layer.backgroundColor = UIColor.whiteColor().CGColor
        
        buttonGoToGarage.clipsToBounds = true
        buttonGoToGarage.layer.cornerRadius = 20.0
        buttonGoToGarage.layer.backgroundColor = UIColor.whiteColor().CGColor
        
        buttonReconnect.clipsToBounds = true
        buttonReconnect.layer.cornerRadius = 20.0
        buttonReconnect.layer.backgroundColor = UIColor.whiteColor().CGColor
        
        buttonAddFromEmpty.clipsToBounds = true
        buttonAddFromEmpty.layer.cornerRadius = 20.0
        buttonAddFromEmpty.layer.backgroundColor = UIColor.whiteColor().CGColor
        
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
        printDBG("Check database for registered vehicle")
        
        let vehicles : [Vehicle] = dataController!.getAllVehicles()
        if vehicles.count > 0 {
            printDBG("Use first vehicle in the database")
            return vehicles[0].module!
        }else {
            printDBG("no vehicle registerd")
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
        if isPanelDispalyed {
            isPanelDispalyed = false
            UIView.animateWithDuration(0.5, animations: {
                self.slideDownPanel()
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
                printDBG("Reconnecting...")
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
                    sleep(3)
                    if !self.isConnected{
                        dispatch_async(dispatch_get_main_queue(),{
                            let actionSheet = UIAlertController(title: "Info", message: "Unable to re connect", preferredStyle: .ActionSheet)
                            actionSheet.addAction(UIAlertAction(title: "OK", style: .Cancel, handler: nil))
                            self.presentViewController(actionSheet, animated: true, completion: nil)
                        })
                    }
                })
            }
        }
    }
    
    @IBAction func onValet(sender: UIButton) {
        printDBG("On valet")
        if !flagDemo {
            checkingValetState = true
            printDBG("set checkingValetState = true")
            sendRequestStatus()
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
                self.printDBG("Wait for state update for valet")
                sleep(2)
                if self.stateValet {
                    dispatch_async(dispatch_get_main_queue(),{
                        self.showActionSheetValet()
                    })
                }else{
                    dispatch_async(dispatch_get_main_queue(),{
                        self.checkingValetEvent = true
                        self.printDBG("set checkingValetEvent = true")
                        let data = NSData(bytes: [0xA8] as [UInt8], length: 1)
                        self.sendCommand(data, actionId: 0x01, retry: 0)
                        self.printDBG("Wait for valet event... from off")
                    })
                }
            })
        }else{
            printDBG("On valet in demo mode")
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
                sleep(1)
                if self.stateValet {
                    dispatch_async(dispatch_get_main_queue(),{
                        let actionSheet = UIAlertController(title: "Info", message: "Disabling valet mode?", preferredStyle: .ActionSheet)
                        actionSheet.addAction(UIAlertAction(title: "Confirm", style: .Default,handler: {
                            action in
                            self.showValetOff()
                            self.stateValet = false
                        }))
                        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: nil))
                        self.presentViewController(actionSheet, animated: true, completion: nil)
                    })
                }else{
                    dispatch_async(dispatch_get_main_queue(),{
                        self.showValetOn()
                        self.stateValet = true
                    })
                }
            })
        }
    }
    
    @IBAction func onTrunk(sender: UIButton) {
        if !flagDemo {
            printDBG("onTrunk")
            if !stateTrunkOpened {
                waitingList.removeAll()
                lastRaw = nil
                checkingTrunkEvent = true
                ifNeedVibration = true
                let data = NSData(bytes: [0x34] as [UInt8], length: 1)
                sendCommand(data, actionId: 0x20, retry: 2)
            }else{
                if isPanelDispalyed {
                    isPanelDispalyed = false
                    UIView.animateWithDuration(0.3, animations: {
                        self.slideDownPanel()
                        }, completion: { finished in
                            self.displayMessage(self.msgTrunkReleased)
                    })
                }
                printDBG("Trunk is already opened")
            }
        }else{
            printDBG("onTrunk in demo mode")
            showTrunkReleased()
        }
    }
    
    @IBAction func onLock(sender: UIButton) {
        if !flagDemo {
            printDBG("onLock 0x30")
            waitingList.removeAll()
            lastRaw = nil
            ifNeedVibration = true
            let data = NSData(bytes: [0x30] as [UInt8], length: 1)
            sendCommand(data, actionId: 0x80, retry: 2)
            
            checkingLock = true
        }else{
            printDBG("onLock in demo mode")
            showLocked()
            displayMessage(msgDoorLocked)
            performBuzz(true, repeats: 1)
        }
    }
    
    @IBAction func onUnlock(sender: UIButton) {
        if !flagDemo {
            printDBG("onUnlock 0x31")
            waitingList.removeAll()
            lastRaw = nil
            ifNeedVibration = true
            let data = NSData(bytes: [0x31] as [UInt8], length: 1)
            sendCommand(data, actionId: 0x80, retry: 2)
            checkingLock = true
        }else{
            printDBG("onUnlock in demo mode")
            showUnlocked()
            
            displayMessage(msgDoorUnlocked)
            performBuzz(true, repeats: 1)
        }
    }
    
    @IBAction func onDown(sender: UISwipeGestureRecognizer) {
        printDBG("On swipe down")
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
        printDBG("On swipe up")
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
    
    @IBAction func onLongPressStart(sender: UILongPressGestureRecognizer) {
        switch sender.state {
        case UIGestureRecognizerState.Began:
            printDBG("UIGestureRecognizerState.Began")
            isPressing = true
            longPressCountDown = 0
            var glowtransform = CGAffineTransformIdentity
            UIView.animateWithDuration(0.3, animations: {
                glowtransform = CGAffineTransformScale(glowtransform,1.3, 1)
                self.imageGlowing.alpha = 1.0
                self.imageGlowing.transform = glowtransform
            })
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
                self.printDBG("now \(self.longPressCountDown)")
                while self.isPressing && self.longPressCountDown <= 5{
                    self.longPressCountDown += 1
                    self.printDBG("set \(self.longPressCountDown)")
                    usleep(150000)
                }
                
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
                        if !self.flagDemo {
                            if self.stateRemote {
                                self.sendStop()
                            }else {
                                self.sendStart()
                            }
                        }else{
                            dispatch_async(dispatch_get_main_queue(),{
                                if self.stateRemote {
                                    self.printDBG("demo stop")
                                    self.showStopped()
                                    self.stateRemote = false
                                    self.stopTimer()
                                    self.performBuzz(true, repeats: 1)
                                    self.displayMessage(self.msgRemoteStopped)
                                }else {
                                    self.printDBG("demo start")
                                    self.showStarted()
                                    self.performBuzz(true, repeats: 3)
                                    self.stateRemote = true
                                    self.startTimerFrom(30)
                                    self.displayMessage(self.msgRemoteStarted)
                                }
                            })
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
            printDBG("UIGestureRecognizerState.Ended")
            break
        default:
            break
        }
    }
    
    @IBAction func onUpdateTemp(sender: UIButton) {
        printVDBG("On update temperatrure")
    }
    
    @IBAction func onTryDemo(sender: UIButton) {
        printDBG("Entering demo mode when : lost connection")
        coverLostConnection.hidden = true
        coverEmptyGarage.hidden = true
        buttonLock.enabled = true
        buttonUnlock.enabled = true
        buttonCover.enabled = true
        self.title = "Control/Demo"
        setDemoFlag(true)
    }
    
    @IBAction func onDemo(sender: UIButton) {
        printDBG("Entering demo mode when : empty garage")
        coverLostConnection.hidden = true
        coverEmptyGarage.hidden = true
        buttonLock.enabled = true
        buttonUnlock.enabled = true
        buttonCover.enabled = true
        setDemoFlag(true)
        self.title = "Control/Demo"
    }
    
    func sendCommand(data : NSData, actionId: UInt8, retry: Int){
        if peripheral != nil && writeCharacteristic != nil {
            if !waitingList.contains(actionId){
                waitingList.append(actionId)
            }
            lastIntValue = nil
            if retry == 0 {
                peripheral.writeValue(data, forCharacteristic: self.writeCharacteristic, type: .WithResponse)
                printDBG("Send command: [0x\(data.hexString)]")
            }else{
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
                    var sendCount = 0
                    while sendCount < retry + 1 {
                        self.peripheral.writeValue(data, forCharacteristic: self.writeCharacteristic, type: .WithResponse)
                        if self.DBG {
                            self.printDBG("Send command: \(sendCount): [0x\(data.hexString)]")
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
                        self.checkingLock = false
                        self.checkingStart = false
                        self.checkingStop = false
                        self.checkingValetState = false
                        self.checkingValetEvent = false
                        self.printDBG("Auto removing \(actionId.hexString)")
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
    
    func sendRequestStatus(){
        printDBG("Request status")
        let data = NSData(bytes: [0xAA] as [UInt8], length: 1)
        if peripheral != nil && writeCharacteristic != nil {
            ifNeedVibration = true
            sendCommand(data, actionId: 0xAA, retry: 0)
        }
    }
    
    func sendStart() {
        printDBG("Start engine")
        let data = NSData(bytes: [0x32] as [UInt8], length: 1)
        sendCommand(data, actionId: 0x02, retry: 2)
        checkingStart = true
    }
    
    func sendStop() {
        printDBG("Stop engine")
        let data = NSData(bytes: [0x33] as [UInt8], length: 1)
        sendCommand(data, actionId: 0x02, retry: 2)
        checkingStop = true
    }
    
    func setNotification(enabled: Bool){
        printDBG("Set notification: \(enabled)")
        if peripheral != nil && stateCharacteristic != nil {
            peripheral.setNotifyValue(enabled, forCharacteristic: stateCharacteristic)
        }
    }
    
    
    func displayMessage(line: String){
        self.labelMessage.text = line
    }
    
    
    
    func handleRawData(data: NSData){
        let rawHex = data.hexString
        
        if lastRaw == nil || rawHex != lastRaw{
            printDBG("- - - - - - - - - - - - - - - - - - - - - - - - - - -")
            printDBG("Raw: [\(rawHex)]")
            handleData(data)
        }
        
        lastRaw = rawHex
    }
    
    func handleData(data :NSData){
        //put NSData in an array of UInt8 value
        let count = data.length / sizeof(UInt8)
        var array = [UInt8](count: count, repeatedValue: 0)
        data.getBytes(&array, length: count * sizeof(UInt8))
        
        if array.count == 6 {
            var result = Dictionary<String,Int!>()
            result["Runtime    "] = Int(array[0]) + 256 * Int(array[1])
            result["Event      "] = Int(array[3])
            result["Status     "] = Int(array[2])
            result["Temperature"] = Int(array[4])
            for key in result.keys{
                printDBG("\(key): \(result[key]!.hexString)")
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
            printDBG("State valet    : \(stateValet)")
            printDBG("State remote   : \(stateRemote)")
            printDBG("State ignition : \(stateIgnition)")
            printDBG("State engine   : \(stateEngineStarted)")
            printDBG("State hood     : \(stateHoodOpened)")
            printDBG("State trunk    : \(stateTrunkOpened)")
            printDBG("State door     : \(stateDoorOpened)")
            printDBG("State lock     : \(stateLocked)")
            
            
            //handle runtime countdown
            let runtimeCountdown = result["Runtime    "]!
            
            
            
            if runtimeCountdown != 0 && runtimeCountdown != 65535{
                countdown = runtimeCountdown
                if isTimerRunning {
                    reSyncTimer(countdown)
                    resetNotification(countdown)
                }else{
                    if !checkingStart && stateRemote{
                        startTimerFrom(countdown)
                    }
                }
            }else{
                if runtimeCountdown == 0 {
                    stopTimer()
                    let application = UIApplication.sharedApplication()
                    let scheduledNotifications = application.scheduledLocalNotifications!
                    for notification in scheduledNotifications {
                        application.cancelLocalNotification(notification)
                    }
                }
            }
            printDBG("Handle runtime countdown: \(runtimeCountdown) seconds")
            printDBG("- - - - - - - - - - - - - - - - - - - - - - - - - - -")
            if waitingList.contains(0xAE){
                let index = waitingList.indexOf(0xAE)
                waitingList.removeAtIndex(index!)
            }
            if isFirstACK {
                isFirstACK = false
            }
        }else{
            printVDBG("Error when processing NSData, array count : \(array.count)")
        }
    }
    
    func handleStatusAndEvent(status : UInt8, event: UInt8){
        printDBG("Handle status and event")
        
        if checkingValetState {
            printDBG("Checking valet")
            printDBG("Check valet mode flag : ON")
            
            if waitingList.contains(0xAA){
                let index = waitingList.indexOf(0xAA)
                waitingList.removeAtIndex(index!)
            }
            
            if checkingValetEvent {
                printDBG("Check valet event flag : ON")
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
                performBuzz(true, repeats: 1)
                return
            }
            
            checkValet(status)
            return
        }
        
        if checkingStart {
            printDBG("Checking start")
            printDBG("Starting engine flag : ON")
            if waitingList.contains(0x02){
                let index = waitingList.indexOf(0x02)
                waitingList.removeAtIndex(index!)
            }
            
            if event == 7 {
                checkingStart = false
                showStartFailed()
                return
            }else if event == 6{
                checkingStart = false
                if stateRemote {
                    showStarted()
                    printDBG("Engine started : perform 3 buzzs")
                    performBuzz(true, repeats: 3)
                }
                
                printDBG("Engine started : Event 6 received")
                
                if !isFirstACK {
                    displayMessage(msgRemoteStarted)
                }
                return
            }else{
                checkIgnition(status)
                checkRemote(status)
                checkEngine(status)
                if stateRemote {
                    printDBG("Starting engine remotely")
                    if !isFirstACK {
                        displayMessage("Starting engine...")
                    }
                }
                return
            }
        }
        
        if checkingStop {
            printDBG("Checking stop")
            if waitingList.contains(0x02){
                let index = waitingList.indexOf(0x02)
                waitingList.removeAtIndex(index!)
            }
            checkingStop = false
            
            checkIgnition(status)
            checkRemote(status)
            checkEngine(status)
            showStopped()
            performBuzz(true, repeats: 1)
            if !isFirstACK{
                displayMessage("\(msgRemoteStopped)")
            }
            return
        }
        
        if checkingLock {
            printDBG("Checking lock")
            if waitingList.contains(0x80){
                let index = waitingList.indexOf(0x80)
                waitingList.removeAtIndex(index!)
                lastRaw = nil
            }
            checkingLock = false
            
            if status & mask9lock != 0 {
                showLocked()
                displayMessage(msgDoorLocked)
                stateLocked = true
            }else{
                showUnlocked()
                displayMessage(msgDoorUnlocked)
                stateLocked = false
            }
            performBuzz(true, repeats: 1)
            return
        }
        
        printDBG("Checking notification")
        
        checkTrunk(status, event: event)
        checkHood(status)
        checkDoor(status)
        checkLock(status)
        checkValet(status)
        
        if stateRemote {
            checkIgnition(status)
            checkRemote(status)
            checkEngine(status)
            printDBG("not checking start or stop or valet")
            if !stateRemote && !isFirstACK{
                showStopped()
            }
        }else{
            checkIgnition(status)
            checkRemote(status)
            checkEngine(status)
            if stateRemote {
                showStarted()
                if event == 6 {
                    printDBG("aaaaaaaaaaa")
                    performBuzz(true, repeats: 3)
                }
                displayMessage("\(msgRemoteStarted)")
            }
        }
        
        if waitingList.contains(0xAA){
            let index = waitingList.indexOf(0xAA)
            waitingList.removeAtIndex(index!)
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
            printDBG("Trunk event: 0x\(intValue.hexString)")
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
            showLocked()
            stateLocked = true
        }else{
            showUnlocked()
            stateLocked = false
        }
    }
    
    func printDBG(string :String){
        if DBG {
            print("\(getTimestamp()) \(string)")
        }
    }
    
    func printVDBG(string :String){
        if VDBG {
            print("\(getTimestamp()) VDBG - \(string)")
        }
    }
    
    func getTimestamp() -> String{
        let date = NSDate()
        let calender = NSCalendar.currentCalendar()
        let components = calender.components([.Hour,.Minute,.Second], fromDate: date)
        var h = "\(components.hour)"
        if components.hour < 10 {
            h = "0\(components.hour)"
        }
        var m = "\(components.minute)"
        if components.minute < 10 {
            m = "0\(components.minute)"
        }
        var s = "\(components.second)"
        if components.second < 10 {
            s = "0\(components.second)"
        }
        return "[\(h):\(m):\(s)] - Control - "
    }
    
    func performBuzz(enabled: Bool, repeats: Int){
        if enabled {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
                for _ in 1...repeats {
                    dispatch_async(dispatch_get_main_queue(),{
                        AudioServicesPlayAlertSound(UInt32(kSystemSoundID_Vibrate))
                    })
                    usleep(1000 * 500)
                }
                self.ifNeedVibration = false
            })
        }
    }
    
    func showUnlocked(){
        printVDBG("Show door unlocked")
        if isPanelDispalyed {
            isPanelDispalyed = false
            UIView.animateWithDuration(0.3, animations: {
                self.slideDownPanel()
                }, completion: { finished in
                    self.buttonLock.setImage(UIImage(named: "ButtonLockOff"), forState: .Normal)
                    self.buttonUnlock.setImage(UIImage(named: "ButtonUnlockOn"), forState: .Normal)
            })
        }else{
            buttonLock.setImage(UIImage(named: "ButtonLockOff"), forState: .Normal)
            buttonUnlock.setImage(UIImage(named: "ButtonUnlockOn"), forState: .Normal)
        }
    }
    
    func showLocked(){
        printVDBG("Show door locked")
        if isPanelDispalyed {
            isPanelDispalyed = false
            UIView.animateWithDuration(0.3, animations: {
                self.slideDownPanel()
                }, completion: { finished in
                    self.buttonLock.setImage(UIImage(named: "ButtonLockOn"), forState: .Normal)
                    self.buttonUnlock.setImage(UIImage(named: "ButtonUnlockOff"), forState: .Normal)
            })
        }else{
            buttonLock.setImage(UIImage(named: "ButtonLockOn"), forState: .Normal)
            buttonUnlock.setImage(UIImage(named: "ButtonUnlockOff"), forState: .Normal)
        }
    }
    
    func showDoorOpened(){
        printVDBG("Show door opened")
        if isPanelDispalyed {
            isPanelDispalyed = false
            UIView.animateWithDuration(0.3, animations: {
                self.slideDownPanel()
                }, completion: { finished in
                    self.imageViewDoors.image = UIImage(named: "StateDoorOpened")
            })
        }else{
            imageViewDoors.image = UIImage(named: "StateDoorOpened")
        }
    }
    
    func showDoorClosed(){
        printVDBG("Show door closed")
        if isPanelDispalyed {
            isPanelDispalyed = false
            UIView.animateWithDuration(0.3, animations: {
                self.slideDownPanel()
                }, completion: { finished in
                    self.imageViewDoors.image = nil
            })
        }else{
            self.imageViewDoors.image = nil
        }
    }
    
    func showTrunkReleased(){
        if isPanelDispalyed {
            isPanelDispalyed = false
            UIView.animateWithDuration(0.3, animations: {
                self.slideDownPanel()
                }, completion: { finished in
                    self.buttonTrunk.setImage(UIImage(named: "ButtonTrunkReleased"), forState: .Normal)
                    self.displayMessage(self.msgTrunkReleased)
            })
        }else{
            buttonTrunk.setImage(UIImage(named: "ButtonTrunkReleased"), forState: .Normal)
            displayMessage(msgTrunkReleased)
        }
        performBuzz(true, repeats: 1)
    }
    
    func showTrunkOpened(){
        if isPanelDispalyed {
            isPanelDispalyed = false
            UIView.animateWithDuration(0.3, animations: {
                self.slideDownPanel()
                }, completion: { finished in
                    self.imageViewTrunk.image = UIImage(named: "StateTrunkOpened")
                    self.buttonTrunk.setImage(UIImage(named: "ButtonTrunk"), forState: .Normal)
                    self.performBuzz(true, repeats: 1)
                    if !self.isFirstACK {
                        self.displayMessage(self.msgTrunkOpened)
                    }
            })
        }else{
            imageViewTrunk.image = UIImage(named: "StateTrunkOpened")
            buttonTrunk.setImage(UIImage(named: "ButtonTrunk"), forState: .Normal)
            performBuzz(true, repeats: 1)
            if !isFirstACK {
                displayMessage(msgTrunkOpened)
            }
        }
    }
    
    func showTrunkClosed(){
        if isPanelDispalyed {
            isPanelDispalyed = false
            UIView.animateWithDuration(0.3, animations: {
                self.slideDownPanel()
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
    
    func showHoodOpened(){
        printVDBG("Show hood opened")
        if isPanelDispalyed {
            isPanelDispalyed = false
            UIView.animateWithDuration(0.3, animations: {
                self.slideDownPanel()
                }, completion: { finished in
                    self.imageViewHood.image = UIImage(named: "StateHoodOn")
            })
        }else{
            imageViewHood.image = UIImage(named: "StateHoodOn")
        }
        performBuzz(true, repeats: 1)
    }
    
    func showHoodClosed(){
        printVDBG("Show hood closed")
        if isPanelDispalyed {
            isPanelDispalyed = false
            UIView.animateWithDuration(0.3, animations: {
                self.slideDownPanel()
                }, completion: { finished in
                    self.imageViewHood.image = nil
            })
        }else{
            imageViewHood.image = nil
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
    
    func showStarted(){
        if isPanelDispalyed {
            isPanelDispalyed = false
            UIView.animateWithDuration(0.3, animations: {
                self.slideDownPanel()
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
    }
    
    func showStopped(){
        if isPanelDispalyed {
            isPanelDispalyed = false
            UIView.animateWithDuration(0.3, animations: {
                self.slideDownPanel()
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
        
        stopTimer()
    }
    
    func showStartFailed(){
        if isPanelDispalyed {
            isPanelDispalyed = false
            UIView.animateWithDuration(0.3, animations: {
                self.slideDownPanel()
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
            displayMessage(msgRemoteFailed)
        }
        stopTimer()
        performBuzz(true, repeats: 1)
    }
    
    func showValetOn(){
        if isPanelDispalyed {
            isPanelDispalyed = false
            UIView.animateWithDuration(0.3, animations: {
                self.slideDownPanel()
                }, completion: { finished in
                    self.displayMessage(self.msgValetOn)
            })
        }else{
            displayMessage(msgValetOn)
        }
        checkingValetEvent = false
    }
    
    func showValetOff(){
        if isPanelDispalyed {
            isPanelDispalyed = false
            UIView.animateWithDuration(0.3, animations: {
                self.slideDownPanel()
                }, completion: { finished in
                    self.displayMessage(self.msgValetOff)
            })
        }else{
            displayMessage(msgValetOff)
        }
        checkingValetEvent = false
    }
    
    func showActionSheetValet(){
        let actionSheet = UIAlertController(title: "Warning", message: "Are you sure about disabling valet mode?", preferredStyle: .ActionSheet)
        actionSheet.addAction(UIAlertAction(title: "Confirm", style: .Default,handler: {
            action in
            self.checkingValetEvent = true
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
    
    
}

