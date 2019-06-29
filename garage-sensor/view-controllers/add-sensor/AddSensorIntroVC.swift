//
//  AddSensorIntroVC.swift
//  garage-sensor
//
//  Created by Josh Perry on 2019/06/10.
//  Copyright © 2019 IoT South Africa. All rights reserved.
//

import Foundation
import UIKit

class AddSensorIntroVC: UIViewController {
    @IBOutlet var readyButton: UIButton!
    
    override func viewDidLoad() {
        styleUI()
    }
    
    // MARK: - UI Hanlding -
    
    func styleUI() {
        // Round the button
        readyButton.layer.cornerRadius = readyButton.frame.height/2.0;
        let navController = parent as? UINavigationController
        let titleAttributes = [NSAttributedStringKey.foregroundColor: UIColor.white]
        navController?.navigationBar.barTintColor = UIColor.init(red: 48/255.0, green: 61/255.0, blue: 79/255.0, alpha: 1.0)
        navController?.navigationBar.titleTextAttributes = titleAttributes
        
        
    }
}
