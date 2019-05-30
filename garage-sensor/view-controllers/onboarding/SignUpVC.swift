//
//  SignUpVC.swift
//  garage-sensor
//
//  Created by Josh Perry on 2018/04/09.
//  Copyright © 2018 IoT South Africa. All rights reserved.
//

import Foundation
import UIKit

enum FormType: Int {
    case SignUp = 0
    case Login = 1
}

class SignUpVC: UIViewController, UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate {
    // Controls
    let clientApi = GDoorAPI()
    let profileKeys = dbProfileKeys();
    var validUserName: Bool! = false
    var validUserEmail: Bool! = false
    var validUserPassword: Bool! = false
    var validPasswordConfirm: Bool! = false
    var nameAttempt: Bool! = false
    var emailAttepmt: Bool! = false
    var passwordAttempt: Bool! = false
    var passwordConfirmAttempt: Bool! = false
    var formType = FormType.SignUp
    
    // User info
    var userName: String?
    var userEmail: String?
    var userPassword: String?
    var userPasswordConfirm: String?
    
    // Constants
    let logoCellID: String! = "LogoCellID"
    let formSelectorCellID: String! = "FormSelectorCellID"
    let textEntryCellID: String! = "TextEntryCellID"
    let infoTextCellID: String! = "TextInfoCellID"
    let signupCellHeights = [1: 60.0, 2: 60.0, 3: 60.0, 4: 60.0, 5: 60.0, 6: 80.0]
    let loginCellHeights = [1: 60.0, 2: 60.0, 3: 60.0, 5: 60.0, 4: 80.0]
    
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
        if (formType == FormType.SignUp) { return 7 }
        return 4
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        // Switch case
        let row = indexPath.row
        if (row == 0) { return UIScreen.main.bounds.height*0.3 } // Logo cell - make 1/3 of screen
        else if (formType == FormType.SignUp) { return CGFloat(signupCellHeights[row]!) }
        else if (formType == FormType.Login)  { return CGFloat(loginCellHeights[row]!) }
        else{
            // error
            return 0;
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // Generate the correct cells for each type
        let row = indexPath.row
        var cell: UITableViewCell?
        
        if (row == 0) { cell = generateLogoCell(tableView: tableView) }
        else if (row == 1) { cell = generateFormSelectorCell(tableView: tableView) }
        else if (formType == FormType.SignUp && (2 ... 5).contains(row)) { cell = generateTextInputCell(tableView: tableView, row: row) }
        else if (formType == FormType.Login && (2 ... 3).contains(row)) { cell = generateTextInputCell(tableView: tableView, row: row) }
        else if ((formType == FormType.SignUp && row == 6) || (formType == FormType.Login && row == 4)){ cell = generateInfoTextCell(tableView: tableView) }
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
        if (cell == nil) { cell = UITableViewCell.init(style: .default, reuseIdentifier: logoCellID) }
        return cell!
    }
    
    func generateFormSelectorCell(tableView: UITableView!) -> UITableViewCell {
        var cell = tableView.dequeueReusableCell(withIdentifier: formSelectorCellID) as? FormTypeSelectorCell
        if (cell == nil) { cell = FormTypeSelectorCell.init(style: .default, reuseIdentifier: formSelectorCellID) }
        
        cell?.signUpButton.addTarget(self, action: #selector(userSelectedSignUp), for: .touchUpInside)
        cell?.loginButton.addTarget(self, action: #selector(userSelectedLogin), for: .touchUpInside)
        return cell!
    }
    
    func generateTextInputCell(tableView: UITableView!, row: Int!) -> TextEntryCell {
        // Create cell and customize the text
        var cell = tableView.dequeueReusableCell(withIdentifier: textEntryCellID) as? TextEntryCell
        if (cell == nil) {
            cell = TextEntryCell.init(style: .default, reuseIdentifier: textEntryCellID)
        }
        
        if (formType == FormType.SignUp) {
            switch row {
                case 2:
                    cell?.userEntry.text = "First & Last Name"
                    cell?.userEntry.tag = 0
                    cell?.userEntry.autocapitalizationType = .words
                case 3:
                    cell?.userEntry.text = "Email"
                    cell?.userEntry.tag = 1
                case 4:
                    cell?.userEntry.text = "Password"
                    cell?.userEntry.tag = 2
                case 5:
                    cell?.userEntry.text = "Confirm Password"
                    cell?.userEntry.tag = 3
                default: cell?.userEntry.text = "Error"
            }
        } else {
            switch row {
                case 2:
                    cell?.userEntry.text = "Email"
                    cell?.userEntry.tag = 1
                case 3:
                    cell?.userEntry.text = "Password"
                    cell?.userEntry.tag = 2
                default: cell?.userEntry.text = "Error"
            }
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
    
    @objc func userSelectedSignUp () {
        if (formType == FormType.SignUp) {
            // Already on this page
            return
        }
        
        formType = FormType.SignUp
        DispatchQueue.main.async { [weak self] in
            self?.setFormTypeUnderline(newFormType: FormType.SignUp)
            self?.resetUserData(resetFormType: FormType.Login)
            self?.signupForm.reloadData()
        }
    }
    
    @objc func userSelectedLogin () {
        if (formType == FormType.Login) {
            // Already on this page
            return
        }
        
        formType = FormType.Login
        DispatchQueue.main.async { [weak self] in
            self?.setFormTypeUnderline(newFormType: FormType.Login)
            self?.resetUserData(resetFormType: FormType.SignUp)
            self?.signupForm.reloadData()
        }
    }
    
    func setFormTypeUnderline(newFormType: FormType) {
        let cell = signupForm.cellForRow(at: IndexPath.init(row: 1, section: 0)) as! FormTypeSelectorCell
        if (newFormType == FormType.SignUp) {
            cell.signUpUnderline.isHidden = false
            cell.loginUnderline.isHidden = true
        } else {
            cell.signUpUnderline.isHidden = true
            cell.loginUnderline.isHidden = false
        }
    }
    
    func resetUserData(resetFormType: FormType) {
        // Data vars
        userName = nil
        userPassword = nil
        userEmail = nil
        userPasswordConfirm = nil
        nameAttempt = false
        emailAttepmt = false
        passwordAttempt = false
        passwordConfirmAttempt = false
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        // Check which text field it
        switch textField.tag {
            case 0: if (userName == nil) { textField.text = "" }
            case 1: if (userEmail == nil) { textField.text = "" }
            case 2:
                if (userPassword == nil) {
                    textField.text = ""
                    textField.isSecureTextEntry = true
                }
            case 3:
                if (userPasswordConfirm == nil) {
                    textField.text = ""
                    textField.isSecureTextEntry = true
                }
            default: print("SIGNUP VC: Error - invalid textfield tag")
        }
        
        
        // Hide the error label
        let indexPath = IndexPath.init(row: 4, section: 0)
        let cell = signupForm.cellForRow(at: indexPath) as? InfoTextCell
        cell?.userInfo.isHidden = true
    }
    
    func textFieldDidEndEditing(_ textField: UITextField, reason: UITextFieldDidEndEditingReason) {
        // Check validity of entry
        var recentEntryValid: Bool! = false
        
        if (formType == FormType.SignUp) {
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
            case 3:
                userPasswordConfirm = textField.text
                recentEntryValid = assessPassworkConfirmValidity(confirmPassword: textField.text!)
                passwordConfirmAttempt = true
            default:
                print("SIGN UP VC: Invalid text field")
            }
        }
        
        if recentEntryValid {
            // If the most recent check passed, scan all
            fullEntryValidityCheck()
        }
    }
    
    func fullEntryValidityCheck() {
        // Check if we have all green lights
        let row = formType == FormType.SignUp ? 6 : 5
        let indexPath = IndexPath.init(row: row, section: 0)
        let cell = signupForm.cellForRow(at: indexPath) as? InfoTextCell
        
        if (formType == FormType.SignUp) {
            if (!validUserName && nameAttempt) {
                cell?.userInfo.isHidden = false
                cell?.userInfo.text = "User name should be longer than 4 characters"
                cell?.submitButton.isHidden = true
            }
                
            else if (!validUserEmail && emailAttepmt){
                cell?.userInfo.isHidden = false
                cell?.userInfo.text = "Hmmm the email address doesn't seem quite right. Please try again."
                cell?.submitButton.isHidden = true
            }
                
            else if(!validUserPassword && passwordAttempt){
                cell?.userInfo.isHidden = false
                cell?.userInfo.text = "Password should be longer than 6 characters"
                cell?.submitButton.isHidden = true
            }
                
            else if(!validPasswordConfirm && passwordConfirmAttempt) {
                cell?.userInfo.isHidden = false
                cell?.userInfo.text = "Passwords don't match"
                cell?.submitButton.isHidden = true
            }
                
            else if (validUserName && validUserEmail && validUserPassword && validPasswordConfirm){
                print("ENTRY VC: All entries correct, exposing submit button")
                cell?.userInfo.isHidden = true
                cell?.submitButton.layer.cornerRadius = cell!.submitButton.frame.height/2
                cell?.submitButton.isHidden = false
            }
            
            else {
                print("ENTRY VC: ERROR => Unknown state of inputs")
            }
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
    
    func assessPassworkConfirmValidity(confirmPassword: String) -> Bool {
        if (confirmPassword == userPassword) {
            validPasswordConfirm = true
            return true
        }
        else {
            print("SIGN UP VC: User's confirmed password does not match")
            setErrorLabel(error: "Confirmed password does not match password entry")
            validPasswordConfirm = false
            return false
        }
    }
    
    func setErrorLabel(error: String!) {
        // Get reference to cell
        let row = formType == FormType.SignUp ? 6 : 5
        let indexPath = IndexPath.init(row: row, section: 0)
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
        
        if (formType == FormType.SignUp) {
            signUserUp(completion: { (userUID, error) in
                if (error != nil) {
                    print("ENTRY VC: Failed to created new user => \(String(describing: error))")
                    // TODO: explain error
                    self.signupError()
                } else {
                    print("ENTRY VC: Successfully created new user");
                    self.successfulSignUp(userUID: userUID)
                }
            })
        }
        
        else {
            logUserIn { (success, error) in
                if (error != nil) {
                    print("ENTRY VC: Failed to created new user => \(String(describing: error))")
                    // TODO: explain error
                } else {
                    
                }
            }
        }
    }
    
    func signUserUp(completion: @escaping (_ userUID: String?,_ error: Error?) -> Void) {
        let userData = [profileKeys.UserNameKey:     userName!,
                        profileKeys.UserPasswordKey: userPassword!,
                        profileKeys.UserEmailKey:    userEmail!]
        
        clientApi.createNewUser(userData: userData) { (userUID, error) in
            if (error != nil) { completion(nil, error) }
            else { completion(userUID, nil) }
        }
    }
    
    func logUserIn(completion: @escaping (_ success: Bool?,_ error: Error?) -> Void) {
        let userCreds = [profileKeys.UserEmailKey:    userEmail!,
                         profileKeys.UserPasswordKey: userPassword!]
        
        clientApi.logUserIn(userCreds: userCreds) { (success, error) in
            if (error != nil) { completion(false, error) }
            else { completion(true, nil) }
        }
    }
    
    func successfulSignUp(userUID: String!) {
        // Send user details to user object model & transition to WiFi setup (main for now)
        print("SIGN UP VC: Successfully user initialization")
        GDoorUser.sharedInstance.setUserProfile(name: userName,
                                                email: userEmail,
                                                password: userPassword,
                                                newUserUID: userUID)
        transitionToMainStory()
    }
    
    func succesfulLogin(userData: [String:String]!) {
        GDoorUser.sharedInstance.setUserProfile(name: userData[profileKeys.UserNameKey],
                                                email: userData[profileKeys.UserEmailKey],
                                                password: userData[profileKeys.UserPasswordKey],
                                                newUserUID: userData[profileKeys.UIDKey])
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
    
    // MARK: - Failures -
    
    func loginFailure(reason: String!) {
        print("ENTRY VC: Failed to log user in, reason => \(String(describing: reason))")
        
        let indexPath = IndexPath.init(row: 3, section: 0)
        let cell = signupForm.cellForRow(at: indexPath) as? InfoTextCell
        cell?.userInfo.text = reason
        cell?.userInfo.isHidden = false
    }
    
    // MARK: - Error Handling -
    
    func signupError() {
        // Show error label
        print("ENTRY VC: Failed to sign user up with email.")
        
        let indexPath = IndexPath.init(row: 4, section: 0)
        let cell = signupForm.cellForRow(at: indexPath) as? InfoTextCell
        cell?.userInfo.text = "Signup error - please try again."
        cell?.userInfo.isHidden = false
    }
    
    func loginError() {
        // Show error label
        print("ENTRY VC: Failed to sign user up with email.")
        
        let indexPath = IndexPath.init(row: 4, section: 0)
        let cell = signupForm.cellForRow(at: indexPath) as? InfoTextCell
        cell?.userInfo.text = "Login error - please try again."
        cell?.userInfo.isHidden = false
    }
    
    
}
