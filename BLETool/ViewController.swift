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
    @IBOutlet var labelDeivceName: UILabel!
    
    @IBOutlet var buttonScan: UIButton!
    @IBOutlet var buttonConnect: UIButton!
    @IBOutlet var controlView: UIStackView!
    
    @IBOutlet var buttonUnlock: UIButton!
    @IBOutlet var buttonLock: UIButton!
    @IBOutlet var buttonStart: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("\(name)")
        labelDeivceName.text = name
        centralManager = CBCentralManager(delegate: self, queue:nil)
    }
    
    
    func log(text:String){
        print("\(text)")
    }
    override func  preferredStatusBarStyle()-> UIStatusBarStyle {
        return UIStatusBarStyle.LightContent
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    func onReady(isReady: Bool){
        if(isReady){
            log("Ble ready")
            buttonScan.enabled = true
            centralManager.scanForPeripheralsWithServices(nil, options: nil)
            log("Scanning")
        }
        else{
            log("Ble not ready")
            buttonScan.enabled = false
        }
    }
    func centralManagerDidUpdateState(central: CBCentralManager) {
        switch(central.state){
        case CBCentralManagerState.PoweredOn:
            self.onReady(true)
            break
        case CBCentralManagerState.PoweredOff:
            self.onReady(false)
            break
        case CBCentralManagerState.Unauthorized:
            log("Unauthorized state")
            break
        case CBCentralManagerState.Resetting:
            log("Resetting state")
            break
        case CBCentralManagerState.Unknown:
            log("unknown state")
            break
        case CBCentralManagerState.Unsupported:
            log("Unsupported state")
            break
        }
    }
    
    @IBAction func onScan(sender: UIButton) {
        centralManager.scanForPeripheralsWithServices(nil, options: nil)
        log("Scanning")
    }
    func centralManager(central: CBCentralManager, didDiscoverPeripheral peripheral: CBPeripheral, advertisementData: [String : AnyObject], RSSI: NSNumber) {
        let nameOfDeviceFound = (advertisementData as NSDictionary).objectForKey(CBAdvertisementDataLocalNameKey) as! NSString
        if peripheral.name == nameOfDeviceFound{
            log("\(nameOfDeviceFound) Match")
            centralManager.stopScan()
            let i = peripheral.name
            log("Stop scanning after \(i) device found")
            self.peripheral = peripheral
            self.peripheral.delegate = self
            self.buttonConnect.enabled = true
            centralManager.connectPeripheral(peripheral, options: nil)
            print("Try to connect")
        }
    }
    
    
    @IBAction func onConnect(sender: UIButton) {
        if(sender.selected){
            centralManager.cancelPeripheralConnection(peripheral)
            sender.selected=false
            sender.setTitle("Connect", forState: UIControlState.Normal)
            showControl(false)
        }else{
            centralManager.connectPeripheral(peripheral, options: nil)
            log("connecting")
        }
    }
    
    func centralManager(central: CBCentralManager, didConnectPeripheral peripheral: CBPeripheral) {
        log("Peripheral connected")
        self.buttonConnect.selected = true
        self.buttonConnect.setTitle("Disconnect", forState: UIControlState.Normal)
        onDiscover()
    }
    
    func onDiscover() {
        peripheral.discoverServices(nil)
    }
    func peripheral(peripheral: CBPeripheral, didDiscoverServices error: NSError?) {
        log("Discovering services & characteristics")
        for service in peripheral.services! {
            if(service.UUID.UUIDString == "1234"){
                self.service = service
            }
            log("found service: \(service.UUID)")
            peripheral.discoverCharacteristics(nil, forService: service)
        }
    }
    func peripheral(peripheral: CBPeripheral, didDiscoverCharacteristicsForService service: CBService, error: NSError?) {
        for characteristic in service.characteristics! {
            if(characteristic.UUID.UUIDString == "1235"){
                self.writeCharacteristic = characteristic
            }
            if(characteristic.UUID.UUIDString == "1236"){
                self.notificationCharacteristic = characteristic
                setNotification(true)
            }
            log("found characteristic: \(characteristic.UUID)")
        }
        log("Connection ready")
            showControl(true)
    }
    
    func showControl(val: Bool){
        if(!val){
            buttonStart.selected = false
            buttonLock.selected = false
            buttonUnlock.selected = false
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
        let data = NSData(bytes: [0x30] as [UInt8], length: 1)
        peripheral.writeValue(data, forCharacteristic: writeCharacteristic, type: .WithResponse)
    }
    
    @IBAction func onUnlock(sender: UIButton) {
        let data = NSData(bytes: [0x31] as [UInt8], length: 1)
        peripheral.writeValue(data, forCharacteristic: writeCharacteristic, type: .WithResponse)
    }
    
    @IBAction func onStartStop(sender: UIButton) {
        if sender.selected {
            onStopEngine()
        }else{
            onStartEngine()
        }
    }
    
    func onStartEngine() {
        let data = NSData(bytes: [0x32] as [UInt8], length: 1)
        peripheral.writeValue(data, forCharacteristic: writeCharacteristic, type: .WithResponse)
    }
    
    func onStopEngine() {
        let data = NSData(bytes: [0x33] as [UInt8], length: 1)
        peripheral.writeValue(data, forCharacteristic: writeCharacteristic, type: .WithResponse)
    }
    
    func setNotification(enabled: Bool){
        peripheral.setNotifyValue(enabled, forCharacteristic: notificationCharacteristic)
    }
    
    func peripheral(peripheral: CBPeripheral, didUpdateValueForCharacteristic characteristic: CBCharacteristic, error: NSError?) {
        let val = characteristic.value?.hexString
        if(val=="00008001"){
            //ack for locked
            buttonLock.selected = true
            buttonUnlock.selected = false
            AudioServicesPlayAlertSound(UInt32(kSystemSoundID_Vibrate))
        }else if(val=="00000002"){
            //ack for unlocked
            buttonLock.selected = false
            buttonUnlock.selected = true
            AudioServicesPlayAlertSound(SystemSoundID(kSystemSoundID_Vibrate))
        }else if(val=="00000201"){
            //ack for started
            buttonStart.selected = true
            buttonStart.setTitle("Stop", forState: UIControlState.Normal)
        }else if(val=="00000001"){
            //ack for stopped
            buttonStart.selected = false
            buttonStart.setTitle("Start", forState: UIControlState.Normal)
        }else if(val=="0240000f"){
            //ack for locked
            buttonStart.selected = false
            buttonStart.setTitle("Start", forState: UIControlState.Normal)
        }
        log("Charateristic's value has updated : \(val!)")
    }
    
    func centralManager(central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: NSError?) {
        log("Disconnected")
        central.scanForPeripheralsWithServices(nil, options: nil)
    }
    @IBAction func onBack(sender: UIButton) {
        centralManager.cancelPeripheralConnection(peripheral)
    }
}

