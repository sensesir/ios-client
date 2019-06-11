//
//  SensorInitializingVC.swift
//  garage-sensor
//
//  Created by Josh Perry on 2019/06/10.
//  Copyright © 2019 IoT South Africa. All rights reserved.
//

import Foundation
import UIKit

class SensorInitializingVC: UIViewController {
    @IBOutlet var whiteLED: UIView!
    
    
    // MARK: - UI Handling -
    
    func styleUI() {
        whiteLED.layer.cornerRadius = whiteLED.frame.height/2.0
    }
    
    func flashWhiteLED() {
        let pulseEffect = CABasicAnimation.init(keyPath: "opacity")
        
        // Configure
        pulseEffect.duration = 1.5
        pulseEffect.repeatCount = 10000
        pulseEffect.autoreverses = true
        pulseEffect.fromValue = 0
        pulseEffect.toValue = 1
        
        print("SENSOR INIT VC: Starting LED flashing")
        whiteLED.layer.add(pulseEffect, forKey: "opacityAnimation")
    }
    
    func stopFlashingWhiteLED() {
        whiteLED.layer.removeAllAnimations()
    }
}
