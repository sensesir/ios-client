//
//  StandardModalVC.swift
//  garage-sensor
//
//  Created by Josh Perry on 2018/04/16.
//  Copyright © 2018 IoT South Africa. All rights reserved.
//

import UIKit

class StandardModalVC: UIViewController{
    // UI elements
    @IBOutlet var modalContentView: UIView!
    @IBOutlet var modalTitle: UILabel!
    @IBOutlet var modalImage: UIImageView!
    @IBOutlet var modalDescription: UILabel!
    
    // Ephemeral
    var titleHolder: String?
    var imageHolder: UIImage?
    var descriptionHolder: String?
    
    override func viewDidLoad() {
        // Assign the labels from the holders
        modalTitle.text = titleHolder
        modalDescription.text = descriptionHolder
        modalImage.image = imageHolder
        
        // Style UI
        uiStyling()
    }
    
    class func initModal(title: String!, descText: String?, image: UIImage?) -> StandardModalVC?{
        // Instantiate the template from storyboard
        let mainStory = UIStoryboard(name: "Main", bundle: nil);
        
        if let modalVC = mainStory.instantiateViewController(withIdentifier: "StandardModalVC") as? StandardModalVC {
            // Ensure the VC gets presented modally
            modalVC.modalPresentationStyle = .overCurrentContext;
            modalVC.modalTransitionStyle = .crossDissolve;
            
            // Set the visual elements
            modalVC.titleHolder = title
            modalVC.descriptionHolder = descText
            modalVC.imageHolder = image
            
            return modalVC
        }
        
        return nil
    }
    
    func uiStyling() {
        modalContentView.layer.cornerRadius = 18.0
        
        // Add tap anywhere to dismiss
        let tapAway = UITapGestureRecognizer.init(target: self, action: #selector(dismissModalVC))
        self.view.addGestureRecognizer(tapAway)
    }
    
    @objc func dismissModalVC() {
        dismiss(animated: true, completion: nil)
    }
    
    
}
