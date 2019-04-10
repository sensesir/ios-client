//
//  SignUpVC.swift
//  garage-sensor
//
//  Created by Josh Perry on 2018/04/09.
//  Copyright © 2018 IoT South Africa. All rights reserved.
//

import Foundation
import UIKit

class SignUpVC: UIViewController, UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate {
    // Controls
    let authInterface: FirebaseAuthInterface! = FirebaseAuthInterface.init()
    var validUserName: Bool! = false
    var validUserEmail: Bool! = false
    var validUserPassword: Bool! = false
    var nameAttempt: Bool! = false
    var emailAttepmt: Bool! = false
    var passwordAttempt: Bool! = false
    
    // User info
    var userName: String?
    var userEmail: String?
    var userPassword: String?
    
    // Constants
    let logoCellID: String! = "LogoCellID"
    let textEntryCellID: String! = "TextEntryCellID"
    let infoTextCellID: String! = "TextInfoCellID"
    
    // Visual props
    @IBOutlet var signupForm: UITableView!
    var loadView: UIView?
    
    override func viewDidLoad() {
        // Initialize the table view
        initSignupForm()
    }
    
    // MARK: - Table view initializers -
    
    func initSignupForm(){
        // Set delegate and Datasource
        signupForm.delegate = self
        signupForm.dataSource = self
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // Statically state for now
        return 5
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        // Switch case
        let row = indexPath.row
        
        if (row == 1 || row == 2 || row == 3) {
            // Name, email & password
            return 60
        } else if (row == 4){
            // Info cell
            return 80
        }
        
        else if (row == 0){
            // Logo cell - make 1/3 of screen
            return UIScreen.main.bounds.height*0.3
        }
        
        else{
            // error
            return 0;
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // Generate the correct cells for each type
        let row = indexPath.row
        var cell: UITableViewCell?
        
        if (row == 1 || row == 2 || row == 3) {
            // Name, email & password
            cell = generateTextInputCell(tableView: tableView, row: row)
        }
        else if (row == 0){
            // Logo cell - make 1/3 of screen
            cell = generateLogoCell(tableView: tableView)
        }
        else if (row == 4){
            // Info cell
            cell = generateInfoTextCell(tableView: tableView)
        }
        else{
            print("SIGNUP VC: Invalid cell row requesting cell")
            cell = UITableViewCell.init()
        }
        
        // Create reusable cell
        return cell!
    }
    
    func generateLogoCell(tableView: UITableView!) -> UITableViewCell {
        // Create with cell ID and return
        var cell = tableView.dequeueReusableCell(withIdentifier: logoCellID)
        if (cell == nil) {
            // Instantiate the cell
            cell = UITableViewCell.init(style: .default, reuseIdentifier: logoCellID)
        }
        
        return cell!
    }
    
    func generateTextInputCell(tableView: UITableView!, row: Int!) -> TextEntryCell {
        // Create cell and customize the text
        var cell = tableView.dequeueReusableCell(withIdentifier: textEntryCellID) as? TextEntryCell
        if (cell == nil) {
            cell = TextEntryCell.init(style: .default, reuseIdentifier: textEntryCellID)
        }
        
        switch row {
            case 1:
                cell?.userEntry.text = "First & Last Name"
                cell?.userEntry.tag = 0
                cell?.userEntry.autocapitalizationType = .words
            case 2:
                cell?.userEntry.text = "Email"
                cell?.userEntry.tag = 1
            case 3:
                cell?.userEntry.text = "Password"
                cell?.userEntry.tag = 2
            default: cell?.userEntry.text = "Error"
        }
        
        cell?.userEntry.delegate = self
        return cell!
    }
    
    func generateInfoTextCell(tableView: UITableView!) -> InfoTextCell {
        // Create cell and customize the text
        var cell = tableView.dequeueReusableCell(withIdentifier: infoTextCellID) as? InfoTextCell
        if (cell == nil){
            cell = InfoTextCell.init(style: .default, reuseIdentifier: infoTextCellID)
        }
        
        // Set the text to hidden
        cell?.userInfo.isHidden = true
        cell?.submitButton.addTarget(self, action: #selector(userSubmittedDetails), for: .touchUpInside)
        return cell!
    }
    
    
    // MARK: - User Entry handling -
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        // Check which text field it
        switch textField.tag {
        case 0:
            if (userName == nil) {
                textField.text = ""
            }
        case 1:
            if (userEmail == nil) {
                textField.text = ""
            }
        case 2:
            if (userPassword == nil) {
                textField.text = ""
                textField.isSecureTextEntry = true
            }
        default:
            print("SIGNUP VC: Error - invalid textfield tag")
        }
        
        // Hide the error label
        let indexPath = IndexPath.init(row: 4, section: 0)
        let cell = signupForm.cellForRow(at: indexPath) as? InfoTextCell
        cell?.userInfo.isHidden = true
    }
    
    func textFieldDidEndEditing(_ textField: UITextField, reason: UITextFieldDidEndEditingReason) {
        // Check validity of entry
        var recentEntryValid: Bool! = false
        
        switch textField.tag {
        case 0:
            userName = textField.text
            recentEntryValid = assessUserNameValidity(name: textField.text!)
            nameAttempt = true
        case 1:
            userEmail = textField.text
            recentEntryValid = assessEmailValidity(email: textField.text!)
            emailAttepmt = true
        case 2:
            userPassword = textField.text
            recentEntryValid = assessPasswordVailidity(password: textField.text!)
            passwordAttempt = true
        default:
            print("SIGN UP VC: Invalid text field")
        }
        
        if recentEntryValid {
            // If the most recent check passed, scan all
            fullEntryValidityCheck()
        }
    }
    
    func fullEntryValidityCheck() {
        // Check if we have all green lights
        let indexPath = IndexPath.init(row: 4, section: 0)
        let cell = signupForm.cellForRow(at: indexPath) as? InfoTextCell
        
        if (!validUserName && nameAttempt) {
            // Expose submit button
            cell?.userInfo.isHidden = false
            cell?.userInfo.text = "User name should be longer than 4 characters"
            cell?.submitButton.isHidden = true
        }
            
        else if (!validUserEmail && emailAttepmt){
            cell?.userInfo.isHidden = false
            cell?.userInfo.text = "Hmmm the email address doesn't seem quite right. Please try again."
            cell?.submitButton.isHidden = true
        }
            
        else if(!validUserName && passwordAttempt){
            cell?.userInfo.isHidden = false
            cell?.userInfo.text = "Password should be longer than 6 characters"
            cell?.submitButton.isHidden = true
        }
            
        else if (validUserName && validUserEmail && validUserPassword){
            cell?.userInfo.isHidden = true
            cell?.submitButton.layer.cornerRadius = cell!.submitButton.frame.height/2
            cell?.submitButton.isHidden = false
        }
    }
    
    func assessUserNameValidity(name: String) -> Bool {
        // Simply check for entry longer than 4 chars
        if name.count > 3 {
            // Set error label
            validUserName = true
            return true
        } else{
            print("SIGN UP VC: Invalid user name")
            setErrorLabel(error: "User name must be 4 or more characters")
            return false
        }
    }
    
    func assessEmailValidity(email: String) -> Bool {
        // Check for @ and .
        let validChars =    CharacterSet.init(charactersIn: "@.")
        let invalidChars =  CharacterSet.init(charactersIn: " ")
        let emailChars =    CharacterSet.init(charactersIn: email)
        let validEmail = emailChars.isSuperset(of: validChars) && !emailChars.isSuperset(of: invalidChars)
        
        if !validEmail {
            print("SIGN UP VC: Invalid user email")
            validUserEmail = false
            setErrorLabel(error: "Hmmm, that email address doesn't look quite right")
            return false
        } else{
            validUserEmail = true
            return true
        }
    }
    
    func assessPasswordVailidity(password: String) -> Bool {
        // Simply check length here
        if password.count > 5 {
            validUserPassword = true
            return true
        } else{
            print("SIGN UP VC: Invalid user password")
            setErrorLabel(error: "Password needs to be 6 characters")
            validUserPassword = false
            return false
        }
    }
    
    func setErrorLabel(error: String!) {
        // Get reference to cell
        let indexPath = IndexPath.init(row: 4, section: 0)
        let cell = signupForm.cellForRow(at: indexPath) as? InfoTextCell
        
        // Set the text and show it
        cell?.userInfo.text = error
        cell?.userInfo.isHidden = false
    }
    
    // MARK: - Submit Details -
    @objc func userSubmittedDetails() {
        // Sending user details to user object
        print("SIGN UP VC: Captured user details, sending to User object")
        loadView = UIEffects.fullScreenLoadOverlay()
        self.view.addSubview(loadView!)
        
        // Send to firebase
        authInterface.authUserWithEmail(userName: userName,
                                        email: userEmail,
                                        password: userPassword)
        { (success, userUID, error) in
            // Completion handler
            self.loadView?.removeFromSuperview()
            
            if (success) {
                self.successfulSignUp(userUID: userUID!)
            } else {
                // Cancel load UI & show error
                self.signupError()
            }
        }
    }
    
    func successfulSignUp(userUID: String!) {
        // Send user details to user object model & transition to WiFi setup (main for now)
        print("SIGN UP VC: Successfully signed user up with email")
        GDoorUser.sharedInstance.createNewUser(name: userName,
                                               email: userEmail,
                                               password: userPassword,
                                               userUID: userUID)
        transitionToMainStory()
    }
    
    func transitionToMainStory() {
        // Transition to WiFi set up (but home screeb for now)
        let mainStory = UIStoryboard(name: "Main", bundle: nil)
        let rootVC = mainStory.instantiateInitialViewController()
        
        present(rootVC!, animated: true, completion: nil)
    }
    
    @IBAction func dissmissKeyboard() {
        view.endEditing(true)
    }
    
    // MARK: - Error Handling -
    
    func signupError() {
        // Show error label
        print("SIGN UP VC: Failed to sign user up with email.")
        
        let indexPath = IndexPath.init(row: 4, section: 0)
        let cell = signupForm.cellForRow(at: indexPath) as? InfoTextCell
        cell?.userInfo.text = "Signup error - please try again."
        cell?.userInfo.isHidden = false
    }
    
    
    
}
