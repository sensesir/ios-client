//
//  UIEffects.swift
//  garage-sensor
//
//  Created by Josh Perry on 2018/04/10.
//  Copyright © 2018 IoT South Africa. All rights reserved.
//

import UIKit

class UIEffects: NSObject {
    // Load elements
    // var blurEffectView: UIVisualEffectView?
    // var loadImage: UIImageView?
    // var loadLabel: UILabel?
    // var loadSpinner: UIActivityIndicatorView?
    
    // Custom load spinner
    class func fullScreenLoadOverlay() -> UIView{
        // Create the blurr effect
        let backgroundBlur = UIBlurEffect.init(style: .light)
        let blurEffectView = UIVisualEffectView.init(effect: backgroundBlur)
        
        // Shape to full screen
        blurEffectView.frame = UIScreen.main.bounds
        blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        // Add the load image
        let imageSide = UIScreen.main.bounds.height/4
        let imageSize = CGSize(width: imageSide, height: imageSide)
        let loadImage = UIImageView.init()
        loadImage.bounds.size = imageSize
        loadImage.center = CGPoint(x: blurEffectView.center.x, y: blurEffectView.center.y*0.6)
        loadImage.image = UIImage.init(named: "gdoor-logo")
        blurEffectView.contentView.addSubview(loadImage)
        
        // Add load spinner
        let loadSpinner = UIActivityIndicatorView.init()
        loadSpinner.activityIndicatorViewStyle = .gray
        loadSpinner.center = CGPoint(x: loadImage.center.x, y: (loadImage.center.y + imageSide/2 + 20))
        blurEffectView.contentView.addSubview(loadSpinner)
        loadSpinner.startAnimating()
        
        // Add the loading label
        let labelY: CGFloat! = loadSpinner.frame.origin.y + loadSpinner.frame.size.height + 20;
        let loadLabelFrame = CGRect(x: 0, y: labelY, width: UIScreen.main.bounds.width, height: 50)
        let loadLabel = UILabel.init(frame: loadLabelFrame)
        loadLabel.textAlignment = .center
        loadLabel.font = UIFont(name: "HelveticaNeue-Light", size: 18)
        loadLabel.text = "Loading"
        loadLabel.textColor = UIColor.init(red: 48/255.0, green: 61/255.0, blue: 79/255.0, alpha: 1.0)
        blurEffectView.contentView.addSubview(loadLabel)
        
        return blurEffectView
    }
}







