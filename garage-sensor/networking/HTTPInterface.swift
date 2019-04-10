//
//  HTTPInterface.swift
//  garage-sensor
//
//  Created by Josh Perry on 2018/04/10.
//  Copyright © 2018 IoT South Africa. All rights reserved.
//

import Foundation

class HTTPInterface: NSObject {
    // Constants
    let actuateDoorCommand: String! = "clientDoorTrigger"
    let functionsRootURL: String! = "https://us-central1-iot-za.cloudfunctions.net/"
    
    // Std HTTP const
    let contentType: String! = "Content-Type"
    let jsonType: String! = "application/json"
    
    // MARK: - Post request -
    
    func hitActuateDoorAPI(completion: @escaping (_ data: Data?, _ response: URLResponse?, _ error: Error?) -> Void) {
        // Create API endpoint URL
        let apiEndpoint = functionsRootURL + actuateDoorCommand
        let apiURL = URL.init(string: apiEndpoint)
        
        // Body to send
        let payload = ["senderUID": GDoorUser.sharedInstance.uid!]
        let payloadData = try! JSONSerialization.data(withJSONObject: payload, options: [])
        
        // Create request and set headers
        var postReq = URLRequest(url: apiURL!)
        postReq.setValue(jsonType, forHTTPHeaderField: contentType)
        postReq.httpBody = payloadData
        postReq.httpMethod = "POST"
        
        let postTask = URLSession.shared.dataTask(with: postReq) { (data, response, error) in
            // Completion handler
            completion(data, response, error)
        }
        
        // Start the task
        print("HTTP INTERFACE: Initiating POST req to trigger door")
        postTask.resume()
    }
}
