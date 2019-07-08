//  Class to represent the user data and operate on it
//
//  GDoorUser.swift
//  garage-sensor
//
//  Created by Josh Perry on 2018/04/09.
//  Copyright © 2018 IoT South Africa. All rights reserved.
//

import Foundation
import Bugsnag

class GDoorUser: NSObject {
    // Class level properties
    var userFirstName: String?
    var userLastName: String?
    var userEmail: String?
    var userPassword: String?
    let appVersion: String! = Bundle.main.infoDictionary!["CFBundleShortVersionString"] as? String
    var userUID: String?
    var userAddress: String?
    var userMobileNum: String?
    var sensorUID: String?
    
    // Manager object & DB keys
    let dataManager: UserDefaults!
    let profileKeys = dbProfileKeys()
    
    // MARK: - Initialization -
    static let sharedInstance = GDoorUser()
    private override init() {
        // Get user defaults manager
        dataManager = UserDefaults.standard
        
        // Create the instance once only
        super.init()
        attemptToLoadUserData()
    }
    
    func userSignedIn() -> Bool {
        // Simple wrapper to check if the user has data
        if (userUID != nil) { return true }
        else { return false }
    }
    
    // MARK: - Update data -
    
    func setUserProfile(name: String!,
                       email: String!,
                       password: String!,
                       newUserUID: String!) {
        
        // Try capture a first and last name
        let spaceSet = CharacterSet.init(charactersIn: " ")
        let nameSet = CharacterSet.init(charactersIn: name)
        
        if nameSet.isSuperset(of: spaceSet) {
            // There is a space, separate them
            let nameArray = name.components(separatedBy: spaceSet)
            userFirstName = nameArray.first
            userLastName = nameArray.last
        } else {
            // No separation
            userFirstName = name
        }
        
        // Set simple props
        userEmail = email
        userPassword = password
        userUID = newUserUID
        
        self.persistData()
        print("USER: Completed setting user data")
    }
    
    func initDataFromLogin(userData: [String: Any]!) {
        
        userFirstName = userData[profileKeys.UserFirstNameKey] as? String
        userEmail = userData[profileKeys.EmailKey] as? String
        userMobileNum = userData[profileKeys.UserPasswordKey] as? String
        userLastName = userData[profileKeys.UserLastNameKey] as? String
        userUID = userData[profileKeys.UIDKey] as? String
        sensorUID = userData[profileKeys.SensorUIDKey] as? String
        
        self.persistData()
    }
    
    // MARK: - Database interface -
    
    func createUserDBProfile(completion: @escaping (_ newUserUID: String?,_ error: Error?) -> Void) {
        // Method will create a database profile for the user
        // Create a dictionary
        var userProfile = [profileKeys.UserFirstNameKey: userFirstName!,
                           profileKeys.EmailKey:         userEmail!,
                           profileKeys.AppVersionKey:    appVersion] as [String:String]
        
        // See of there's a last name to add
        if (userLastName != nil) { userProfile[profileKeys.UserLastNameKey] = userLastName }
        else { userProfile[profileKeys.UserLastNameKey] = "" }
        
        // Send the data to the client API
        print("USER: Writing user profile to DB = ")
        print(userProfile)
        let api = GDoorAPI()
        api.createNewUser(userData: userProfile) { (userUID, error) in
            if (error != nil) { completion(nil, error) }
            else { completion(userUID, nil) }
        }
    }
    
    func updateLastSeenTime() {
        if (userUID?.count == env.UID_LENGTH) {
            let api = GDoorAPI()
            api.updateLastSeen(userUID: userUID, completion: nil)
        }
    }
    
    // MARK: - Disk Hanlding -
    
    func persistData() {
        // Write all data to disk
        print("USER: Writing data to local storage")
        if (userFirstName != nil) { dataManager.set(userFirstName, forKey: profileKeys.UserFirstNameKey) }
        if (userLastName != nil)  { dataManager.set(userLastName, forKey: profileKeys.UserLastNameKey) }
        if (userEmail != nil)     { dataManager.set(userEmail, forKey: profileKeys.EmailKey) }
        if (userPassword != nil)  { dataManager.set(userPassword, forKey: profileKeys.UserPasswordKey) }
        if (userUID != nil)       { dataManager.set(userUID, forKey: profileKeys.UIDKey) }
        if (userAddress != nil)   { dataManager.set(userAddress, forKey: profileKeys.UserAddressKey) }
        if (userMobileNum != nil) { dataManager.set(userMobileNum, forKey: profileKeys.UserMobileNumKey) }
        
        setBugsnapUserInfo()
    }
    
    // Attempt to load user vars from memory
    private func attemptToLoadUserData() {
        userUID = dataManager.string(forKey: profileKeys.UIDKey)
        
        if (userUID != nil) {
            // User has access and should have data
            print("USER: Loading data from local storage")
            userFirstName   = dataManager.string(forKey: profileKeys.UserFirstNameKey)
            userLastName    = dataManager.string(forKey: profileKeys.UserLastNameKey)
            userEmail       = dataManager.string(forKey: profileKeys.EmailKey)
            userPassword    = dataManager.string(forKey: profileKeys.UserPasswordKey)
            userAddress     = dataManager.string(forKey: profileKeys.UserAddressKey)
            userMobileNum   = dataManager.string(forKey: profileKeys.UserMobileNumKey)
            
            setBugsnapUserInfo()
        }
            
        else{
            print("USER: No user data locally")
        }
    }
    
    func setBugsnapUserInfo() {
        let userFullName = (userLastName == nil) ? userFirstName : "\(userFirstName!) \(userLastName!)"
        Bugsnag.configuration()?.setUser(userUID,
                                         withName: userFullName,
                                         andEmail: userEmail)
    }
}
