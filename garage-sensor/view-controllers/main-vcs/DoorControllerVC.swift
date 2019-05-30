//
//  DoorControllerVC.swift
//  garage-sensor
//
//  Created by Josh Perry on 2018/04/09.
//  Copyright © 2018 IoT South Africa. All rights reserved.
//

import Foundation
import UIKit

class DoorControllerVC: UIViewController, SensorStateProtocol, DoorStateProtocol {
    // Class props
    // Constants
    let sensorSateLabelLookup = ["online": "Sensor Online",
                                 "offline": "Sensor Offline",
                                 "unknown": "Sensor connecting"]
    
    let sensorStateImageLookup = ["online": "door-online",
                                  "offline": "door-offline",
                                  "unknown": "cloud-navy"]
    
    // Controls
    var doorTriggerInProgress: Bool! = false
    var staticStateVC: StaticStateVC?
    
    // UI props
    @IBOutlet var stateContainer:       UIView!
    @IBOutlet var doorActuator:         UIButton!
    @IBOutlet var doorConnStateButton:  UIButton!
    @IBOutlet var doorConnStateIcon:    UIImageView!
    
    // MARK: - Initializations -
    // Set up function
    override func viewDidLoad() {
        // Get reference to child VCs
        let stateController = childViewControllers[0] as! UITabBarController
        staticStateVC = stateController.childViewControllers[0] as? StaticStateVC
            
        // Round the buttons
        styleUI();
        
        // Setup Daatabase listeners for state changes on door state
        GDoorModel.main.sensorStateDelegate = self
        GDoorModel.main.doorStateDelegate = self
    }
    
    // MARK: - UI Hanlding -

    func styleUI() {
        // Round the button
        doorActuator.layer.cornerRadius = doorActuator.frame.height/2.0;
        let navController = parent as? UINavigationController
        let titleAttributes = [NSAttributedStringKey.foregroundColor: UIColor.white]
        navController?.navigationBar.barTintColor = UIColor.init(red: 48/255.0, green: 61/255.0, blue: 79/255.0, alpha: 1.0)
        navController?.navigationBar.titleTextAttributes = titleAttributes
        
        // Assess whether con state is known or not
        if GDoorModel.main.initialDoorStateConfirmed {
            transitionToStaticState()
        } else {
            uiStateForConnecting()
            transitionToTransientState()
        }
    }
    
    func transitionToStaticState() {
        let stateController = childViewControllers[0] as! UITabBarController
        stateController.selectedIndex = 0;
    }
    
    func transitionToTransientState() {
        let stateController = childViewControllers[0] as! UITabBarController
        stateController.selectedIndex = 1;
    }
    
    func updateUIForTriggerError(errorCode: Int!) {
        // Updates the UI to show the request failed
    }
    
    func updateSensorUIElements() {
        let connStateCode = GDoorModel.main.sensorConnState
        doorConnStateButton.setTitle(sensorSateLabelLookup[connStateCode!], for: .normal)
        doorConnStateIcon.image = UIImage.init(named: sensorStateImageLookup[connStateCode!]!)
    }
    
    func uiStateForConnecting() {
        // Set the label to connecting
        doorConnStateButton.setTitle("Sensor Connecting", for: .normal)
        doorConnStateIcon.image = UIImage.init(named: sensorStateImageLookup["unknown"]!)
    }
    
    func showSuccessModal() {
        let successImage = UIImage.init(named: "success-tick-green")
        if let successModal = StandardModalVC.initModal(title: "Trigger Sent!",
                                                        descText: "The door trigger command was successfully sent",
                                                        image: successImage!) {
            // Present the VC
            present(successModal, animated: true, completion: nil)
        }
    }
    
    func showFailureModal(errorCode: Int!) {
        // Use a lookup table for error codes and corresponding title and descriptions
        let failureImage = UIImage.init(named: "connection-failed")
        let errorResolver = doorInterfaceErrorDesc()
        let errorTitleResolver = doorInterfaceErrorTitles()
        
        if let errorModal = StandardModalVC.initModal(title: errorTitleResolver.errorCodeResolver[errorCode],
                                                        descText: errorResolver.errorCodeResolver[errorCode],
                                                        image: failureImage!) {
            // Present the VC
            present(errorModal, animated: true, completion: nil)
        }
    }
    
    // MARK: - Door Interface -
    
    /*
    @IBAction func triggerDoor() {
        print("DOOR CONTROLLER: User attempting to actuate door")
        let stateController = childViewControllers[0] as! UITabBarController
        stateController.selectedIndex = 1;
        
        // Send an HTTP get request to trigger the garage door
        httpInterface.hitActuateDoorAPI { (data, response, error) in
            // Cancel loading interface
            DispatchQueue.main.async {self.transitionToStaticState()}
            
            if (error != nil){
                // Inspect error
                print("DOOR CONTROLLER: Error in http req = ", error!)
                var errorCode = 9;
                if ((error! as NSError).code == -1001){errorCode = 4}
                DispatchQueue.main.async {self.updateUIForTriggerResponse(resCode: errorCode)}
                return
            }
            
            // Check for any errors
            if let httpCode = response as? HTTPURLResponse, httpCode.statusCode != 200 {
                let statusCode = httpCode.statusCode
                print("DOOR CONTROLLER: Error response from server. Code => ", statusCode)
                
                // Update UI
                var errorCode = 7;
                if (statusCode == 408){errorCode = 4}   // Sensor, not server error
                DispatchQueue.main.async {self.updateUIForTriggerResponse(resCode: errorCode)}
                return
            }
            
            // Check the response
            print("DOOR CONTROLLER: Got http response from door")
            let resCodeDict = GDUtilities.shared.doorResJSONDataToDict(jsonData: data)
            let resCode = resCodeDict["message"]
            DispatchQueue.main.async {self.updateUIForTriggerResponse(resCode: resCode as! Int)}
        }
    }
 */
    
    func updateUIForTriggerResponse(resCode: Int!) {
        if resCode == 0 {
            // All nominal
            print("DOOR CONTROLLER: Door repsonse positive - showing user the door is moving")
            showSuccessModal()
        }
        
        // Error of some sort - show user error overlay
        else{
            print("DOOR CONTROLLER: Error while attempting to trigger door. Code = ", resCode)
            showFailureModal(errorCode: resCode)
        }
    }
    
    // MARK: - Delegate Callbacks -
    
    func doorStateUpdated() {
        // Update UI
        DispatchQueue.main.async {
            // Any door state update requires the Static VC to feature
            let stateController = self.childViewControllers[0] as? UITabBarController
            if stateController?.selectedIndex == 0 {
                // VC is in view - need explicitly update state
                self.staticStateVC?.updateDoorStateUIItems()
            } else {
                self.transitionToStaticState()
            }
        }
    }
    
    func sensorStateUpdated() {
        // Update UI
        DispatchQueue.main.async { self.updateSensorUIElements() }
    }
    
    func sensorLanIPError() {
        // Show the user the LAN static IP config isn't correct
        showFailureModal(errorCode: 8);
    }
}








