//
//  InitializeSensorVC.swift
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

class InitializeSensorVC: UIViewController, UITextFieldDelegate {
    @IBOutlet var ssidEntry: UITextField!
    @IBOutlet var passwordEntry: UITextField!
    @IBOutlet var enterButton: UIButton!
    @IBOutlet var loadSpinner: UIActivityIndicatorView!
    
    var availableNetworks: String?
    var loadView: UIView?
    
    var commRetries: Int! = 0
    
    override func viewDidLoad() {
        styleUI()
        ssidEntry.delegate = self
    }
    
    func styleUI() {
        enterButton.layer.cornerRadius = enterButton.frame.height/2.0;
        disableEnterButton()
    }
    
    func setLoadingUI() {
        loadView = UIEffects.fullScreenLoadOverlay()
        self.view.addSubview(loadView!)
    }
    
    func clearLoadUI() {
        loadView?.removeFromSuperview()
    }
    
    // MARK: - Text field handling -
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        if ((textField == ssidEntry) && (ssidEntry.text?.count ?? 0 > 0)) {
            
            enableEnterButton()
        } else {
            disableEnterButton()
        }
    }
    
    @IBAction func dissmissKeyboard() {
        view.endEditing(true)
    }
    
    func enableEnterButton() {
        enterButton.isUserInteractionEnabled = true
        enterButton.backgroundColor = UIColor.init(red: 48/255.0, green: 61/255.0, blue: 79/255.0, alpha: 1)
    }
    
    func disableEnterButton() {
        enterButton.isUserInteractionEnabled = false
        enterButton.backgroundColor = UIColor.init(red: 67/255.0, green: 67/255.0, blue: 67/255.0, alpha: 1)
    }
    
    // MARK: - Network handling -
    
    @IBAction func userSubmittedDetails() {
        print("INIT SENSOR VC: User submitted WiFi details")
        DispatchQueue.main.async { [weak self] in
            self?.setLoadingUI()
            self?.dissmissKeyboard()
        }
        
        let ssid = ssidEntry.text
        let password = passwordEntry.text
        
        // Must make sure not to block main (UI) thread
        DispatchQueue.global(qos: .background).async {
            while self.commRetries < env.MAX_SENSOR_INIT_RETIES {
                print("INIT SENSOR VC: Sensor init attempt \(self.commRetries + 1)")
                do {
                    let result = try await(self.initializeSensor(ssid: ssid, password: password))
                    if (result) {
                        GDoorModel.main.setWifiCreds(ssid: ssid, password: password)
                        DispatchQueue.main.async { [weak self] in self?.transitionToSensorInitVC() }
                        return
                    }
                    
                    // Failure - increment count and delay retry
                    Thread.sleep(forTimeInterval: 10)
                    self.commRetries += 1
                }
                    
                catch {
                    DispatchQueue.main.async { [weak self] in self?.fatalSensorInitFailure() }
                    break
                }
            }
            
            DispatchQueue.main.async { [weak self] in self?.fatalSensorInitFailure() }
        }
    }
    
    func initializeSensor(ssid: String!, password: String?) -> Promise<Bool> {
        return async {
            let sensorApi = GDoorSensorApi()
            
            do {
                let sensorUID = try await(sensorApi.getSensorUID())
                GDoorModel.main.setSensorUID(newUID: sensorUID)
                print("INIT SENSOR VC: Received sensorUID => \(sensorUID)")
                
                try await(sensorApi.postWiFiCreds(ssid: ssid!, password: password))
                print("INIT SENSOR VC: Sent Wifi creds")
                try await(sensorApi.postSensorUIDResConfirmation())
                print("INIT SENSOR VC: Sent sensor UID reception confirmation")
                
                return true
            }
                
            catch {
                print(error)
                return false
            }
        }
    }
    
    // MARK: - Failure handling -
    
    func fatalSensorInitFailure() {
        print("INIT SENSOR VC: Fatal failure, notifying user")
        clearLoadUI()
        
        let commsFailureImage = UIImage.init(named: "door-offline")
        if let fatalCommsFailureModal = StandardModalVC.initModal(title: "Fatal failure",
                                                         descText: "Could not communicate with your sensor, this is because your phone did not successfully connect to the sensor's wifi network. Please connect to it, wait for a successful connection and reopen this app",
                                                         image: commsFailureImage!) {
            // Present the VC
            present(fatalCommsFailureModal, animated: true, completion: nil)
        }
        
        // Log error with bugsnag
        Bugsnag.notifyError(NSError(domain:"wifi-cred-pass", code:004, userInfo:nil))
    }
    
    // MARK: - Transitions -
    
    func transitionToSensorInitVC() {
        print("INIT SENSOR VC: Transitioning to sensor initializing VC")
        performSegue(withIdentifier: "SensorInitializingSegue", sender: self)
    }
  
}
