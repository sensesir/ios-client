//
//  ConnectionModalVC.swift
//  garage-sensor
//
//  Created by Josh Perry on 2019/08/02.
//  Copyright © 2019 IoT South Africa. All rights reserved.
//

import UIKit
import QuartzCore

class ConnectionModalVC: UIViewController {
    @IBOutlet var loadSpinner: UIActivityIndicatorView?
    @IBOutlet var modalView: UIView?
    
    override func viewDidLoad() {
        loadSpinner!.transform = CGAffineTransform(scaleX: 2, y: 2)
        modalView?.layer.cornerRadius = 18.0
    }
    
    
}
