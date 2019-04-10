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
let userFirstNameKey    = "kUserFirstName"
let userLastNameKey     = "kUserLastName"
let userEmailKey        = "kUserEmail"
let userPasswordKey     = "kUserPassword"
let signupDateKey       = "kSignupDate"
let uidKey              = "kUID"
let userAddressKey      = "kUserAddressKey"
let userMobileNumKey    = "kUserMobileNum"
let localTokenKey       = "kLocalToken"

class GDoorUser: NSObject {
    // Class level properties
    var userFirstName: String?
    var userLastName: String?
    var userEmail: String?
    var userPassword: String?
    let appVersion: String! = Bundle.main.infoDictionary!["CFBundleShortVersionString"] as? String
    var signupDate: Int?
    var uid: String?
    var userAddress: String?
    var userMobileNum: String?
    var localToken: Bool! = false
    
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
    
    func userHasToken() -> Bool {
        // Simple wrapper to check if the user has data
        if (localToken) {
            return true;
        } else{
            return false;
        }
    }
    
    // MARK: - Update data -
    
    func createNewUser(name: String!,
                       email: String!,
                       password: String!,
                       userUID: String!){
        
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
        uid = userUID
        localToken = true
        
        // Log this as the moment the user signed up
        signupDate = GDUtilities.shared.generateTimeStampForNow()
        
        // Persist data & update database
        persistData()
        createUserDBProfile()
    }
    
    // MARK: - Database interface -
    
    func createUserDBProfile() {
        // Method will create a database profile for the user
        // Create a dictionary
        var userProfile = [dbKeys.UserFirstNameKey:         userFirstName!,
                           dbKeys.UserEmailKey:             userEmail!,
                           dbKeys.ActiveDayKey:             1,
                           dbKeys.DoorCommandsKey:          0,
                           dbKeys.AppVersionKey:            appVersion,
                           dbKeys.CityKey:                  "Unknown",
                           dbKeys.CountryKey:               "Unknown",
                           dbKeys.DoorStateKey:             2,
                           dbKeys.LastIPUpdateKey:          0,
                           dbKeys.LastSeenKey:              signupDate!,
                           dbKeys.NetworkReconnKey:         0,
                           dbKeys.PremiumKey:               false,
                           dbKeys.RemoteIPAddressKey:       "",
                           dbKeys.SensorNetworkStateKey:    "offline",
                           dbKeys.SignupDateKey:            signupDate!,
                           dbKeys.UIDKey:                   uid!,
                           dbKeys.UserAddressKey:           "Unknown"] as [String:Any]
        
        // See of there's a last name to add
        if (userLastName != nil) {
            userProfile[dbKeys.UserLastNameKey] = userLastName
        } else {
            userProfile[dbKeys.UserLastNameKey] = ""
        }
        
        // Send the dictionar up to Firebase!
        let profilePath = "users/" + uid!
        let firebaseInterface = FirebaseInterface()
        firebaseInterface.writeToDatabase(writePath: profilePath, value: userProfile)
        print("USER: Writing user profile to DB = ")
        print(userProfile)
    }
    
    func updateLastSeenTime() {
        if ((uid?.count == 28) && (localToken)) {
            // Update the DB
            let firebaseInterface = FirebaseInterface()
            let lastSeenPath = "users/" + uid! + "/lastSeen"
            let lastSeenTime = GDUtilities.shared.generateTimeStampForNow()
            
            firebaseInterface.writeToDatabase(writePath: lastSeenPath, value: lastSeenTime)
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
            print("USER: User not logged in")
        }
    }
    
    
}
