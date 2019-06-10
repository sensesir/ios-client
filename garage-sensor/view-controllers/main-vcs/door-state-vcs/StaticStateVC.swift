//
//  StaticStateVC.swift
//  garage-sensor
//
//  Created by Josh Perry on 2018/04/10.
//  Copyright © 2018 IoT South Africa. All rights reserved.
//

import UIKit

class StaticStateVC: UIViewController {
    // Constants
    let doorStateImageLookUp = [DoorStateEnum.OPEN: "gdoor-open",
                                DoorStateEnum.CLOSED: "gdoor-logo",
                                DoorStateEnum.UNKNOWN: "gdoor-unknown",
                                DoorStateEnum.ADD_SENSOR: "gdoor-sensor-add"]
    
    // Outlets
    @IBOutlet var connStateLabel: UILabel!
    @IBOutlet var connStateImage: UIImageView!
    @IBOutlet var containerCircle: UIView!
    @IBOutlet var stateInfoText: UILabel!
    var addSensorTap: UITapGestureRecognizer?
    
    override func viewDidLoad() {
        // Set state base do door state
        styleUI()
        
        // Hide the tabbar
        self.tabBarController?.tabBar.isHidden = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        // Update UI state every time
        updateDoorStateUIItems()
    }
    
    override func viewDidLayoutSubviews() {
        // Style the UI geometrically
        containerCircle.layer.cornerRadius = containerCircle.frame.height/2
    }
    
    // MARK: - UI Handling -
    
    func styleUI() {
        containerCircle.backgroundColor = UIColor.white // UIColor.init(red: 48/255.0, green: 61/255.0, blue: 79/255.0, alpha: 1.0)
        containerCircle.layer.borderColor = UIColor.init(red: 48/255.0, green: 61/255.0, blue: 79/255.0, alpha: 1.0).cgColor
        containerCircle.layer.borderWidth = 5.0
        
        // Look at the GDoor model
        updateDoorStateUIItems()
    }
    
    func updateDoorStateUIItems() {
        // Use the model object to display the state
        print("STATIC STATE VC: Updating UI elements for new door state = ", GDoorModel.main.doorState!)
        let currentDoorState = GDoorModel.main.doorStateEnum
        connStateLabel.text = GDoorModel.main.doorState
        connStateImage.image = UIImage.init(named: doorStateImageLookUp[currentDoorState!]!)
        
        if (currentDoorState == DoorStateEnum.ADD_SENSOR) {
            stateInfoText.isHidden = false
            setAddNewSensorButton()
        }
        else {
            stateInfoText.isHidden = true
            removeAddNewSensorButton()
        }
    }
    
    func setAddNewSensorButton() {
        if (addSensorTap == nil) {
            addSensorTap = UITapGestureRecognizer.init(target: self, action: #selector(transitionToAddSensorStory))
            connStateImage.addGestureRecognizer(addSensorTap!)
        }
        
        connStateImage.isUserInteractionEnabled = true
    }
    
    func removeAddNewSensorButton() {
        connStateImage.isUserInteractionEnabled = false
    }
    
    // MARK: - Transition handling -
    
    @objc func transitionToAddSensorStory() {
        let parentView = (self.parent as! UIViewController).parent as! DoorControllerVC
        parentView.transitionToAddSensorStory()
    }
}















