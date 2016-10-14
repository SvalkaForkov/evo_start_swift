//
//  ModelViewController.swift
//  BLETool
//
//  Created by Xiaotu Zhang on 2016-09-13.
//  Copyright © 2016 fortin. All rights reserved.
//

import UIKit

class ModelViewController: UIViewController ,UITableViewDataSource, UITableViewDelegate{

    var make : Make?
    var dataController : DataController?
    var models : [Model]?
    var lastChoice : Int! = 0
    weak var registerViewController : RegisterViewController?
    
    @IBOutlet var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    override func viewWillAppear(animated: Bool) {
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        dataController = appDelegate.dataController
        print("current make : \(make?.title)")
        tableView.dataSource = self
        tableView.delegate = self
        models = dataController?.fetchModelsForMake(make!)
        print("fecth models count \(models?.count)")
    }
    
    override func viewDidAppear(animated: Bool) {
        if models?.count != 0 {
        let index = lastChoice as Int
        tableView.scrollToRowAtIndexPath(NSIndexPath(forRow: index, inSection: 0), atScrollPosition: .Top, animated: true)
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return models!.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("ModelCell", forIndexPath: indexPath)
        cell.textLabel!.text = models![indexPath.row].title
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        registerViewController?.buttonSelectModel.setTitle(models![indexPath.row].title, forState: .Normal)
        registerViewController?.indexForModel = indexPath.row
        tableView.deselectRowAtIndexPath(indexPath, animated: false)
        self.navigationController?.popViewControllerAnimated(true)
    }

    
    
}
