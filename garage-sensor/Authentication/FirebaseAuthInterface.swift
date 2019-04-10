//
//  FirebaseAuthInterface.swift
//  garage-sensor
//
//  Created by Josh Perry on 2018/04/10.
//  Copyright © 2018 IoT South Africa. All rights reserved.
//

import Foundation
import FirebaseAuth

class FirebaseAuthInterface: NSObject {
    
    func authUserWithEmail(userName: String!,
                           email: String!,
                           password: String!,
                           completion: @escaping (_ success: Bool, _ userUID: String?, _ authError: Error?) -> Void){
        
        // Call the default firebase method
        Auth.auth().createUser(withEmail: email, password: password) { (firebaseUser, error) in
            // If all went well - return success bool and nil error
            if (firebaseUser != nil && error == nil){
                
                // Submit name change request
                let changeRequest = Auth.auth().currentUser?.createProfileChangeRequest()
                changeRequest?.displayName = userName
                
                changeRequest?.commitChanges(completion: { (nameError) in
                    if (error == nil) {
                        // All good!
                        print("FIREBASE AUTH: Successfully logged user in with email")
                        completion(true, firebaseUser!.uid, nil)
                    } else {
                        // Could not complete name change
                        completion(false, nil, nameError)
                    }
                })
            }
            
            else{
                // Error occured - check if
                print("FIREBASE AUTH: Couldn't log user in with email")
                completion(false, nil, error)
            }
        }
    }
}
