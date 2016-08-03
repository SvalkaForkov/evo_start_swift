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
    
    var name = ""
    var address = ""
    var count = 0
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
    @IBAction func onClearLog(sender: UIButton) {
        self.textViewLog.text = ""
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.navigationBar.barTintColor = getColorFromHex(0xe21f1d)
        removeBorderFromBar()
        textViewLog.text = ""
        getDefault()
        if name != "" {
            logOnScreen("not nil : "+name)
            centralManager = CBCentralManager(delegate: self, queue:nil)
        }else{
            logOnScreen("prompt image")
            imageStatus.image = UIImage(named: "unlock")
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
    
    func getDefault(){
        logOnScreen("check default")
        let defaultName =
        NSUserDefaults.standardUserDefaults().objectForKey("default")
        as? String
        if defaultName != nil {
            logOnScreen("default is not nil")
            name = defaultName!
        }else{
            logOnScreen("default is nil")
            name = ""
            checkDatabase()
        }
    }
    
    func setDefault(value: String){
        logOnScreen("set default : \(value)")
        NSUserDefaults.standardUserDefaults().setObject(value, forKey: "default")
    }
    
    func checkDatabase(){
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        let dataController = appDelegate.dataController
        let vehicles : [Vehicle] = dataController.getAllVehicles()
        if vehicles.count > 0 {
            name = vehicles[0].name!
            logOnScreen("use first vehicle in the database")
        }else {
            logOnScreen("no vehicle registerd")
        }
    }
    
    func sendLock(){
        
    }
    
    func sendUnlock(){
        
    }
    
    func sendStart(){
        
    }
    
    func sendStop(){
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func centralManagerDidUpdateState(central: CBCentralManager) {
        switch(central.state){
        case CBCentralManagerState.PoweredOn:
            logOnScreen("Ble PoweredOn")
            centralManager.scanForPeripheralsWithServices(nil, options: nil)
            logOnScreen("Scanning bluetooth")
            break
        case CBCentralManagerState.PoweredOff:
            logOnScreen("Ble PoweredOff")
            centralManager.stopScan()
            break
        case CBCentralManagerState.Unauthorized:
            logOnScreen("Unauthorized state")
            break
        case CBCentralManagerState.Resetting:
            logOnScreen("Resetting state")
            break
        case CBCentralManagerState.Unknown:
            logOnScreen("unknown state")
            break
        case CBCentralManagerState.Unsupported:
            logOnScreen("Unsupported state")
            break
        }
    }
    
    func centralManager(central: CBCentralManager, didDiscoverPeripheral peripheral: CBPeripheral, advertisementData: [String : AnyObject], RSSI: NSNumber) {
        let nameOfDeviceFound = peripheral.name as String!
        if nameOfDeviceFound != nil {
            logOnScreen("Did discover \(nameOfDeviceFound)")
            logOnScreen("and name is \(name)")
            if nameOfDeviceFound == name{
                logOnScreen("Match")
                centralManager.stopScan()
                logOnScreen("Stop scanning after \(nameOfDeviceFound) device found")
                self.peripheral = peripheral
                self.peripheral.delegate = self
                centralManager.connectPeripheral(self.peripheral, options: nil)
                logOnScreen("Try to connect \(nameOfDeviceFound)")
            }
        }
    }
    
    func centralManager(central: CBCentralManager, didConnectPeripheral peripheral: CBPeripheral) {
        logOnScreen("Peripheral connected")
        setDefault(peripheral.name!)
        peripheral.discoverServices(nil)
    }
    
    func peripheral(peripheral: CBPeripheral, didDiscoverServices error: NSError?) {
        logOnScreen("Discovered service")
        for service in peripheral.services! {
            if(service.UUID.UUIDString == "1234"){
                self.service = service
            }
            logOnScreen("Found service: \(service.UUID)")
            peripheral.discoverCharacteristics(nil, forService: service)
        }
    }
    
    func peripheral(peripheral: CBPeripheral, didDiscoverCharacteristicsForService service: CBService, error: NSError?) {
        logOnScreen("Discovered characteristic")
        for characteristic in service.characteristics! {
            if(characteristic.UUID.UUIDString == "1235"){
                self.writeCharacteristic = characteristic
            }
            if(characteristic.UUID.UUIDString == "1236"){
                self.notificationCharacteristic = characteristic
                setNotification(true)
            }
            logOnScreen("Found characteristic: \(characteristic.UUID)")
        }
        logOnScreen("Connection ready")
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
        logOnScreen("onlock")
        let data = NSData(bytes: [0x30] as [UInt8], length: 1)
        sendCommend(data, action: 0)
    }
    
    
    @IBAction func onUnlock(sender: UIButton) {
        logOnScreen("onUnlock")
        let data = NSData(bytes: [0x31] as [UInt8], length: 1)
        sendCommend(data, action: 1)
    }
    
    @IBAction func onStart(sender: UIButton) {
        if started {
            stopEngine()
        } else {
            startEngine()
        }
    }
    
    func startEngine() {
        logOnScreen("on start")
        let data = NSData(bytes: [0x32] as [UInt8], length: 1)
        sendCommend(data, action: 2)
        started = true
        receivedStart = true
    }
    
    func stopEngine() {
        logOnScreen("on stop")
        let data = NSData(bytes: [0x33] as [UInt8], length: 1)
        receivedStop = false
        sendCommend(data, action: 3)
        started = false
        receivedStop = true
    }
    
    func sendCommend(data : NSData, action : Int){
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
            self.peripheral.writeValue(data, forCharacteristic: self.writeCharacteristic, type: .WithResponse)
            dispatch_async(dispatch_get_main_queue(),{
                self.logOnScreen("Send : 1st time")
            })
            sleep(1)
            if flag {
                return
            }
            self.peripheral.writeValue(data, forCharacteristic: self.writeCharacteristic, type: .WithResponse)
            dispatch_async(dispatch_get_main_queue(),{
                self.logOnScreen("Send : 2nd time")
            })
            sleep(1)
            if flag {
                return
            }
            self.peripheral.writeValue(data, forCharacteristic: self.writeCharacteristic, type: .WithResponse)
            dispatch_async(dispatch_get_main_queue(),{
                self.logOnScreen("Send : 3rd time")
            })
            sleep(1)
            if flag {
                return
            }
            self.peripheral.writeValue(data, forCharacteristic: self.writeCharacteristic, type: .WithResponse)
            dispatch_async(dispatch_get_main_queue(),{
                self.logOnScreen("Send : 4th time")
            })
            sleep(1)
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
        peripheral.setNotifyValue(enabled, forCharacteristic: notificationCharacteristic)
    }
    
    func peripheral(peripheral: CBPeripheral, didUpdateValueForCharacteristic characteristic: CBCharacteristic, error: NSError?) {
        let val = characteristic.value!.hexString
        if(val=="00008001"){
            //ack for locked
            logOnScreen("\(val) : \(count)")
            count = count + 1
            receivedLock = true
            AudioServicesPlayAlertSound(UInt32(kSystemSoundID_Vibrate))
        }else if(val=="00000002"){
            //ack for unlocked
            logOnScreen("\(val) : \(count)")
            count = count + 1
            receivedUnlock = true
            AudioServicesPlayAlertSound(SystemSoundID(kSystemSoundID_Vibrate))
        }else if(val=="00000201"){
            //ack for started
            started = true
            logOnScreen("\(val) : \(count)")
            count = count + 1
            receivedStart = true
        }else if(val=="00000001"){
            started = false
            //ack for stopped
            logOnScreen("\(val) : \(count)")
            count = count + 1
            receivedStop = true
        }else if(val=="0240000f"){
            //ack for locked
            buttonStart.selected = false
            buttonStart.setTitle("Start", forState: UIControlState.Normal)
        }else{
            logOnScreen("\(val) : \(count)")
            count = count + 1
            receivedLock = true
            receivedStop = true
            receivedStart = true
            receivedUnlock = true
        }
        logOnScreen("Charateristic's value has updated : \(val!)")
    }
    
    func centralManager(central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: NSError?) {
        logOnScreen("Disconnected")
        if !isManuallyDisconnected {
            central.scanForPeripheralsWithServices(nil, options: nil)
            showControl(false)
        }
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        if self.isMovingToParentViewController() {
            logOnScreen("on back clicked")
            isManuallyDisconnected = true
            centralManager.cancelPeripheralConnection(self.peripheral)
        }
    }
}

