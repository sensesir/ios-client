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
import Bugsnag
import AWSIoT

enum SensorInitState {
    case awaitingNetworkConnection
    case awaitingSensorOnline
}

class SensorInitializingVC: UIViewController, GDoorPubSubDelegate {
    @IBOutlet var whiteLED: UIView!
    @IBOutlet var greenLED: UIView!
    @IBOutlet var sensorBox: UIView!
    @IBOutlet var mqttConnArrow: UIImageView!
    
    var gdoorAPI = GDoorAPI()
    var pubsubClient: GDoorPubSub?
    var sensorInitState = SensorInitState.awaitingNetworkConnection
    var connectedToAWSIoT: Bool = false
    var networkPollingTimer: Timer?
    var sensorLinkingComplete: Bool! = false
    
    override func viewDidLoad() {
        styleUI()
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(appEnteringForeground),
                                               name: NSNotification.Name.UIApplicationWillEnterForeground,
                                               object: nil)
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(appEnteringBackground),
                                               name: NSNotification.Name.UIApplicationWillResignActive,
                                               object: nil)
    }
    
    // MARK: - App state handling -
    
    override func viewWillAppear(_ animated: Bool) {
        startNetworkPollTimer(delay: 5)
    }
    
    @objc func appEnteringForeground() {
        switch sensorInitState {
        case .awaitingNetworkConnection:
            print("SENSOR INIT: Awaiting network conn, restarting polling timer")
            pollNetworkConnState()
        case .awaitingSensorOnline:
            print("SENSOR INIT: Awaiting sensor online - ensuring MQTT conn up")
            reconnectAWSIoT()
        }
    }
        
    @objc func appEnteringBackground() {
        switch sensorInitState {
        case .awaitingNetworkConnection:
            print("SENSOR INIT: App entering background, stopping network conn poll timer")
            networkPollingTimer?.invalidate()
        case .awaitingSensorOnline:
            print("SENSOR INIT: App entering background - disconnecting from AWS IoT")
            pubsubClient?.disconnectDeviceGateway()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        sensorInitState = .awaitingNetworkConnection
        
        stopPulsingArrow()
        stopFlashingWhiteLED()
        networkPollingTimer?.invalidate()
        
        // Disconnect and release pubsub var --> need t check timing on this
        pubsubClient?.disconnectDeviceGateway()
        pubsubClient = nil
    }
    
    override func viewDidLayoutSubviews() {
        whiteLED.layer.cornerRadius = whiteLED.frame.height/2.0
        greenLED.layer.cornerRadius = greenLED.frame.height/2.0
        sensorBox.layer.cornerRadius = 4.0
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
    
    // What happens if minimize and re-open the app?
    
    @objc func pollNetworkConnState() {
        do {
            let networkConnection = try await(self.connectedToNetwork())
            if (networkConnection) {
                print("SENSOR INIT VC: Re-established connection, linking user and sensor")
                self.sensorInitState = .awaitingSensorOnline
                self.linkUserAndSensor()
            } else {
                print("SENSOR INIT: Waiting for network connection...")
                self.startNetworkPollTimer(delay: 5)
            }
        } catch {
            print("SENSOR INIT: Error polling network state => \(error)")
            print("SENSOR INIT: Waiting before retrying...")
            self.startNetworkPollTimer(delay: 5)
        }
    }
    
    func linkUserAndSensor() {
        async {
            do {
                try await(self.gdoorAPI.initializeSensor(sensorUID: GDoorModel.main.sensorUID!, userUID: GDoorUser.sharedInstance.userUID!))
                try await(self.connectAWSIoT())
                print("SENSOR INIT: Linked sensor and user account")
            }
            catch {
                print("SENSOR INIT: Failed to link user and sensor account - fatal error")
                Bugsnag.notifyError(error)
            }
        }
    }
    
    // MARK: - Network -
    
    func connectedToNetwork() -> Promise<Bool> {
        return Promise<Bool> {seal in
            do {
                // Ping server
                print("SENSOR INIT: Testing network connection")
                let res = try await(gdoorAPI.pingServer())
                if (res) {
                    print("SENSOR INIT: Successfully reconnected to network")
                    seal.fulfill(true)
                }
                else { seal.fulfill(false) }
            } catch {
                // Check timeout error here
                print("SENSOR INIT: Failed to ping server => \(error)")
                seal.fulfill(false)
            }
        }
    }
    
    func checkSensorStateAPI() {
        async {
            do {
                let sensorData = try await(self.gdoorAPI.getSensorDataPromise(userUID: GDoorUser.sharedInstance.userUID!))
                if let sensorConnState = sensorData["online"] as? Bool {
                    if (sensorConnState == true) {
                        self.sensorLinkingComplete = true
                        self.transitionForSensorInitComplete()
                    } else {
                        print("SENSOR INIT: Sensor not online, waiting for connect event to be published")
                    }
                }
            } catch {
                print(error)
                // Todo: handle - retry ? + fail hard
                Bugsnag.notifyError(error)
            }
        }
    }
    
    // MARK: - Timers -
    
    func startNetworkPollTimer(delay: TimeInterval) {
        networkPollingTimer = Timer.scheduledTimer(timeInterval: delay,
                                                   target: self,
                                                   selector: #selector(pollNetworkConnState),
                                                   userInfo: nil,
                                                   repeats: false)
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
    
    // MARK: - Pubsub -
    
    func connectAWSIoT() -> Promise<Bool> {
        return Promise<Bool> { seal in
            pubsubClient = GDoorPubSub.initWithDelegate(newDelegate: self)
            pubsubClient!.connectToDeviceGateway()
            
            for _ in 1...25 {
                if (connectedToAWSIoT) {
                    seal.fulfill(true)
                    return;
                }
                
                // Puts thread to sleep, but won't block the UI thread - this is background
                sleep(1)
            }
            
            print("SENSOR INIT: Failed to connect to device gateway in time")
            seal.fulfill(false)
        }
    }
    
    func reconnectAWSIoT() {
        let currentMQTTState = pubsubClient?.getConnectionStatus()
        if (currentMQTTState != .connected || currentMQTTState != .connecting) {
            pubsubClient?.connectToDeviceGateway()
        }
    }
    
    func connectionStateUpdate(newState: AWSIoTMQTTStatus) {
        switch newState {
            case .connected:
                print("SENSOR INIT: Checking sensor state after MQTT connection")
                self.connectedToAWSIoT = true
            
                /*  Perform a quick API check for connection here -
                 *  catches the edge case where in the sensor goes
                 *  up while the phone is connecting to AWS IoT
                 */
                checkSensorStateAPI()
            
            // What to do with error states? --> report to user ?
            // A failure here could no internet ? or server down?
            case .connectionError: print("PUBSUB: AWS IoT connection error")
            case .connectionRefused: print("PUBSB: AWS IoT connection refused")
            case .protocolError: print("PUBSUB: AWS IoT protocol error")
            case .disconnected: print("PUBSUB: AWS IoT disconnected")
            case .unknown: print("PUBSUB: AWS IoT unknown state")
            default: print("PUBSUB: Error - unknown MQTT state")
        }
    }
    
    func sensorDataUpdated() {
        // The connection event should catch this]
        print("SENSOR INIT: Sensor data updated via MQTT, checking online status")
        if (GDoorModel.main.networkState == "Sensor Online") {
            self.sensorLinkingComplete = true
            self.transitionForSensorInitComplete()
        }
    }
    
    func sensorRSSIUpdated(rssi: Float) {
        // Not used
    }
    
    // MARK: - Transitions -
    
    func transitionForSensorInitComplete() {
        DispatchQueue.main.async {
            self.performSegue(withIdentifier: "UnwindFromSensorAddStory", sender: self)
        }
    }
    
}
