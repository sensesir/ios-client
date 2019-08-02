//
//  GDoorPubSub.swift
//  garage-sensor
//
//  Created by Josh Perry on 2019/06/28.
//  Copyright © 2019 IoT South Africa. All rights reserved.
//

import Foundation
import AWSIoT
import AwaitKit
import PromiseKit

protocol GDoorPubSubDelegate {
    func connectionStateUpdate(newState: AWSIoTMQTTStatus)
    func sensorDataUpdated()
    func sensorRSSIUpdated(rssi: Float)
}

class GDoorPubSub: NSObject {
    var dataManager: AWSIoTDataManager?
    var delegate: GDoorPubSubDelegate?
    
    override init() {
        print("PUBSUB: Initializing AWS IoT Pubsub client")
        super.init()
        initAWSCreds()
    }
    
    static func initWithDelegate(newDelegate: GDoorPubSubDelegate) -> GDoorPubSub {
        let gdoorPubsub = GDoorPubSub()
        gdoorPubsub.delegate = newDelegate
        return gdoorPubsub                          // Ensure pointer ref is maintained ??
    }
    
    // MARK: - AWS Credential handling -
    
    func initAWSCreds() {
        let credentials = AWSCognitoCredentialsProvider(regionType:.EUWest1, identityPoolId: env.AWS_IDENTITY_POOL_ID)
        let configuration = AWSServiceConfiguration(region:.EUWest1, credentialsProvider: credentials)
        AWSIoT.register(with: configuration!, forKey: env.AWS_PUBSUB_KEY)
        initializeDataManager(credentials: credentials)
    }
    
    func getAWSClientId() -> Promise<String> {
        return Promise<String> { seal in
            let credentials = AWSCognitoCredentialsProvider(regionType:.EUWest1, identityPoolId: env.AWS_IDENTITY_POOL_ID)
            
            credentials.getIdentityId().continueWith(block: { (task:AWSTask<NSString>) -> Any? in
                if let error = task.error as NSError? {
                    print("PUBSUB: Failed to get client ID => \(error)")
                    seal.reject(error)
                    return nil
                }
                
                // print("PUBSUB: Got client ID => \(String(describing: task.result))")
                let clientId = task.result! as String
                seal.fulfill(clientId)
                return nil  // Just the way AWSTask is set up -> requires a return from closure
            })
        }
    }
    
    // MARK: - IoT -
    
    func initializeDataManager(credentials: AWSCredentialsProvider) {
        let iotEndPoint = AWSEndpoint(urlString: env.AWS_IOT_ENDPOINT)
        let iotDataConfiguration = AWSServiceConfiguration(
            region: env.AWS_REGION,
            endpoint: iotEndPoint,
            credentialsProvider: credentials
        )
    
        AWSIoTDataManager.register(with: iotDataConfiguration!, forKey: env.AWS_IOT_DATA_MANAGER_KEY)
        dataManager = AWSIoTDataManager(forKey: env.AWS_IOT_DATA_MANAGER_KEY)
    }
    
    func connectToDeviceGateway() {
        
        func mqttEventCallback(_ status: AWSIoTMQTTStatus ) {
            switch status {
            case .connecting: print("PUBSUB: Connecting AWS IoT")
            case .connected:
                print("PUBSUB: Connected to AWS IoT")
                self.registerSubscriptions()
            case .connectionError: print("PUBSUB: AWS IoT connection error")
            case .connectionRefused: print("PUBSB: AWS IoT connection refused")
            case .protocolError: print("PUBSUB: AWS IoT protocol error")
            case .disconnected: print("PUBSUB: AWS IoT disconnected")
            case .unknown: print("PUBSUB: AWS IoT unknown state")
            default: print("PUBSUB: Error - unknown MQTT state")
            }
            
            self.delegate?.connectionStateUpdate(newState: status)
        }
        
        // Ensure background thread
        DispatchQueue.global(qos: .background).async {
            do {
                let clientId = try await(self.getAWSClientId())
                print("PUBSUB: Attempting to connect to IoT device gateway with ID = \(clientId)")
                self.dataManager?.connectUsingWebSocket(withClientId: clientId,
                                                        cleanSession: true,
                                                        statusCallback: mqttEventCallback)
                
            } catch {
                print("PUBSUB: Error, failed to connect to device gateway")
                print(error)
                self.delegate?.connectionStateUpdate(newState: AWSIoTMQTTStatus.connectionError)
            }
        }
    }
    
    func registerSubscriptions() {
        func messageReceived(payload: Data) {
            let payloadDictionary = GDUtilities.shared.jsonDataToDict(jsonData: payload)
            self.handleEvent(payload: payloadDictionary)
        }
        
        let doorStateChangeTopic = topicSubDoorStateChanges()
        let connectedTopic = topicConnected()
        let disconnectedTopic = topicDisconnected()
        let rssiTopic = topicRSSIEvent()
        let topicArray = [doorStateChangeTopic, connectedTopic, disconnectedTopic, rssiTopic]
        
        for topic in topicArray {
            print("PUBSUB: Registering subscription to => \(String(describing: topic))")
            dataManager!.subscribe(toTopic: topic!,                                 // Should fail hard if topic is nil (no user UID)
                                   qoS: .messageDeliveryAttemptedAtLeastOnce,
                                   messageCallback: messageReceived)
            }
    }
    
    func assessMQTTConnection() {
        // Check if we're connected to IoT
        let mqttStatus = dataManager?.getConnectionStatus()
        if (mqttStatus == .disconnected) {
            print("PUBSUB: Disconnected from IoT, attempting reconnection")
            dataManager?.disconnect()
            connectToDeviceGateway()
        }
    }
    
    // MARK: - Topic generators -
    
    func topicSubDoorStateChanges() -> String? {
        // target/uid/version/category/descriptor
        let target = env.MQTT_TARGET_MOBILE_CLIENT
        let uid = GDoorUser.sharedInstance.userUID
        let softwareVersion = "v" + GDUtilities.getMajorVersionNumber()
        let category = env.MQTT_SUB_EVENT
        let descriptor = env.MQTT_SUB_DOOR_STATE_CHANGE
        
        if (uid != nil) {
            let topic = "\(target)/\(uid!)/\(softwareVersion)/\(category)/\(descriptor)"
            return topic
        } else {
            return nil
        }
    }
    
    func topicDisconnected() -> String? {
        let target = env.MQTT_TARGET_MOBILE_CLIENT
        let uid = GDoorUser.sharedInstance.userUID
        let softwareVersion = "v" + GDUtilities.getMajorVersionNumber()
        let category = env.MQTT_SUB_EVENT
        let descriptor = env.MQTT_SUB_DISCONNECT
        
        if (uid != nil) {
            let topic = "\(target)/\(uid!)/\(softwareVersion)/\(category)/\(descriptor)"
            return topic
        } else {
            return nil
        }
    }
    
    func topicConnected() -> String? {
        let target = env.MQTT_TARGET_MOBILE_CLIENT
        let uid = GDoorUser.sharedInstance.userUID
        let softwareVersion = "v" + GDUtilities.getMajorVersionNumber()
        let category = env.MQTT_SUB_EVENT
        let descriptor = env.MQTT_SUB_CONNECTED
        
        if (uid != nil) {
            let topic = "\(target)/\(uid!)/\(softwareVersion)/\(category)/\(descriptor)"
            return topic
        } else {
            return nil
        }
    }
    
    func topicRSSIEvent() -> String? {
        let target = env.MQTT_TARGET_MOBILE_CLIENT
        let uid = GDoorUser.sharedInstance.userUID
        let softwareVersion = "v" + GDUtilities.getMajorVersionNumber()
        let category = env.MQTT_SUB_EVENT
        let descriptor = env.MQTT_SUB_RSSI
        
        if (uid != nil) {
            let topic = "\(target)/\(uid!)/\(softwareVersion)/\(category)/\(descriptor)"
            return topic
        } else {
            return nil
        }
    }
    
    func topicRSSICommand() -> String? {
        let target = env.MQTT_TARGET_SENSOR
        let uid = GDoorModel.main.sensorUID
        let softwareVersion = "v1" // Set somewhere
        let category = env.MQTT_PUB_COMMAND
        let descriptor = env.MQTT_SUB_RSSI
        
        if (uid != nil) {
            let topic = "\(target)/\(uid!)/\(softwareVersion)/\(category)/\(descriptor)"
            return topic
        } else {
            return nil
        }
    }
    
    // MARK: - Handling events -
    
    func handleEvent(payload: [String:Any]) {
        if (GDoorUser.sharedInstance.userUID == nil) {
            print("PUBSUB: Received event without user being initialized, ignoring...")
            return
        }
        
        let eventUserUID = payload["userUID"] as! String
        if (GDoorUser.sharedInstance.userUID! != eventUserUID) {
            print("PUBSUB: Error - received message for incorrect user => \(eventUserUID)")
            return
        }
        
        let event = payload["event"] as! String
        if (event == env.MQTT_SUB_DOOR_STATE_CHANGE ||
            event == env.MQTT_SUB_CONNECTED ||
            event == env.MQTT_SUB_DISCONNECT) {
            print("PUBSUB: Received message of event => \(event)")
            delegate?.sensorDataUpdated()
        } else if (event == env.MQTT_SUB_RSSI) {
            // Different kind of delegate update [different view controller]
            let rssi = getRSSIValue(payload: payload)
            delegate?.sensorRSSIUpdated(rssi: rssi)
        }
        
        else {
            print("PUBSUB: Warning, unknown event type \(event)")
        }
    }
    
    // MARK: - Publish events -
    
    func refreshRSSI(sensorUID: String) {
        let topic = topicRSSICommand()
        let payload = ["sensorUID": sensorUID, "command": "rssi"]           // Use constants
        let serialPayload = GDUtilities.dictToJSONSerial(payload: payload)
        
        if (topic == nil || serialPayload == nil) {
            print("PUBSUB: Failed to generate topic/payload for rssi event")
            // Bugsnag **
            return
        }
        
        dataManager?.publishData(serialPayload!,
                                 onTopic: topic!,
                                 qoS: .messageDeliveryAttemptedAtLeastOnce)
    }
    
    func getRSSIValue(payload: [String: Any]) -> Float {
        var rssiFloat = payload["rssi"] as? Float
        if (rssiFloat == nil) {
            // Old type = NSNumber
            rssiFloat = (payload["rssi"] as! NSNumber).floatValue
        }
        
        return rssiFloat!
    }
}
