//
//  FirebaseInterface.swift
//  garage-sensor
//
//  Created by Josh Perry on 2018/04/09.
//  Copyright © 2018 IoT South Africa. All rights reserved.
//

import Foundation
import Firebase

// Firebase Interface Protocol
protocol FirebaseDBDelegate: class {
    func receivedListenerUpdate(data: Any, key: String)
}

class FirebaseInterface: NSObject {
    // Class level props
    var rootRef: DatabaseReference!
    var childRef: DatabaseReference!
    
    // Delegate
    weak var listenerDelegate: FirebaseDBDelegate?
    
    // Initializer
    override init(){
        // Custom initializer - protects against DB overwrites
        print("FIREBASE INTERACE: Created instance")
        rootRef = Database.database().reference();
    }
    
    // MARK: - Write methods -
    
    func writeToDatabase(writePath: String!, value: Any) {
        // Create a DB ref
        let dbRef = rootRef.child(writePath)
        dbRef.setValue(value)
    }
    
    // Create a listener
    func listenForPath(path: String!, delegate: FirebaseDBDelegate){
        // Create the DB ref
        childRef = rootRef.child(path)
        
        childRef.observe(DataEventType.value) { (snapshot) in
            // Listener execution
            if let newData = snapshot.value {
                // Got new data
                print("FIREBASE INTERFACE: Received new data for listener with path", path)
                delegate.receivedListenerUpdate(data: newData, key: snapshot.key);
            }
            
            else{
                print("FIREBASE INTERFACE: Data deleted at path", path);
            }
        }
        
        print("FIREBASE INTERFACE: Added new listener at path", path);
    }
}
