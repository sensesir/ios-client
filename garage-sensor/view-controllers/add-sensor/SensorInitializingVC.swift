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
    @IBOutlet var mqttConnArrow: UIImageView!
    
    override func viewDidLoad() {
        styleUI()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        stopPulsingArrow()
        stopFlashingWhiteLED()
    }
    
    override func viewDidLayoutSubviews() {
        whiteLED.layer.cornerRadius = whiteLED.frame.height/2.0
    }
    
    // MARK: - UI Handling -
    
    func styleUI() {
        flashWhiteLED()
        pulseMQTTArrow()
    }
    
    func flashWhiteLED() {
        let pulseEffect = CABasicAnimation.init(keyPath: "opacity")
        
        // Configure
        pulseEffect.duration = 1
        pulseEffect.repeatCount = 10000
        pulseEffect.autoreverses = true
        pulseEffect.fromValue = 0
        pulseEffect.toValue = 1
        
        print("SENSOR INIT VC: Starting LED flashing")
        whiteLED.layer.add(pulseEffect, forKey: "opacityAnimation")
    }
    
    func pulseMQTTArrow() {
        let pulseEffect = CABasicAnimation.init(keyPath: "opacity")
        
        // Configure
        pulseEffect.duration = 1
        pulseEffect.repeatCount = 10000
        pulseEffect.autoreverses = true
        pulseEffect.fromValue = 0
        pulseEffect.toValue = 1
        
        print("SENSOR INIT VC: Starting arrow pulse")
        mqttConnArrow.layer.add(pulseEffect, forKey: "opacityAnimation")
    }
    
    func stopFlashingWhiteLED() {
        whiteLED.layer.removeAllAnimations()
    }
    
    func stopPulsingArrow() {
        mqttConnArrow.layer.removeAllAnimations()
    }
    
    // MARK: - Info Modals -
    
    @IBAction func showWiFiInfoModal() {
        let wifiImage = UIImage.init(named: "door-online")
        if let wifiInfoModal = StandardModalVC.initModal(title: "Sensor WiFi Connection",
                                                        descText: "Your sensor should connect to your home wifi network within ~2mins. If this does not happen, the most likely reason is you made typo when entering the details. To correct this, hold the 'mode' button down on the sensor for 5s, it will reboot, and you should go back to the step where you connected to the sensors network (GarageDoor-jPtF)",
                                                        image: wifiImage!) {
            // Present the VC
            present(wifiInfoModal, animated: true, completion: nil)
        }
    }
    
    @IBAction func showMQTTInfoModal() {
        let wifiImage = UIImage.init(named: "sensor-mqtt-conn")
        if let mqttInfoModal = StandardModalVC.initModal(title: "Sensor Registration",
                                                        descText: "After connecting to your WiFi network, your sensor will attempt to register with our server. This can take up to 5 mins, please be patient. If it continues without success (after 5 mins), this could indicate that your internet connection is not strong enough. You may need to boost the signal in your garage for your sensor to work. Contact SenseSir for more details.",
                                                        image: wifiImage!) {
            // Present the VC
            present(mqttInfoModal, animated: true, completion: nil)
        }
    }
    
}
