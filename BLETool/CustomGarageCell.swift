//
//  CustomCell.swift
//  BLETool
//
//  Created by Xiaotu Zhang on 2016-06-20.
//  Copyright © 2016 fortin. All rights reserved.
//

import UIKit

class CustomGarageCell: UITableViewCell {

    @IBOutlet var labelModel: UILabel!
    @IBOutlet var labelMake: UILabel!
    @IBOutlet var labelName: UILabel!
    
    @IBOutlet var mainView: UIView!
    var dataController : DataController!
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        dataController = appDelegate.dataController
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        // Configure the view for the selected state
    }
}
