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
    let sensorStateImageLookup = ["Sensor Online": "door-online",
                                  "Sensor Offline": "door-offline",
                                  "Sensor Connecting": "cloud-navy"]
    
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
        
        doorActuator.isHidden = true
        doorConnStateButton.isHidden = true
        doorConnStateIcon.isHidden = true
        styleUI();
    
        GDoorModel.main.sensorStateDelegate = self
        GDoorModel.main.doorStateDelegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        updateDoorState()
    }
    
    // MARK: - UI Hanlding -

    func styleUI() {
        // Round the button
        doorActuator.layer.cornerRadius = doorActuator.frame.height/2.0;
        let navController = parent as? UINavigationController
        let titleAttributes = [NSAttributedStringKey.foregroundColor: UIColor.white]
        navController?.navigationBar.barTintColor = UIColor.init(red: 48/255.0, green: 61/255.0, blue: 79/255.0, alpha: 1.0)
        navController?.navigationBar.titleTextAttributes = titleAttributes
        
        if GDoorModel.main.modelInitialised { transitionToStaticState() }
        else { transitionToTransientState() }
    }
    
    func transitionToStaticState() {
        let stateController = childViewControllers[0] as! UITabBarController
        stateController.selectedIndex = 0;
        
        // Update the static state VCs UI
        let staticStateVC = stateController.childViewControllers[0] as? StaticStateVC
        staticStateVC?.updateDoorStateUIItems();
    }
    
    func transitionToTransientState() {
        let stateController = childViewControllers[0] as! UITabBarController
        stateController.selectedIndex = 1;
    }
    
    func updateUIForTriggerError(errorCode: Int!) {
        // Updates the UI to show the request failed
    }
    
    func updateSensorUIElements() {
        if (GDoorModel.main.sensorUID == "None") {
            // Special case of no sensor linked to account
            doorActuator.isHidden = true
            doorConnStateButton.isHidden = true
            doorConnStateIcon.isHidden = true
        }
        
        else {
            doorActuator.isHidden = false
            doorConnStateButton.isHidden = false
            doorConnStateIcon.isHidden = false
            doorConnStateButton.setTitle(GDoorModel.main.networkState, for: .normal)
            doorConnStateIcon.image = UIImage.init(named: sensorStateImageLookup[GDoorModel.main.networkState!]!)
        }
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
    
    func updateDoorState() {
        GDoorModel.main.initializeModel { (success, failureMessage, error) in
            if (error != nil) {
                // TODO: report error
                return
            }
            
            DispatchQueue.main.async {
                self.transitionToStaticState()
                self.updateSensorUIElements()
            }
        }
    }
    
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
    
    @IBAction func actuateDoor() {
        print("DOOR CONTROLLER: Sending door actuation trigger")
        let gdoorApi = GDoorAPI()
        gdoorApi.actuateDoor(userUID: GDoorUser.sharedInstance.userUID!) { (success, error) in
            if (error != nil) {
                // TODO: Handle
                return
            }
            
            print("DOOR CONTROLLER: Successfully actuated door")
            // Todo: show modal
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
    
    // MARK: - Transitions -
    
    func transitionToAddSensorStory() {
        // Transition to WiFi set up (but home screeb for now)
        let addSensorStory = UIStoryboard(name: "AddSensor", bundle: nil)
        let introVC = addSensorStory.instantiateInitialViewController()
        present(introVC!, animated: true, completion: nil)
    }
    
    @IBAction func unwindFromAddSensorStory(for unwindSegue: UIStoryboardSegue, towardsViewController subsequentVC: UIViewController) {
        print("DOOR CONTROLLER: Unwound after completing sensor setup")
    }
}








