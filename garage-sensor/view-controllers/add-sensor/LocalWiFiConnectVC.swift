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
    
    // MARK: - Initialization -
    
    override func viewDidLoad() {
        GDoorUser.sharedInstance.addingSensor = true
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(appEnteringForeground),
                                               name: NSNotification.Name.UIApplicationWillEnterForeground,
                                               object: nil)
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(appEnteringBackground),
                                               name: NSNotification.Name.UIApplicationWillResignActive,
                                               object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        GDoorModel.main.disconnectIoT()
        connectToSensor()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        print("WIFI CONNECT: Exiting wifi connect")
        Bugsnag.leaveBreadcrumb(withMessage: "Exiting wifi connect")
        delayTimer?.invalidate()
        delayTimer = nil
        connTimeoutTimer?.invalidate()
        connTimeoutTimer = nil
    }
    
    // MARK: - App minimization/re-selection -
  
    @objc func appEnteringForeground() {
        // Start connect sensor process again
        Bugsnag.leaveBreadcrumb(withMessage: "App entering forground - proprietary method called")
        print("WIFI CONNECT: App entering forground - proprietary method called")
        connectToSensor()
    }
    
    @objc func appEnteringBackground() {
        // Stop connect sensor process
        Bugsnag.leaveBreadcrumb(withMessage: "App entering background - proprietary method called")
        print("WIFI CONNECT: App entering background - proprietary method called")
        delayTimer?.invalidate()
        delayTimer = nil
        connTimeoutTimer?.invalidate()
        connTimeoutTimer = nil
 
        connectionModalVC?.dismiss(animated: false, completion: {
           self.connectionModalVC = nil
        })
        connectionFailureModal?.dismiss(animated: false, completion: {
            self.connectionFailureModal = nil
        })
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
            Bugsnag.leaveBreadcrumb(withMessage: "Pinging sensor")
            let result = try await(sensorAPI.pingSensor())
            if (result) { pingCounter += 1 }
                
            if (pingCounter > 4) {
                print("WIFI CONNECTION: Successfully connected to Sensor")
                Bugsnag.leaveBreadcrumb(withMessage: "Successfully connected to sensor")
                connTimeoutTimer?.invalidate()
                delayTimer?.invalidate()
                DispatchQueue.main.async {
                    self.connectionModalVC?.dismiss(animated: false, completion: {
                        self.connectionModalVC = nil
                    })
                    self.transitionToSensorInitializatio()
                }
    
                // End function - do not restart connect
                return;
            }
        } catch {
            print("WIFI CONNECT: Failed to ping sensor: \(error)")
            Bugsnag.leaveBreadcrumb(withMessage: "Ping failure")
            // Reset ping to zero?
        }
        
        startDelayTimer(delay: 1.0)  // Functions like a (delayed) recursive call
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
                                                                           descText: "Could not communicate with your sensor, this is because your phone does not have a strong connection to it. Please make sure the devices are close together, and there are no objects causing interference nearby (i.e. large pieces of metal).",
                                                                           image: connFailureImage,
                                                                           buttonTitle: "I'll connected properly",
                                                                           confirmAction:
                    {
                      // When user clicks affirmative action - code here
                      self.connectionFailureModal = nil
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
