//
//  CustomMessageCell.swift
//  BLETool
//
//  Created by Xiaotu Zhang on 2016-08-23.
//  Copyright © 2016 fortin. All rights reserved.
//

import UIKit

class CustomMessageCell: UITableViewCell {

    @IBOutlet var labelBackground: UIView!
    @IBOutlet var button: UIButton!
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
