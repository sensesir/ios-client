//
//  IoTPubSub.swift
//  garage-sensor
//
//  Created by Josh Perry on 2019/06/12.
//  Copyright © 2019 IoT South Africa. All rights reserved.
//

import Foundation
import AWSIoT
import AWSMobileClient

class IoTPubSub: NSObject {
    var connected: Bool! = false
    
    @objc var iotDataManager: AWSIoTDataManager!;
    @objc var iotManager: AWSIoTManager!;
    @objc var iot: AWSIoT!
    
    func initAWSIoT() {
        AWSMobileClient.sharedInstance().initialize { (userState, error) in
            guard error == nil else {
                print("Failed to initialize AWSMobileClient. Error: \(error!.localizedDescription)")
                return
            }
            print("AWSMobileClient initialized.")
        }
        
        let iotEndPoint = AWSEndpoint(urlString: env.IOT_ENDPOINT)
        let iotConfiguration = AWSServiceConfiguration(region: env.AWS_REGION, credentialsProvider: AWSMobileClient.sharedInstance())
        let iotDataConfiguration = AWSServiceConfiguration(region: env.AWS_REGION,
                                                           endpoint: iotEndPoint,
                                                           credentialsProvider: AWSMobileClient.sharedInstance())
        
        AWSServiceManager.default().defaultServiceConfiguration = iotConfiguration
        iotManager = AWSIoTManager.default()
        iot = AWSIoT.default()
        AWSIoTDataManager.register(with: iotDataConfiguration!, forKey: "ASWIoTDataManager")
        iotDataManager = AWSIoTDataManager(forKey: "ASWIoTDataManager")
    }
    
    func connectToDeviceGateway() {
        func mqttEventCallback( _ status: AWSIoTMQTTStatus )
        {
            DispatchQueue.main.async {
                print("connection status = \(status.rawValue)")
                switch(status) {
                case .connecting: print("Connecting...")
                case .connected:
                    print("Connected")
                    self.connected = true
                case .disconnected: print("Disconnected")
                case .connectionRefused: print("Connection Refused")
                case .connectionError: print("Connection Error")
                case .protocolError: print("Protocol Error")
                default: print("Unknown State")
                }
            }
        }
        
        if (!connected) {
            let defaults = UserDefaults.standard
            
            let myBundle = Bundle.main
            let myImages = myBundle.paths(forResourcesOfType: "p12" as String, inDirectory:nil)
            let uuid = UUID().uuidString;
            
            if (myImages.count > 0) {
                // At least one PKCS12 file exists in the bundle.  Attempt to load the first one
                // into the keychain (the others are ignored), and set the certificate ID in the
                // user defaults as the filename.  If the PKCS12 file requires a passphrase,
                // you'll need to provide that here; this code is written to expect that the
                // PKCS12 file will not have a passphrase.
                if let data = try? Data(contentsOf: URL(fileURLWithPath: myImages[0])) {
                    print("IOT PUBSUB: Found certificate file")
                    
                    if AWSIoTManager.importIdentity( fromPKCS12Data: data, passPhrase:"Redhcp2013!", certificateId:myImages[0]) {
                        // Set the certificate ID and ARN values to indicate that we have imported
                        // our identity from the PKCS12 file in the bundle.
                        defaults.set(myImages[0], forKey:"certificateId")
                        defaults.set("from-bundle", forKey:"certificateArn")
                        print("Using certificate: \(myImages[0])")
                        
                        print("Certificate ID = \(myImages[0])")
                        
                        DispatchQueue.main.async {
                            
                            self.iotDataManager.connect( withClientId:   "mobile-client-ios",
                                                         cleanSession:   true,
                                                         certificateId:  myImages[0],
                                                         statusCallback: mqttEventCallback)
                    
                            /*
                            self.iotDataManager.connectUsingWebSocket(withClientId: "mobile-client-ios",
                                                                      cleanSession: true,
                                                                      statusCallback: mqttEventCallback)
                             */
                        }
                    }
                }
            }
        }
        
        else {
            
        }
    }
}
