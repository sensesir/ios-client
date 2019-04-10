//
//  InfoTextCell.swift
//  garage-sensor
//
//  Created by Josh Perry on 2018/04/09.
//  Copyright © 2018 IoT South Africa. All rights reserved.
//

import Foundation
import UIKit

class InfoTextCell: UITableViewCell {
    // Class props
    @IBOutlet var userInfo: UILabel!
    @IBOutlet var submitButton: UIButton!
    
    override func awakeFromNib() {
        // UI Inits
        userInfo.isHidden = true
        submitButton.isHidden = true
    }
    
    override func layoutSubviews() {
        // Round the button corners
        submitButton.layer.cornerRadius = submitButton.frame.height/2
    }
}
