//
//  TransientStateVC.swift
//  garage-sensor
//
//  Created by Josh Perry on 2018/04/10.
//  Copyright © 2018 IoT South Africa. All rights reserved.
//

import UIKit

class TransientStateVC: UIViewController {
    // Constants
    let doorStateLabelLookUp = [0: "Sending",
                                1: "Sending",
                                2: "Connecting"]
    
    // Outlets
    @IBOutlet var circleContainer: UIView!
    @IBOutlet var stateTitle: UILabel!
    @IBOutlet var wifiLogo: UIImageView!
    
    // MARK: - Initializations -
    override func viewDidLoad() {
        // Hide the tabbar
        self.tabBarController?.tabBar.isHidden = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        // Check the state of the door model and update UI accordingly
        setUIForTransientState()
        
        // Start animation
        pulseWifiLogo()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        // Stop animation
        wifiLogo.layer.removeAllAnimations()
    }
    
    override func viewDidLayoutSubviews() {
        // Geometric inits
        circleContainer.layer.cornerRadius = circleContainer.frame.height/2
    }
    
    // MARK: - UI Styling -
    
    func setUIForTransientState() {
        // Assess the door model and set UI accordingly
        stateTitle.text = doorStateLabelLookUp[GDoorModel.main.doorState]
    }
    
    // MARK: - Animation -
    
    func pulseWifiLogo() {
        let wifiPulseEffect = CABasicAnimation.init(keyPath: "opacity")
        
        // Configure
        wifiPulseEffect.duration = 1.5
        wifiPulseEffect.repeatCount = 10000
        wifiPulseEffect.autoreverses = true
        wifiPulseEffect.fromValue = 0
        wifiPulseEffect.toValue = 1
        
        print("TRANSIENT STATE VC: Starting pulsating effet")
        wifiLogo.layer.add(wifiPulseEffect, forKey: "opacityAnimation")
    }
}
