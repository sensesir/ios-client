//
//  LocalWiFiConnectVC.swift
//  garage-sensor
//
//  Created by Josh Perry on 2019/06/10.
//  Copyright © 2019 IoT South Africa. All rights reserved.
//

import Foundation
import UIKit

class LocalWiFiConnectVC: UIViewController {
    let env = DevEnv()
    var ssidTimer: Timer?
    
    override func viewWillAppear(_ animated: Bool) {
        let correctNetwork = pollNetworkSSID()
        if (!correctNetwork) {
            ssidTimer = Timer.scheduledTimer(timeInterval: 5, target: self, selector: #selector(pollNetworkSSID), userInfo: nil, repeats: true)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        ssidTimer?.invalidate()
    }
    
    @objc func pollNetworkSSID() -> Bool {
        let updatedName = SSID.fetchSSIDInfo()
        
        // || For dev only
        if (updatedName == env.SENSOR_AP_SSID) {
            print("WIFI CONNECT: User connected to correct network")
            self.ssidTimer?.invalidate()
            DispatchQueue.main.async { self.transitionToSensorInitializatio() }
            return true
        }
                
        return false
    }
    
    // MARK: - Transitions -
    
    func transitionToSensorInitializatio() {
        performSegue(withIdentifier: "InitializeSensorSegue", sender: nil)
    }
    
    @IBAction func unwindFromInitSensor(for unwindSegue: UIStoryboardSegue, towardsViewController subsequentVC: UIViewController) {
        print("WIFI CONNECT VC: Unwound from sensor initialization VC")
    }
}
