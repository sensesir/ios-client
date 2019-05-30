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

class GDoorModel: NSObject {
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
    weak var doorStateDelegate: DoorStateProtocol?
    weak var sensorStateDelegate: SensorStateProtocol?
    
    // MARK: - Initializations -
    // Singleton - there is only 1 door ;)
    static let main = GDoorModel()
    private override init() {
        super.init()
        print("GDOOR: Data model created")

    }
    
    
    
}














