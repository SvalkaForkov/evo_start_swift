//
//  MakeViewController.swift
//  BLETool
//
//  Created by Xiaotu Zhang on 2016-09-13.
//  Copyright © 2016 fortin. All rights reserved.
//

import UIKit

class MakeViewController: UIViewController ,UITableViewDataSource, UITableViewDelegate{
    var makes : [Make]?
    @IBOutlet var tableView: UITableView!
    weak var registerViewController : RegisterViewController?
    var lastChoice : Int! = 0
    var dataController : DataController?
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.dataSource = self
        tableView.delegate = self
    }
    
    override func viewWillAppear(animated: Bool) {
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        dataController = appDelegate.dataController
        makes = dataController!.fetchAllMakes()
        tableView.reloadData()
        print("[Make] size : \(makes?.count)")
    }
    
    override func viewDidAppear(animated: Bool) {
        if makes?.count != 0 {
            let index = lastChoice as Int
            tableView.scrollToRowAtIndexPath(NSIndexPath(forRow: index, inSection: 0), atScrollPosition: .Top, animated: true)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return makes!.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("MakeCell", forIndexPath: indexPath)
        let title = makes![indexPath.row].title as String!
        cell.textLabel!.text = title
        cell.imageView?.image = UIImage(named: title)
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let makeTitle = makes![indexPath.row].title
        registerViewController?.buttonSelectMake.setTitle(makeTitle, forState: .Normal)
        let modelTitle = registerViewController?.buttonSelectModel.titleLabel!.text
        if modelTitle != "Select Model" {
            let model = dataController?.fetchModelByTitle(modelTitle!)
            if model?.model2make?.title != makeTitle {
                registerViewController?.buttonSelectModel.setTitle("Select Model", forState: .Normal)
                registerViewController?.indexForModel = 0
            }
        }
        registerViewController?.indexForMake = indexPath.row
        tableView.deselectRowAtIndexPath(indexPath, animated: false)
        self.navigationController?.popViewControllerAnimated(true)
    }

}
