//
//  YearViewController.swift
//  BLETool
//
//  Created by Xiaotu Zhang on 2016-09-13.
//  Copyright © 2016 fortin. All rights reserved.
//

import UIKit

class YearViewController: UIViewController , UIPickerViewDelegate, UIPickerViewDataSource{
    
    @IBOutlet var buttonDone: UIButton!
    @IBOutlet var yearPicker: UIPickerView!
    weak var registerViewController : RegisterViewController?
    let data : [NSDecimalNumber] = [2017,2016,2015,2014,2013,2012,2011,2010,2009,2008,2007,2006,2005,2004,2003,2002,2001,2000,1999,1998,1997,1996,1995]
    var selectedYear : NSDecimalNumber?
    var lastChoice : Int! = 0
    override func viewDidLoad() {
        super.viewDidLoad()
        yearPicker.dataSource = self
        yearPicker.delegate = self
        // Do any additional setup after loading the view.
    }
    override func viewDidAppear(animated: Bool) {
        if lastChoice != 0 {
            yearPicker.selectRow(lastChoice!, inComponent: 0, animated: false)
            selectedYear = data[lastChoice]
            buttonDone.hidden = false
        }else{
            yearPicker.selectRow(0, inComponent: 0, animated: false)
            selectedYear = data[0]
            buttonDone.hidden = false
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func numberOfComponentsInPickerView(pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return data.count
    }
    
    func pickerView(pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return data[row].stringValue
    }
    
    func pickerView(pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        selectedYear = data[row]
        lastChoice = row
        buttonDone.hidden = false
    }
    
    @IBAction func onDone(sender: UIButton) {
        registerViewController?.buttonSelectYear.setTitle(selectedYear!.stringValue, forState: .Normal)
        registerViewController?.indexForYear = lastChoice
        self.navigationController?.popViewControllerAnimated(true)
    }
    
}
