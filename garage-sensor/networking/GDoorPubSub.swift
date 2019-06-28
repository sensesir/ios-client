//
//  PubSub.swift
//  garage-sensor
//
//  Created by Josh Perry on 2019/06/20.
//  Copyright © 2019 IoT South Africa. All rights reserved.
//

import Foundation
import AWSIoT
import AWSMobileClient

class GDoorPubSub: NSObject {
    var iotDataManager: AWSIoTDataManager?
    var isInitialized: Bool! = false
    
    static let client = GDoorPubSub()
    private override init() {
        super.init()
        print("PUBSUB: Pubsub client created")
        // connectToAWSSNS()
    }
    
    func connectToIoT() {
        if (isInitialized) { return }
        
        print("PUBSUB: Initializing AWS IoT")
        let credentialProvider = AWSCognitoCredentialsProvider(regionType: env.AWS_REGION, identityPoolId: "eu-west-1:62bb7ed6-7810-4710-a296-96b5f46ba7b2")
        let configuration = AWSServiceConfiguration(region: env.AWS_REGION, credentialsProvider: credentialProvider)
        AWSIoT.register(with: configuration!, forKey: env.AWS_PUBSUB_KEY)
        initIoTDataManager(credentials: credentialProvider)
        isInitialized = true
        
        getClientId()
        connectToDeviceGateway()
    }
    
    // Need to ascertain whether this is sufficient to auth for IoT
    func awsFederatedAuthInit() {
        let credentialsProvider = AWSCognitoCredentialsProvider(regionType:.EUWest1, identityPoolId:"eu-west-1:62bb7ed6-7810-4710-a296-96b5f46ba7b2")
        let configuration = AWSServiceConfiguration(region:.EUWest1, credentialsProvider:credentialsProvider)
        AWSServiceManager.default().defaultServiceConfiguration = configuration
    }
    
    func initIoTDataManager(credentials: AWSCredentialsProvider) {
        let iotEndPoint = AWSEndpoint(urlString: "wss://anwaqu8y2zf77-ats.iot.eu-west-1.amazonaws.com/mqtt")
        let iotDataConfiguration = AWSServiceConfiguration(
            region: env.AWS_REGION,
            endpoint: iotEndPoint,
            credentialsProvider: credentials
        )
        
        AWSIoTDataManager.register(with: iotDataConfiguration!, forKey: "MyAWSIoTDataManager")
        iotDataManager = AWSIoTDataManager(forKey: "MyAWSIoTDataManager")
    }
    
    func getClientId() {
        let credentialProvider = AWSCognitoCredentialsProvider(regionType: env.AWS_REGION,
                                                               identityPoolId: "eu-west-1:62bb7ed6-7810-4710-a296-96b5f46ba7b2")
        
        credentialProvider.getIdentityId().continueWith(block: { (task:AWSTask<NSString>) -> Any? in
            if let error = task.error as? NSError {
                print("FAILED to get client ID")
                print("Error: \(error)")
                return nil
            }
            
            print("Temp: Got client ID")
            print(task)
            return nil
        })
    }
    
    func connectToDeviceGateway() {
        // eu-west-1:f3012e23-9cad-4937-8a94-8174b9c5f639
        
        func mqttEventCallback(_ status: AWSIoTMQTTStatus ) {
            print("connection status = \(status)")
            if status == .connected {
                self.iotSubscribe()
            }
        }
        
        iotDataManager?.connectUsingWebSocket(withClientId: "eu-west-1:f3012e23-9cad-4937-8a94-8174b9c5f639",
                                              cleanSession: true,
                                              statusCallback: mqttEventCallback)
    }
    
    func iotSubscribe() {
        if (iotDataManager == nil) {
            return
        }
        
        print("TEMP: Subscribing to events")
        iotDataManager!.subscribe(
            toTopic: "test",
            qoS: .messageDeliveryAttemptedAtMostOnce, /* Quality of Service */
            messageCallback: {
                (payload) ->Void in
                let stringValue = NSString(data: payload, encoding: String.Encoding.utf8.rawValue)!
                
                print("Message received: \(stringValue)")
        } )
    }
}
