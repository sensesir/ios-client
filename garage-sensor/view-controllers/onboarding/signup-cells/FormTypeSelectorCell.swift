//
//  FormTypeSelectorCell.swift
//  garage-sensor
//
//  Created by Josh Perry on 2019/05/29.
//  Copyright © 2019 IoT South Africa. All rights reserved.
//

import Foundation
import UIKit

class FormTypeSelectorCell: UITableViewCell {
    // Class props
    @IBOutlet var signUpButton: UIButton!
    @IBOutlet var loginButton: UIButton!
    @IBOutlet var signUpUnderline: UIView!
    @IBOutlet var loginUnderline: UIView!
    
    override func awakeFromNib() {
        loginUnderline.isHidden = true
    }
}
