//  Class to represent the user data and operate on it
//
//  GDoorUser.swift
//  garage-sensor
//
//  Created by Josh Perry on 2018/04/09.
//  Copyright © 2018 IoT South Africa. All rights reserved.
//

import Foundation

// Constants
// local keys
let userFirstNameKey    = "userFirstName"
let userLastNameKey     = "userLastName"
let userEmailKey        = "userEmail"
let userPasswordKey     = "userPassword"
let signupDateKey       = "signupDate"
let uidKey              = "userUID"
let userAddressKey      = "userAddressKey"
let userMobileNumKey    = "userMobileNum"

class GDoorUser: NSObject {
    // Class level properties
    var userFirstName: String?
    var userLastName: String?
    var userEmail: String?
    var userPassword: String?
    let appVersion: String! = Bundle.main.infoDictionary!["CFBundleShortVersionString"] as? String
    var signupDate: Int?
    var userUID: String?
    var userAddress: String?
    var userMobileNum: String?
    
    // Manager object & DB keys
    let dataManager: UserDefaults!
    let dbKeys = dbProfileKeys()
    
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
    
    func createNewUser(name: String!,
                       email: String!,
                       password: String!,
                       completion: @escaping (_ newUserUID: String?, _ error: Error?) -> Void) {
        
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
        
        createUserDBProfile { (userUID, error) in
            if (error != nil) {
                print("USER: Failed to create profile in DB => \(String(describing: error))")
                // Todo: call method on UI, delegate callback
                return
            }
            
            self.persistData()
            print("USER: Completed new user creation")
        }
    }
    
    // MARK: - Database interface -
    
    func createUserDBProfile(completion: @escaping (_ newUserUID: String?,_ error: Error?) -> Void) {
        // Method will create a database profile for the user
        // Create a dictionary
        var userProfile = [dbKeys.UserFirstNameKey: userFirstName!,
                           dbKeys.UserEmailKey:     userEmail!,
                           dbKeys.AppVersionKey:    appVersion] as [String:String]
        
        // See of there's a last name to add
        if (userLastName != nil) { userProfile[dbKeys.UserLastNameKey] = userLastName }
        else { userProfile[dbKeys.UserLastNameKey] = "" }
        
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
            api.updateLastSeen(userUID: userUID)
        }
    }
    
    // MARK: - Disk Hanlding -
    
    func persistData() {
        // Write all data to disk
        print("USER: Writing data to local storage")
        if (userFirstName != nil)   {dataManager.set(userFirstName, forKey: userFirstNameKey)}
        if (userLastName != nil)    {dataManager.set(userLastName, forKey: userLastNameKey)}
        if (userEmail != nil)       {dataManager.set(userEmail, forKey: userEmailKey)}
        if (userPassword != nil)    {dataManager.set(userPassword, forKey: userPasswordKey)}
        if (signupDate != nil)      {dataManager.set(signupDate, forKey: signupDateKey)}
        if (uid != nil)             {dataManager.set(uid, forKey: uidKey)}
        if (userAddress != nil)     {dataManager.set(userAddress, forKey: userAddressKey)}
        if (userMobileNum != nil)   {dataManager.set(userMobileNum, forKey: userMobileNumKey)}
        
        // Save the token
        dataManager.set(localToken, forKey: localTokenKey)
    }
    
    // Attempt to load user vars from memory
    private func attemptToLoadUserData() {
        localToken = dataManager.bool(forKey: localTokenKey)
        if (localToken) {
            // User has access and should have data
            print("USER: Loading data from local storage")
            userFirstName   = dataManager.string(forKey: userFirstNameKey)
            userLastName    = dataManager.string(forKey: userLastNameKey)
            userEmail       = dataManager.string(forKey: userEmailKey)
            userPassword    = dataManager.string(forKey: userPasswordKey)
            signupDate      = dataManager.integer(forKey: signupDateKey)
            uid             = dataManager.string(forKey: uidKey)
            userAddress     = dataManager.string(forKey: userAddressKey)
            userMobileNum   = dataManager.string(forKey: userMobileNumKey)
        }
            
        else{
            print("USER: Doug not logged in - force it")
            loadDougsData()
        }
    }
    
    private func loadDougsData() {
        localToken = true
        userFirstName = "TestUser_"
        userLastName = "0"
        userEmail = "peza@testing.com"
        userPassword = "admin123"
        signupDate = GDUtilities.shared.generateTimeStampForNow()
        uid = "JPpTrZcb30WoxUgRAAdsk6XiuGt2"
        
        // Auth with Firebase [temp]
        let authInterface: FirebaseAuthInterface! = FirebaseAuthInterface.init()
        
        // Email method
        
        // Anonymour method
        authInterface.authAnonymousUser { (success, userUID, error) in
            if (success) {
                print("GDOOR: Sign in success with UID => ", userUID!)
                self.persistData()
            } else {
                print("GDOOR: Sign in failure")
            }
        }
    }
}
