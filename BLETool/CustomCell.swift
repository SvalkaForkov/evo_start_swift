//
//  CustomCell.swift
//  BLETool
//
//  Created by Xiaotu Zhang on 2016-06-20.
//  Copyright © 2016 fortin. All rights reserved.
//

import UIKit

class CustomCell: UITableViewCell {

    @IBOutlet var label1: UILabel!
    @IBOutlet var label2: UILabel!
    @IBOutlet var label3: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        // Configure the view for the selected state
    }

}
