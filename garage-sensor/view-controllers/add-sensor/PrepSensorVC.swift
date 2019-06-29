//
//  PrepSensorVC.swift
//  garage-sensor
//
//  Created by Josh Perry on 2019/06/10.
//  Copyright © 2019 IoT South Africa. All rights reserved.
//

import Foundation
import UIKit

class PrepSensorVC: UIViewController {
    @IBOutlet var proceedButton: UIButton!
    
    override func viewDidLoad() {
        proceedButton.layer.cornerRadius = proceedButton.frame.height/2
    }
    
    @IBAction func unwindFromWiFiConnect(for unwindSegue: UIStoryboardSegue, towardsViewController subsequentVC: UIViewController) {
        print("PREP SENSOR VC: Unwound from wifi connect VC")
    }
}
