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
        setLoadingUI()
        let ssid = ssidEntry.text
        let password = passwordEntry.text
        
        // Invoke handler on DoorModel, using API
        while commRetries < env.MAX_SENSOR_INIT_RETIES {
            print("INIT SENSOR VC: Sensor init attempt \(commRetries + 1)")
            do {
                let result = try await(initializeSensor(ssid: ssid, password: password))
                if (result) { break }
                
                // Failure - increment count and delay retry
                Thread.sleep(forTimeInterval: 5)
                commRetries += 1
            }
            
            catch {
                DispatchQueue.main.async { [weak self] in self?.fatalSensorInitFailure() }
                break
            }
        }
        
        DispatchQueue.main.async { [weak self] in
            self?.transitionToSensorInitVC()
        }
    }
    
    func initializeSensor(ssid: String!, password: String?) -> Promise<Bool> {
        return async {
            let sensorApi = SensorApi()
            
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
        
        // Todo
    }
    
    // MARK: - Transitions -
    
    func transitionToSensorInitVC() {
        print("INIT SENSOR VC: Transitioning to sensor initializing VC")
        performSegue(withIdentifier: "SensorInitializingSegue", sender: self)
    }
  
}
