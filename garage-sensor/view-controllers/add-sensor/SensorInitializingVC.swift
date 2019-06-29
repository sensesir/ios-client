//
//  SensorInitializingVC.swift
//  garage-sensor
//
//  Created by Josh Perry on 2019/06/10.
//  Copyright © 2019 IoT South Africa. All rights reserved.
//

import Foundation
import UIKit
import PromiseKit
import AwaitKit

class SensorInitializingVC: UIViewController {
    @IBOutlet var whiteLED: UIView!
    @IBOutlet var mqttConnArrow: UIImageView!
    
    var networkPollingTimer: Timer?
    var sensorStatePollingTimer: Timer?
    var sensorLinkingComplete: Bool! = false
    
    override func viewDidLoad() {
        styleUI()
        startNetworkConnPolling()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        stopPulsingArrow()
        stopFlashingWhiteLED()
        networkPollingTimer?.invalidate()
        sensorStatePollingTimer?.invalidate()
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
    
    // MARK: - Logic -
    
    func startNetworkConnPolling() {
        networkPollingTimer?.invalidate()
        networkPollingTimer = Timer.scheduledTimer(timeInterval: 5,
                                                   target: self,
                                                   selector: #selector(pollNetworkConnState),
                                                   userInfo: nil,
                                                   repeats: true)
    }
    
    func startSensorNetworkStateTimer() {
        sensorStatePollingTimer?.invalidate()
        sensorStatePollingTimer = Timer.scheduledTimer(timeInterval: 5,
                                                       target: self,
                                                       selector: #selector(pollSensorNetworkState),
                                                       userInfo: nil,
                                                       repeats: true)
    }
    
    @objc func pollNetworkConnState() {
        let activeConn = Reachability.isConnectedToNetwork()
        if (activeConn) {
            print("SENSOR INIT VC: Re-established connection, linking user and sensor")
            networkPollingTimer?.invalidate()
            linkUserAndSensor()
        } else {
            print("SENSOR INIT VC: Network connection not yet online")
        }
    }
    
    func linkUserAndSensor() {
        let gdoorApi = GDoorAPI()
        async {
            do {
                let res = try await(gdoorApi.initializeSensor(sensorUID: GDoorModel.main.sensorUID!, userUID: GDoorUser.sharedInstance.userUID!))
                self.sensorLinkingComplete = true
                DispatchQueue.main.async { [weak self] in self?.startSensorNetworkStateTimer() }
            }
                
            catch {
                print(error)
                // Todo: handle - retry ? + fail hard
            }
        }
    }
    
    /*
     *  Refactor required: No need to perform using polling timer and periodic http requests.
     *  We can now use the pubsub module, watching for a connected event, but in the philosophy
     *  of changing as little as possible, this optimisation won't be implemented untill the
     *  final app platform is decided on
     */
    
    @objc func pollSensorNetworkState() {
        async {
            do {
                let gdoorApi = GDoorAPI()
                let payload = try await(gdoorApi.getSensorState())
                
                if (payload["online"] as? Bool == true) {
                    print("SENSOR INIT VC: Sensor online")
                    self.sensorStatePollingTimer?.invalidate()
                    DispatchQueue.main.async { [weak self] in self?.transitionForSensorInitComplete() }
                } else {
                    print("SENSOR INIT VC: Sensor not online yet")
                }
            }
            
            catch { print(error) }
        }
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
    
    // MARK: - Transitions -
    
    func transitionForSensorInitComplete() {
        performSegue(withIdentifier: "UnwindFromSensorAddStory", sender: self)
    }
    
}
