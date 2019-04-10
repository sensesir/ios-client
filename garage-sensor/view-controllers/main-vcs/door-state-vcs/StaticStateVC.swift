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
    let doorStateImageLookUp = [0: "gdoor-open",
                                1: "gdoor-logo",
                                2: "gdoor-unknown"]
    
    let doorStateLabelLookUp = [0: "Open",
                                1: "Closed",
                                2: "Unknown"]
    
    // Outlets
    @IBOutlet var connStateLabel: UILabel!
    @IBOutlet var connStateImage: UIImageView!
    @IBOutlet var containerCircle: UIView!
    
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
        let doorStateCode = GDoorModel.main.doorState!
        print("STATIC STATE VC: Updating UI elements for new door state = ", doorStateCode)
        
        if doorStateCode < 2 {
            // Door state is know, we can stay on this UI
            connStateLabel.text = doorStateLabelLookUp[doorStateCode]
            connStateImage.image = UIImage.init(named: doorStateImageLookUp[doorStateCode]!)
        }
        
        else if (doorStateCode == 2){
            // Unknown state
            connStateLabel.text = doorStateLabelLookUp[doorStateCode]
            connStateImage.image = UIImage.init(named: doorStateImageLookUp[doorStateCode]!)
        }
        
        else{
            print("STATIC STATE VC: Invalid door status code for UI update")
        }
    }
}















