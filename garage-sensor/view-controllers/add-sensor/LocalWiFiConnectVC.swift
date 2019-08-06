//
//  LocalWiFiConnectVC.swift
//  garage-sensor
//
//  Created by Josh Perry on 2019/06/10.
//  Copyright © 2019 IoT South Africa. All rights reserved.
//

import Foundation
import UIKit
import AwaitKit
import Bugsnag

class LocalWiFiConnectVC: UIViewController {
    let env = DevEnv()
    let sensorAPI = GDoorSensorApi()
    
    var delayTimer: Timer?
    var connTimeoutTimer: Timer?
    var pingCounter: Int = 0
    var connectionModalVC: ConnectionModalVC?
    var connectionFailureModal: ModalWithConfirmVC?
    
    override func viewDidLoad() {
        GDoorModel.main.disconnectIoT()
        GDoorUser.sharedInstance.addingSensor = true
        connectToSensor()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        delayTimer?.invalidate()
        connTimeoutTimer?.invalidate()
    }
    
  
    @objc func connectToSensor() {
        if (!correctSSID()) {
            startDelayTimer(delay: 1.0);
            return
        }
        
        // Only perform once in recursive method
        if(connectionModalVC == nil) { showConnectionModal() }
        if(connTimeoutTimer == nil) { startConnTimeoutTimer() }
        
        do {
            print("WIFI CONNECT: Pinging sensor for ack #\(pingCounter + 1)")
            let result = try await(sensorAPI.pingSensor())
            if (result) { pingCounter += 1 }
                
            if (pingCounter > 4) {
                print("WIFI CONNECTION: Successfully connected to Sensor")
                connTimeoutTimer?.invalidate()
                delayTimer?.invalidate()
                DispatchQueue.main.async {
                    self.connectionModalVC?.dismiss(animated: false, completion: nil)
                    self.transitionToSensorInitializatio()
                }
    
                // End function - do not restart connect
                return;
            }
        } catch {
            print("WIFI CONNECT: Failed to ping sensor: \(error)")
            // Reset ping to zero?
        }
        
        print("Temp: restarting delay timer")
        startDelayTimer(delay: 1.0)
    }
    
    @objc func correctSSID() -> Bool {
        let updatedName = SSID.fetchSSIDInfo()
        
        // || For dev only
        if (updatedName == env.SENSOR_AP_SSID) {
            print("WIFI CONNECT: User connected to correct network SSID")
            return true
        }
        
        return false
    }
    
    func showConnectionModal() {
        // Show IFF it isn't already showing
        if (connectionModalVC == nil) {
            let addSensorStory = UIStoryboard(name: "AddSensor", bundle: nil)
            connectionModalVC = addSensorStory.instantiateViewController(withIdentifier: "ConnectionModal") as? ConnectionModalVC
            connectionModalVC?.modalPresentationStyle = .overCurrentContext;
            connectionModalVC?.modalTransitionStyle = .crossDissolve;
            present(connectionModalVC!, animated: true, completion: nil)
        }
    }
    
    // MARK: - Timers -
    
    func startDelayTimer(delay: Float) {
        if (delayTimer != nil) {
            delayTimer!.invalidate()
            delayTimer = nil
        }
        
        if (delayTimer == nil) {
            delayTimer = Timer.scheduledTimer(timeInterval: TimeInterval(delay),
                                              target: self,
                                              selector: #selector(connectToSensor),
                                              userInfo: nil,
                                              repeats: false)
        }
    }
    
    func startConnTimeoutTimer() {
        if (connTimeoutTimer == nil) {
            connTimeoutTimer = Timer.scheduledTimer(timeInterval: 10,
                                                     target: self,
                                                     selector: #selector(connTimeout),
                                                     userInfo: nil,
                                                     repeats: false)
        }
    }
    
    @objc func connTimeout() {
        print("WIFI CONNECT: Conn timeout - failed to connect to sensor stably")
        delayTimer?.invalidate()
        connTimeoutTimer?.invalidate()
        connTimeoutTimer = nil
        
        DispatchQueue.main.async {
            self.connectionModalVC?.dismiss(animated: true, completion: {
                self.connectionModalVC = nil
                let connFailureImage = UIImage.init(named: "door-offline")
                self.connectionFailureModal = ModalWithConfirmVC.initModal(title: "Failed to connect to sensor",
                                                                           descText: "Could not communicate with your sensor, this is because your phone does not have a strong enough connection to it. Please make sure the devices are close together, and there are no objects causing interference nearby (i.e. large pieces of metal).",
                                                                           image: connFailureImage,
                                                                           buttonTitle: "I've connected properly",
                                                                           confirmAction:
                    {
                      // When user clicks affirmative action - code here
                      self.connectToSensor()
                    })
                
                self.present(self.connectionFailureModal!, animated: true, completion: nil)
                Bugsnag.notifyError(NSError(domain:"sensor-conn", code:005, userInfo:["message": "failed to connect to sensor AP"]))
            })
        }
    }
    
    // MARK: - Transitions -
    
    func transitionToSensorInitializatio() {
        if (self.connectionFailureModal != nil) {
            self.connectionFailureModal?.dismiss(animated: false, completion: nil)
        }
        performSegue(withIdentifier: "InitializeSensorSegue", sender: nil)
    }
    
    @IBAction func unwindFromInitSensor(for unwindSegue: UIStoryboardSegue, towardsViewController subsequentVC: UIViewController) {
        print("WIFI CONNECT VC: Unwound from sensor initialization VC")
    }
}
