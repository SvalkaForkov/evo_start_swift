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
    @IBOutlet var buttonUnlock: UIButton!
    @IBOutlet var buttonLock: UIButton!
    @IBOutlet var buttonStart: UIButton!
    
    @IBOutlet var buttonStop: UIButton!
    @IBOutlet var textViewSent: UITextView!
    @IBOutlet var textViewACK: UITextView!
    @IBOutlet var stackView: UIStackView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("did load view controller")
        print("name is \(name)")
        textViewSent.text = ""
        textViewACK.text = ""
        centralManager = CBCentralManager(delegate: self, queue:nil)
    }
    
//    override func viewWillAppear(animated: Bool) {
//        super.viewWillAppear(animated)
//        buttonUnlock.center.x = 50
//        buttonLock.center.x = view.bounds.width
//        buttonStart.center.x 	= view.bounds.width  }
//    
//    override func viewDidAppear(animated: Bool) {
//        super.viewDidAppear(animated)
//        UIView.animateWithDuration(0.5, animations: {
//            self.buttonUnlock.center.x = self.view.bounds.width/2
//            self.buttonLock.center.x -= self.view.bounds.width
//            self.buttonStart.center.x += self.view.bounds.width
//        })
//    }
    
//    override func viewDidAppear(animated: Bool) {
//        super.viewDidAppear(animated)
//        UIView.animateWithDuration(0.5, delay: 0.0, options: UIViewAnimationOptions.CurveEaseOut, animations: {
//            self.buttonLock.constant += self.view.bounds.width
//            self.view.layoutIfNeeded()
//            }, completion: nil)
//    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func centralManagerDidUpdateState(central: CBCentralManager) {
        switch(central.state){
        case CBCentralManagerState.PoweredOn:
            print("Ble ready")
            centralManager.scanForPeripheralsWithServices(nil, options: nil)
            print("Scanning")
            break
        case CBCentralManagerState.PoweredOff:
            print("Ble not ready")
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
            print("and name is \(name)")
            if nameOfDeviceFound == name{
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
        peripheral.discoverServices(nil)
    }
    
    func peripheral(peripheral: CBPeripheral, didDiscoverServices error: NSError?) {
        print("Discovered service")
        for service in peripheral.services! {
            if(service.UUID.UUIDString == "1234"){
                self.service = service
            }
            print("Found service: \(service.UUID)")
            peripheral.discoverCharacteristics(nil, forService: service)
        }
    }
    
    func peripheral(peripheral: CBPeripheral, didDiscoverCharacteristicsForService service: CBService, error: NSError?) {
        print("Discovered characteristic")
        for characteristic in service.characteristics! {
            if(characteristic.UUID.UUIDString == "1235"){
                self.writeCharacteristic = characteristic
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
        count = 0
        receivedLock = false
        textViewACK.text = ""
        textViewSent.text = ""
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
            self.peripheral.writeValue(data, forCharacteristic: self.writeCharacteristic, type: .WithResponse)
            dispatch_async(dispatch_get_main_queue(),{
                self.textViewSent.text = self.textViewSent.text.stringByAppendingString("\nSend : 1")
            })
            sleep(1)
            if self.receivedLock {
                return
            }
            self.peripheral.writeValue(data, forCharacteristic: self.writeCharacteristic, type: .WithResponse)
            dispatch_async(dispatch_get_main_queue(),{
                self.textViewSent.text = self.textViewSent.text.stringByAppendingString("\nSend : 2")
            })
            sleep(1)
            if self.receivedLock {
                return
            }
            self.peripheral.writeValue(data, forCharacteristic: self.writeCharacteristic, type: .WithResponse)
            dispatch_async(dispatch_get_main_queue(),{
                self.textViewSent.text = self.textViewSent.text.stringByAppendingString("\nSend : 3")
            })
            sleep(1)
            if self.receivedLock {
                return
            }
            self.peripheral.writeValue(data, forCharacteristic: self.writeCharacteristic, type: .WithResponse)
            dispatch_async(dispatch_get_main_queue(),{
                self.textViewSent.text = self.textViewSent.text.stringByAppendingString("\nSend : 4")
            })
            sleep(1)
            if self.receivedLock {
                return
            }
            self.peripheral.writeValue(data, forCharacteristic: self.writeCharacteristic, type: .WithResponse)
            dispatch_async(dispatch_get_main_queue(),{
                self.textViewSent.text = self.textViewSent.text.stringByAppendingString("\nSend : 5")
            })
        })
    }
    
    @IBAction func onUnlock(sender: UIButton) {
        print("onUnlock")
        let data = NSData(bytes: [0x31] as [UInt8], length: 1)
        count = 0
        receivedUnlock = false
        textViewACK.text = ""
        textViewSent.text = ""
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
            self.peripheral.writeValue(data, forCharacteristic: self.writeCharacteristic, type: .WithResponse)
            dispatch_async(dispatch_get_main_queue(),{
                self.textViewSent.text = self.textViewSent.text.stringByAppendingString("\nSend : 1")
            })
            sleep(1)
            if self.receivedUnlock {
                return
            }
            self.peripheral.writeValue(data, forCharacteristic: self.writeCharacteristic, type: .WithResponse)
            dispatch_async(dispatch_get_main_queue(),{
                self.textViewSent.text = self.textViewSent.text.stringByAppendingString("\nSend : 2")
            })
            sleep(1)
            if self.receivedUnlock {
                return
            }
            self.peripheral.writeValue(data, forCharacteristic: self.writeCharacteristic, type: .WithResponse)
            dispatch_async(dispatch_get_main_queue(),{
                self.textViewSent.text = self.textViewSent.text.stringByAppendingString("\nSend : 3")
            })
            sleep(1)
            if self.receivedUnlock {
                return
            }
            self.peripheral.writeValue(data, forCharacteristic: self.writeCharacteristic, type: .WithResponse)
            dispatch_async(dispatch_get_main_queue(),{
                self.textViewSent.text = self.textViewSent.text.stringByAppendingString("\nSend : 4")
            })
            sleep(1)
            if self.receivedUnlock {
                return
            }
            self.peripheral.writeValue(data, forCharacteristic: self.writeCharacteristic, type: .WithResponse)
            dispatch_async(dispatch_get_main_queue(),{
                self.textViewSent.text = self.textViewSent.text.stringByAppendingString("\nSend : 5")
            })
        })
    }
    
    
    @IBAction func onStart(sender: UIButton) {
        count = 0
        onStartEngine()
    }
    
    @IBAction func onStop(sender: UIButton) {
        count = 0
        onStopEngine()
    }
    func onStartEngine() {
        print("on start")
        let data = NSData(bytes: [0x32] as [UInt8], length: 1)
        receivedStart = false
        textViewACK.text = ""
        textViewSent.text = ""
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
            self.peripheral.writeValue(data, forCharacteristic: self.writeCharacteristic, type: .WithResponse)
            dispatch_async(dispatch_get_main_queue(),{
                self.textViewSent.text = self.textViewSent.text.stringByAppendingString("\nSend : 1")
            })
            sleep(1)
            if self.receivedStart {
                return
            }
            self.peripheral.writeValue(data, forCharacteristic: self.writeCharacteristic, type: .WithResponse)
            dispatch_async(dispatch_get_main_queue(),{
                self.textViewSent.text = self.textViewSent.text.stringByAppendingString("\nSend : 2")
            })
            sleep(1)
            if self.receivedStart {
                return
            }
            self.peripheral.writeValue(data, forCharacteristic: self.writeCharacteristic, type: .WithResponse)
            dispatch_async(dispatch_get_main_queue(),{
                self.textViewSent.text = self.textViewSent.text.stringByAppendingString("\nSend : 3")
            })
            sleep(1)
            if self.receivedStart {
                return
            }
            self.peripheral.writeValue(data, forCharacteristic: self.writeCharacteristic, type: .WithResponse)
            dispatch_async(dispatch_get_main_queue(),{
                self.textViewSent.text = self.textViewSent.text.stringByAppendingString("\nSend : 4")
            })
            sleep(1)
            if self.receivedStart {
                return
            }
            self.peripheral.writeValue(data, forCharacteristic: self.writeCharacteristic, type: .WithResponse)
            dispatch_async(dispatch_get_main_queue(),{
                self.textViewSent.text = self.textViewSent.text.stringByAppendingString("\nSend : 5")
            })
            self.started = true
            self.receivedStart = true
        })
    }
    
    func onStopEngine() {
        print("on stop")
        let data = NSData(bytes: [0x33] as [UInt8], length: 1)
        receivedStop = false
        textViewACK.text = ""
        textViewSent.text = ""
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
            self.peripheral.writeValue(data, forCharacteristic: self.writeCharacteristic, type: .WithResponse)
            dispatch_async(dispatch_get_main_queue(),{
                self.textViewSent.text = self.textViewSent.text.stringByAppendingString("\nSend : 1")
            })
            sleep(1)
            if self.receivedStop {
                return
            }
            self.peripheral.writeValue(data, forCharacteristic: self.writeCharacteristic, type: .WithResponse)
            dispatch_async(dispatch_get_main_queue(),{
                self.textViewSent.text = self.textViewSent.text.stringByAppendingString("\nSend : 2")
            })
            sleep(1)
            if self.receivedStop {
                return
            }
            self.peripheral.writeValue(data, forCharacteristic: self.writeCharacteristic, type: .WithResponse)
            dispatch_async(dispatch_get_main_queue(),{
                self.textViewSent.text = self.textViewSent.text.stringByAppendingString("\nSend : 3")
            })
            sleep(1)
            if self.receivedStop {
                return
            }
            self.peripheral.writeValue(data, forCharacteristic: self.writeCharacteristic, type: .WithResponse)
            dispatch_async(dispatch_get_main_queue(),{
                self.textViewSent.text = self.textViewSent.text.stringByAppendingString("\nSend : 4")
            })
            sleep(1)
            if self.receivedStop {
                return
            }
            self.peripheral.writeValue(data, forCharacteristic: self.writeCharacteristic, type: .WithResponse)
            dispatch_async(dispatch_get_main_queue(),{
                self.textViewSent.text = self.textViewSent.text.stringByAppendingString("\nSend : 5")
            })
            self.started = false
            self.receivedStop = true
        })
    }
    
    func setNotification(enabled: Bool){
        peripheral.setNotifyValue(enabled, forCharacteristic: notificationCharacteristic)
    }
    
    func peripheral(peripheral: CBPeripheral, didUpdateValueForCharacteristic characteristic: CBCharacteristic, error: NSError?) {
        let val = characteristic.value!.hexString
        if(val=="00008001"){
            //ack for locked
            textViewACK.text = textViewACK.text.stringByAppendingString("\n\(val) : \(count)")
            count = count + 1
            receivedLock = true
            AudioServicesPlayAlertSound(UInt32(kSystemSoundID_Vibrate))
        }else if(val=="00000002"){
            //ack for unlocked
            textViewACK.text = textViewACK.text.stringByAppendingString("\n\(val) : \(count)")
            count = count + 1
            receivedUnlock = true
            AudioServicesPlayAlertSound(SystemSoundID(kSystemSoundID_Vibrate))
        }else if(val=="00000201"){
            //ack for started
            started = true
            textViewACK.text = textViewACK.text.stringByAppendingString("\n\(val) : \(count)")
            count = count + 1
            receivedStart = true
        }else if(val=="00000001"){
            started = false
            //ack for stopped
            textViewACK.text = textViewACK.text.stringByAppendingString("\n\(val) : \(count)")
            count = count + 1
            receivedStop = true
        }else if(val=="0240000f"){
            //ack for locked
            buttonStart.selected = false
            buttonStart.setTitle("Start", forState: UIControlState.Normal)
        }else{
            textViewACK.text = textViewACK.text.stringByAppendingString("\n\(val) : \(count)")
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

