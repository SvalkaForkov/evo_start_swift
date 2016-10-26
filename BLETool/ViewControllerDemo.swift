//
//  ViewControllerDemo.swift
//  BLETool
//
//  Created by Xiaotu Zhang on 2016-10-26.
//  Copyright © 2016 fortin. All rights reserved.
//

import UIKit
import AudioToolbox

class ViewControllerDemo: UIViewController {
    
    @IBOutlet var stateView: UIView!
    @IBOutlet var controlView: UIView!
    @IBOutlet var leftView: UIView!
    @IBOutlet var rightView: UIView!
    @IBOutlet var topView: UIStackView!
    @IBOutlet var slideUpView: UIView!
    @IBOutlet var timerView: UIView!
    @IBOutlet var buttonGPS: UIButton!
    @IBOutlet var buttonMore: UIButton!
    @IBOutlet var buttonLock: UIButton!
    @IBOutlet var buttonUnlock: UIButton!
    @IBOutlet var button: UIButton!
    
    @IBOutlet var imageViewTrunk: UIImageView!
    @IBOutlet var imageViewHood: UIImageView!
    @IBOutlet var imageViewDoor: UIImageView!
    @IBOutlet var needleBatt: UIImageView!
    @IBOutlet var needleGas: UIImageView!
    @IBOutlet var needleTemp: UIImageView!
    @IBOutlet var needleRPM: UIImageView!
    
    @IBOutlet var buttonGarage: UIButton!
    @IBOutlet var buttonExitDemo: UIButton!
    @IBOutlet var buttonValet: UIButton!
    @IBOutlet var labelCountDown: UILabel!
    
    @IBOutlet var imageHourGlass: UIImageView!
    @IBOutlet var imageStart: UIImageView!
    @IBOutlet var imageGlowing: UIImageView!
    @IBOutlet var imageCap: UIImageView!
    @IBOutlet var labelMessage: UILabel!
    var started = false
    var isPanelDispalyed = false
    var currentAngleTemp : CGFloat = 0
    let defaultCountdown = 90
    var countdown = 90
    var timer : NSTimer?
    
    var isTimerRunning = false
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Control/Demo"
    }
    
    override func viewDidAppear(animated: Bool) {
        buttonMore.clipsToBounds = true
        setAnchorPoint(CGPoint(x: 0.5, y: 0.0), forView: self.imageCap)
        setAnchorPoint(CGPoint(x: 0.5, y: 0.0), forView: self.imageStart)
        setAnchorPoint(CGPoint(x: 0.5, y: 0.0), forView: self.imageGlowing)
        needleBatt.transform = CGAffineTransformMakeRotation(CGFloat(M_PI) * getBattAngle(0) / 180)
        needleRPM.transform = CGAffineTransformMakeRotation(CGFloat(M_PI) * getRPMAngle(0) / 180)
        needleGas.transform = CGAffineTransformMakeRotation(CGFloat(M_PI) * getGasAngle(0) / 180)
        needleTemp.transform = CGAffineTransformMakeRotation(CGFloat(M_PI) * getTempAngle(-40) / 180)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func displayMessage(line: String){
        self.labelMessage.text = line
    }
    
    func setAnchorPoint(anchorPoint: CGPoint, forView view: UIView) {
        print("Set anchor : \(view.layer.position)")
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
    
    func rotateNeedle(view:UIView, angle: CGFloat){
        print("Rotate UIView angle by :\(angle)")
        UIView.animateWithDuration(1.5, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0, options: UIViewAnimationOptions.CurveEaseIn, animations: {
            view.transform = CGAffineTransformMakeRotation(CGFloat(M_PI) * angle / 180)
            }, completion: nil)
    }
    
    func getBattAngle(percentage: CGFloat) -> CGFloat{
        return 313 - percentage/10*12.5
    }
    
    func getGasAngle(percentage: CGFloat) -> CGFloat{
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
    
    func updateUIGas(percentage : CGFloat){
        rotateNeedle(needleGas, angle: getGasAngle(percentage))
    }
    
    func updateUITemperature(temperature: Int){
        print("Update temperature: \(temperature)º")
        let temp = CGFloat(temperature)
        print("currentAngleTemp=\(currentAngleTemp)")
        rotateNeedle(needleTemp, angle: getTempAngle(temp)/2-currentAngleTemp)
        rotateNeedle(needleTemp, angle: getTempAngle(temp))
        currentAngleTemp = getTempAngle(temp)
    }
    
    func showTrunkReleased(){
        if isPanelDispalyed {
            isPanelDispalyed = false
            UIView.animateWithDuration(0.3, animations: {
                self.buttonLock.alpha = 1
                self.buttonUnlock.alpha = 1
                self.slideUpView.alpha = 0
                self.slideUpView.center.y = self.slideUpView.center.y + self.slideUpView.bounds.height
                let transform = CGAffineTransformIdentity
                self.buttonMore.transform = transform
                }, completion: { finished in
                    self.buttonExitDemo.setImage(UIImage(named: "ButtonTrunkReleased"), forState: .Normal)
                    self.displayMessage("Trunk released")
            })
        }else{
            buttonExitDemo.setImage(UIImage(named: "ButtonTrunkReleased"), forState: .Normal)
            displayMessage("Trunk released")
        }
        AudioServicesPlayAlertSound(UInt32(kSystemSoundID_Vibrate))
    }
    
    func showStopped(){
        if isPanelDispalyed {
            isPanelDispalyed = false
            UIView.animateWithDuration(0.3, animations: {
                self.buttonLock.alpha = 1
                self.buttonUnlock.alpha = 1
                self.slideUpView.alpha = 0
                self.slideUpView.center.y = self.slideUpView.center.y + self.slideUpView.bounds.height
                let transform = CGAffineTransformIdentity
                self.buttonMore.transform = transform
                }, completion: { finished in
                    self.updateUIRPM(0)
                    self.updateUIBattery(0)
                    self.updateUIGas(0)
            })
        }else{
            updateUIRPM(0)
            updateUIBattery(0)
            updateUIGas(0)
        }
        AudioServicesPlayAlertSound(UInt32(kSystemSoundID_Vibrate))
        
        if timer != nil {
            stopTimer()
        }
        
    }
    func showStarted(){
        if isPanelDispalyed {
            isPanelDispalyed = false
            UIView.animateWithDuration(0.3, animations: {
                self.buttonLock.alpha = 1
                self.buttonUnlock.alpha = 1
                self.slideUpView.alpha = 0
                self.slideUpView.center.y = self.slideUpView.center.y + self.slideUpView.bounds.height
                let transform = CGAffineTransformIdentity
                self.buttonMore.transform = transform
                }, completion: { finished in
                    self.updateUIRPM(1100)
                    self.updateUIBattery(95)
                    self.updateUIGas(50)
                    self.updateUITemperature(40)
            })
        }else{
            updateUIRPM(1100)
            updateUIBattery(95)
            updateUIGas(50)
            updateUITemperature(40)
        }
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
    
    func reSyncTimer(seconds: Int){
        countdown = seconds
    }
    
    func resetNotification(countdown: Int){
        print("Reset notification")
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
            updateUIGas(0)
        }
    }
    
    func showUnlocked(){
        print("Show door unlocked")
        if isPanelDispalyed {
            isPanelDispalyed = false
            UIView.animateWithDuration(0.3, animations: {
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
        
        displayMessage("Door unlocked")
        AudioServicesPlayAlertSound(UInt32(kSystemSoundID_Vibrate))
        
    }
    func showLocked(){
        print("Show door locked")
        if isPanelDispalyed {
            isPanelDispalyed = false
            UIView.animateWithDuration(0.3, animations: {
                self.buttonLock.alpha = 1
                self.buttonUnlock.alpha = 1
                self.slideUpView.alpha = 0
                self.slideUpView.center.y = self.slideUpView.center.y + self.slideUpView.bounds.height
                let transform = CGAffineTransformIdentity
                self.buttonMore.transform = transform
                self.imageViewDoor.image = nil
                }, completion: { finished in
                    self.buttonLock.setImage(UIImage(named: "ButtonLockOn"), forState: .Normal)
                    self.buttonUnlock.setImage(UIImage(named: "ButtonUnlockOff"), forState: .Normal)
            })
        }else{
            buttonLock.setImage(UIImage(named: "ButtonLockOn"), forState: .Normal)
            buttonUnlock.setImage(UIImage(named: "ButtonUnlockOff"), forState: .Normal)
        }
        displayMessage("Door locked")
        AudioServicesPlayAlertSound(UInt32(kSystemSoundID_Vibrate))
        
    }
    func showValetOn(){
        if isPanelDispalyed {
            isPanelDispalyed = false
            UIView.animateWithDuration(0.3, animations: {
                self.buttonLock.alpha = 1
                self.buttonUnlock.alpha = 1
                self.slideUpView.alpha = 0
                self.slideUpView.center.y = self.slideUpView.center.y + self.slideUpView.bounds.height
                let transform = CGAffineTransformIdentity
                self.buttonMore.transform = transform
                }, completion: { finished in
                    self.displayMessage("valet on")
            })
        }else{
            displayMessage("valet on")
        }
    }
    
    func showValetOff(){
        if isPanelDispalyed {
            isPanelDispalyed = false
            UIView.animateWithDuration(0.3, animations: {
                self.buttonLock.alpha = 1
                self.buttonUnlock.alpha = 1
                self.slideUpView.alpha = 0
                self.slideUpView.center.y = self.slideUpView.center.y + self.slideUpView.bounds.height
                let transform = CGAffineTransformIdentity
                self.buttonMore.transform = transform
                }, completion: { finished in
                    self.displayMessage("valet off")
            })
        }else{
            displayMessage("valet off")
        }
    }
}



