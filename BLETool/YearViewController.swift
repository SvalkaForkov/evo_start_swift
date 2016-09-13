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
    let data : [NSDecimalNumber] = [1996,1997,1998,1999,2000,2001,2002,2003,2004,2005,2006,2007,2008,2009,2010,2011,2012,2013,2014,2015,2016]
    var selectedYear : NSDecimalNumber?
    override func viewDidLoad() {
        super.viewDidLoad()
        yearPicker.dataSource = self
        yearPicker.delegate = self
        // Do any additional setup after loading the view.
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
        buttonDone.hidden = false
    }
    
    @IBAction func onDone(sender: UIButton) {
        registerViewController?.buttonSelectYear.setTitle(selectedYear!.stringValue, forState: .Normal)
        self.navigationController?.popViewControllerAnimated(true)
    }
    
}
