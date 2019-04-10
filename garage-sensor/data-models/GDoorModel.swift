//
//  GDoorModel.swift
//  garage-sensor
//
//  Created by Josh Perry on 2018/04/10.
//  Copyright © 2018 IoT South Africa. All rights reserved.
//

import Foundation

protocol DoorStateProtocol: class {
    func doorStateUpdated()
}

protocol SensorStateProtocol: class {
    func sensorStateUpdated()
    func sensorLanIPError();
}

class GDoorModel: NSObject, FirebaseDBDelegate {
    // Constants
    let profileKeys = dbProfileKeys()
    
    // Properties
    var doorState: Int! = 2
    var sensorConnState: String! = "unknown"
    var assignedLoaclIP: String?
    var targetLocalIP: String?
    var initialDoorStateConfirmed: Bool! = false
    var initialSensorStateConfirmed: Bool! = false
    
    // Interfaces
    let firebaseInterface: FirebaseInterface!
    weak var doorStateDelegate: DoorStateProtocol?
    weak var sensorStateDelegate: SensorStateProtocol?
    
    // MARK: - Initializations -
    // Singleton - there is only 1 door ;)
    static let main = GDoorModel()
    private override init() {
        firebaseInterface = FirebaseInterface()
        super.init()
        print("GDOOR: Data model created")
        
        // Initialize DB listener
        setupDatabaseListeners()
    }
    
    func setupDatabaseListeners() {
        let profilePath = "users/" + GDoorUser.sharedInstance.uid!
        let doorStatePath = profilePath + "/" + profileKeys.DoorStateKey
        let sensorConnStatePath = profilePath + "/" + profileKeys.SensorNetworkStateKey
        let assignedIPAddressPath = profilePath + "/" + profileKeys.AssignedLocalIPKey
        let targetIPAddressPath = profilePath + "/" + profileKeys.TargetStaticIPKey
        
        firebaseInterface.listenForPath(path: doorStatePath, delegate: self)
        firebaseInterface.listenForPath(path: sensorConnStatePath, delegate: self)
        firebaseInterface.listenForPath(path: assignedIPAddressPath, delegate: self)
        firebaseInterface.listenForPath(path: targetIPAddressPath, delegate: self)
        print("GDOOR: Set up database listeners for door and sensor state")
    }
    
    func assessLocalStaticIPAssignment() {
        // Assesses parity between target static IP and actual assigned IP
        if (targetLocalIP != nil && assignedLoaclIP != nil) {
            // Ensure we have a read from both DB values
            if (targetLocalIP != assignedLoaclIP){
                // Alert user that setup needs to happen again
                print("GDOOR: Sensor target IP for virtual server and assigned LAN IP not the same - alerting user of Error")
                print("GDOOR: Target IP = ", targetLocalIP!, " Assigned IP = ", assignedLoaclIP!)
                sensorStateDelegate?.sensorLanIPError()
            }
        }
    }
    
    // MARK: - DB Interface -
    
    func receivedListenerUpdate(data: Any, key: String) {
        // Delegate callback for listener
        if (key == profileKeys.DoorStateKey) {
            // Door state updated
            initialDoorStateConfirmed = true
            doorState = data as! Int
            
            // Update the delegate
            print("GDOOR: Received door state update. New state =", doorState)
            doorStateDelegate?.doorStateUpdated()
        }
        
        else if (key == profileKeys.SensorNetworkStateKey){
            initialSensorStateConfirmed = true
            let newSensorState = data as! String
            sensorConnState = newSensorState
  
            // Update delegate
            print("GDOOR: Received sensor state update. New state =", sensorConnState)
            sensorStateDelegate?.sensorStateUpdated()
        }
            
        else if (key == profileKeys.AssignedLocalIPKey){
            // Check if we have parity (if both vars have been defined)
            assignedLoaclIP = data as? String
            assessLocalStaticIPAssignment()
        } else if (key == profileKeys.TargetStaticIPKey) {
            targetLocalIP = data as? String
            assessLocalStaticIPAssignment()
        }
        
        else{
            print("GDOOR: Error - received listener update method call without valid key. Key = ", key)
        }
    }
}














