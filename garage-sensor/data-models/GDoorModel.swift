//
//  GDoorModel.swift
//  garage-sensor
//
//  Created by Josh Perry on 2018/04/10.
//  Copyright © 2018 IoT South Africa. All rights reserved.
//

import Foundation
import AWSIoT

protocol DoorStateProtocol: class {
    func doorStateUpdated()
}

protocol SensorStateProtocol: class {
    func sensorStateUpdated()
    func sensorLanIPError();
}

enum DoorStateEnum: Int {
    case UNKNOWN = -1
    case OPEN = 0
    case CLOSED = 1
    case ADD_SENSOR = 2
}

class GDoorModel: NSObject, GDoorPubSubDelegate {
    // Constants
    let profileKeys = dbProfileKeys()
    let sensorDBKeys = dbSensorKeys()
    
    // Properties
    var pubsubClient: GDoorPubSub?
    var doorState: String! = "Unknown"
    var doorStateEnum: DoorStateEnum! = DoorStateEnum.UNKNOWN
    var networkState: String! = "Sensor Connecting"
    var lastPing: Date?
    var networkDown: Date?
    var sensorUID: String?
    var modelInitialised: Bool! = false
    
    // Interfaces
    weak var doorStateDelegate: DoorStateProtocol?
    weak var sensorStateDelegate: SensorStateProtocol?
    
    // MARK: - Initializations -
    // Singleton - there is only 1 door ;)
    static let main = GDoorModel()
    private override init() {
        super.init()
        print("GDOOR: Data model created")
        pubsubClient = GDoorPubSub.initWithDelegate(newDelegate: self)
        pubsubClient!.connectToDeviceGateway()
    }
    
    // Requests the sensor Data from the client API
    func initializeModel(completion: @escaping (_ success: Bool?,_ failureMessage: String?,_ error: Error?) -> Void) {
        print("GDOOR: Initializing sensor data")
        let api = GDoorAPI()
        let userUID = GDoorUser.sharedInstance.userUID!
        api.getSensorData(userUID: userUID) { (sensorData, error) in
            if (error != nil) {
                completion(false, error!.localizedDescription, error!)
                return
            }
            
            self.setSensorData(sensorData: sensorData!)
            completion(true, nil, nil)
        }
    }
    
    func updateModel() {
        print("GDOOR: Updating model")
        let api = GDoorAPI()
        let userUID = GDoorUser.sharedInstance.userUID!
        api.getSensorData(userUID: userUID) { (sensorData, error) in
            if (error != nil) {
                print("GDOOR: Failed to updat model => \(String(describing: error))")
                return
            }
            
            self.setSensorData(sensorData: sensorData!)
            DispatchQueue.main.async {
                self.doorStateDelegate?.doorStateUpdated()
                self.sensorStateDelegate?.sensorStateUpdated()
            }
        }
    }
    
    // MARK: - Local data handling -
    
    func setSensorUID(newUID: String!) {
        sensorUID = newUID
    }
    
    func setSensorData(sensorData: [String:Any]!) {
        // Check if the user has a sensor or not
        sensorUID = sensorData[sensorDBKeys.SENSOR_UID] as? String
        if (sensorUID == "None") {
            print("GDOOR: No sensor linked to user account")
            doorState = "Add New"
            doorStateEnum = DoorStateEnum.ADD_SENSOR
            return
        }
        
        networkState = (sensorData[sensorDBKeys.ONLINE] as! Bool) ? "Sensor Online" : "Sensor Offline"
        doorState = (sensorData[sensorDBKeys.DOOR_STATE] as! String).capitalizingFirstLetter()
        
        // Date handling
        let dateFormatter = ISO8601DateFormatter()
        lastPing = dateFormatter.date(from: (sensorData[sensorDBKeys.LAST_PING] as! String))
        networkDown = dateFormatter.date(from: (sensorData[sensorDBKeys.NETWORK_DOWN] as! String))
        
        if (doorState == "Unknown")     { doorStateEnum = DoorStateEnum.UNKNOWN }
        else if (doorState == "Open")   { doorStateEnum = DoorStateEnum.OPEN}
        else if (doorState == "Closed") { doorStateEnum = DoorStateEnum.CLOSED }
        else { print("DOOR MODEL: Error - undefined door state") }
    }
    
    // MARK: - Pubsub delegate handling -
    
    func sensorDataUpdated() {
        print("GDOOR: Sensor model updated, checking database")
        updateModel()
    }
    
    func connectionStateUpdate(newState: AWSIoTMQTTStatus) {
        // Handle
    }
}














