//
//  MakeViewController.swift
//  BLETool
//
//  Created by Xiaotu Zhang on 2016-09-13.
//  Copyright © 2016 fortin. All rights reserved.
//

import UIKit

class MakeViewController: UIViewController ,UITableViewDataSource, UITableViewDelegate{
    let makes = ["1","2","3"]
    @IBOutlet var tableView: UITableView!
    weak var registerViewController : RegisterViewController?
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.dataSource = self
        tableView.delegate = self

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return makes.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("MakeCell", forIndexPath: indexPath)
        cell.textLabel!.text = makes[indexPath.row]
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        registerViewController?.buttonSelectMake.setTitle(makes[indexPath.row], forState: .Normal)
        tableView.deselectRowAtIndexPath(indexPath, animated: false)
        self.navigationController?.popViewControllerAnimated(true)
    }

}
