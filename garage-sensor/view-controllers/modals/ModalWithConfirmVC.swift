//
//  ModalWithConfirmVC.swift
//  garage-sensor
//
//  Created by Josh Perry on 2019/06/29.
//  Copyright © 2019 IoT South Africa. All rights reserved.
//

import UIKit

class ModalWithConfirmVC: UIViewController {
    @IBOutlet var modalContentView: UIView!
    @IBOutlet var modalTitle: UILabel!
    @IBOutlet var modalImage: UIImageView!
    @IBOutlet var modalDescription: UILabel!
    @IBOutlet var modalConfirmButton: UIButton!
    
    var confirmActionHandler: (() -> Void)?
    
    // Ephemeral
    var titleHolder: String?
    var imageHolder: UIImage?
    var descriptionHolder: String?
    var buttonTitleHolder: String?
    
    override func viewDidLoad() {
        // Assign the labels from the holders
        modalTitle.text = titleHolder
        modalDescription.text = descriptionHolder
        modalImage.image = imageHolder
        modalConfirmButton.setTitle(buttonTitleHolder, for: .normal)
        
        uiStyling()
        
        let tapAway = UITapGestureRecognizer.init(target: self, action: #selector(dismissModalVC))
        self.view.addGestureRecognizer(tapAway)
    }
    
    class func initModal(title: String!,
                         descText: String?,
                         image: UIImage?,
                         buttonTitle: String?,
                         confirmAction: @escaping () -> Void) -> ModalWithConfirmVC? {
        
        // Instantiate the template from storyboard
        let mainStory = UIStoryboard(name: "Main", bundle: nil);
        
        if let modalVC = mainStory.instantiateViewController(withIdentifier: "ModalWithConfirmVC") as? ModalWithConfirmVC {
            // Ensure the VC gets presented modally
            modalVC.modalPresentationStyle = .overCurrentContext;
            modalVC.modalTransitionStyle = .crossDissolve;
            
            // Set the visual elements
            modalVC.titleHolder = title
            modalVC.descriptionHolder = descText
            modalVC.imageHolder = image
            modalVC.buttonTitleHolder = buttonTitle != nil ? buttonTitle : "Confirm"
            
            // Callback set
            modalVC.confirmActionHandler = confirmAction
            
            return modalVC
        }
        
        return nil
    }
    
    func uiStyling() {
        modalContentView.layer.cornerRadius = 18.0
        modalConfirmButton.layer.cornerRadius = modalConfirmButton.frame.height/2.0
    }
    
    @objc func dismissModalVC() {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func confirmPressed(sender: UIButton?) {
        dismiss(animated: true) {
            self.confirmActionHandler!()
        }
    }
}
