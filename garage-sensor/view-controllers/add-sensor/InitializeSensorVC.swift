//
//  InitializeSensorVC.swift
//  garage-sensor
//
//  Created by Josh Perry on 2019/06/10.
//  Copyright © 2019 IoT South Africa. All rights reserved.
//

import Foundation
import UIKit

class InitializeSensorVC: UIViewController, UITextFieldDelegate {
    @IBOutlet var ssidEntry: UITextField!
    @IBOutlet var passwordEntry: UITextField!
    @IBOutlet var enterButton: UIButton!
    @IBOutlet var loadSpinner: UIActivityIndicatorView!
    
    var availableNetworks: String?
    
    override func viewDidLoad() {
        styleUI()
        ssidEntry.delegate = self
    }
    
    func styleUI() {
        enterButton.layer.cornerRadius = enterButton.frame.height/2.0;
        disableEnterButton()
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
        
        // Invoke handler on DoorModel, using API
    }
    
    
  
}
