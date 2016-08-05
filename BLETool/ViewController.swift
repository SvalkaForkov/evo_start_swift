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
    
    override func viewWillAppear(animated: Bool) {
        centralManager = CBCentralManager(delegate: self, queue:nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.navigationBar.barTintColor = UIColor.blackColor()
        self.navigationController?.navigationBar.tintColor = UIColor.whiteColor()
        self.navigationController?.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName:UIColor.whiteColor()]
        //getColorFromHex(0xe21f1d)
        removeBorderFromBar()
        textViewLog.text = ""
        getDefault()
        print("view did load")
        if module != "" {
            print("not nil : " + module)
            centralManager = CBCentralManager(delegate: self, queue:nil)
        }else{
            print("prompt image")
            imageStatus.image = UIImage(named: "unlock")
            performSegueWithIdentifier("control2scan", sender: self)
        }
    }
    
    @IBAction func onClearLog(sender: UIButton) {
        self.textViewLog.text = ""
    }
    
    @IBAction func onGarageButton(sender: UIButton) {
        print("on Garage button clicked")
        centralManager.stopScan()
        if peripheral != nil {
            centralManager.cancelPeripheralConnection(peripheral)
            centralManager = nil
            print("disconnect")
        }
        performSegueWithIdentifier("control2garage", sender: sender)
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
        print("check default")
        let defaultName =
        NSUserDefaults.standardUserDefaults().objectForKey("default")
        as? String
        if defaultName != nil {
            print("default is not nil")
            module = defaultName!
        }else{
            print("default is nil")
            module = ""
            checkDatabase()
        }
    }
    
    func setDefault(value: String){
        print("set default : \(value)")
        NSUserDefaults.standardUserDefaults().setObject(value, forKey: "default")
    }
    
    func checkDatabase(){
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        let dataController = appDelegate.dataController
        let vehicles : [Vehicle] = dataController.getAllVehicles()
        if vehicles.count > 0 {
            module = vehicles[0].module!
            print("use first vehicle in the database")
        }else {
            print("no vehicle registerd")
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func centralManagerDidUpdateState(central: CBCentralManager) {
        switch(central.state){
        case CBCentralManagerState.PoweredOn:
            print("Ble PoweredOn")
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
            print("Did discover \(nameOfDeviceFound)")
            print("and name is \(module)")
            if nameOfDeviceFound == module{
                print("Match")
                centralManager.stopScan()
                print("Stop scanning after \(nameOfDeviceFound) device found")
                self.peripheral = peripheral
                self.peripheral.delegate = self
                centralManager.connectPeripheral(self.peripheral, options: nil)
                print("Try to connect \(nameOfDeviceFound)")
            }
        }
    }
    
    func centralManager(central: CBCentralManager, didConnectPeripheral peripheral: CBPeripheral) {
        print("Peripheral connected")
        setDefault(peripheral.name!)
        peripheral.discoverServices([CBUUID(string: "1234")])
    }
    
    func peripheral(peripheral: CBPeripheral, didDiscoverServices error: NSError?) {
        print("Discovered service")
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
        receivedStart = true
    }
    
    func stopEngine() {
        print("stopEngine")
        let data = NSData(bytes: [0x33] as [UInt8], length: 1)
        receivedStop = false
        sendCommend(data, action: 3)
        started = false
        receivedStop = true
    }
    
    func sendCommend(data : NSData, action : Int){
        print("send command : \(action)")
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
            print("go off main thread")
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
        print("setNotification = true")
        peripheral.setNotifyValue(enabled, forCharacteristic: notificationCharacteristic)
    }
    
    func peripheral(peripheral: CBPeripheral, didUpdateValueForCharacteristic characteristic: CBCharacteristic, error: NSError?) {
        let val = characteristic.value!.hexString
        if(val=="00008001"){
            //ack for locked
            print("\(val) : \(count)")
            count = count + 1
            receivedLock = true
            AudioServicesPlayAlertSound(UInt32(kSystemSoundID_Vibrate))
        }else if(val=="00000002"){
            //ack for unlocked
            print("\(val) : \(count)")
            count = count + 1
            receivedUnlock = true
            AudioServicesPlayAlertSound(SystemSoundID(kSystemSoundID_Vibrate))
        }else if(val=="00000201"){
            //ack for started
            started = true
            print("\(val) : \(count)")
            count = count + 1
            receivedStart = true
        }else if(val=="00000001"){
            started = false
            //ack for stopped
            print("\(val) : \(count)")
            count = count + 1
            receivedStop = true
        }else if(val=="0240000f"){
            //ack for locked
            buttonStart.selected = false
            buttonStart.setTitle("Start", forState: UIControlState.Normal)
        }else{
            print("\(val) : \(count)")
            count = count + 1
            receivedLock = true
            receivedStop = true
            receivedStart = true
            receivedUnlock = true
        }
        print("Charateristic's value has updated : \(val!)")
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
}

