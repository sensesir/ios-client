//
//  GdoorAPI.swift
//  garage-sensor
//
//  Created by Josh Perry on 2019/05/28.
//  Copyright © 2019 IoT South Africa. All rights reserved.
//

import Foundation

class GDoorAPI: NSObject {
    
    // MARK: - Create -
    
    func createNewUser(userData: [String:String]!,
                       completion: @escaping (_ newUserUID: String?,_ error: Error?) -> Void) {
        
        let endpoint = env.CLIENT_API_ROOT_URL + env.CREATE_USER_ENDPOINT;
        let payload = try! JSONSerialization.data(withJSONObject: userData, options: [])
        let request = jsonPostReq(endpoint: endpoint, payload: payload)
        
        let postTask = URLSession.shared.dataTask(with: request) { (data, response, error) in
            if (error != nil) {
                completion(nil, error!)
            } else {
                let res = GDUtilities.shared.jsonDataToDict(jsonData: data!)
                let newUserUID = res["userUID"] as! String
                completion(newUserUID, nil)
            }
        }
        
        // Start the task
        print("API: Sending req to create new user")
        postTask.resume()
    }
    
    func updateLastSeen(userUID: String!,
                        completion: (([String: Any]?,Error?))? = nil) {
        
        let endpoint = env.CLIENT_API_ROOT_URL + env.UPDATE_LAST_SEEN
        let payload = try! JSONSerialization.data(withJSONObject: ["userUID": userUID], options: [])
        let request = jsonPostReq(endpoint: endpoint, payload: payload)
        
        let postTask = URLSession.shared.dataTask(with: request) { (data, response, error) in
            if (error != nil) {
                print("API: Failed to update last seen => \(String(describing: error))")
                if (completion != nil) { completion(nil, error!) }
            } else {
                print("API: Updated last seen")
                let res = GDUtilities.shared.jsonDataToDict(jsonData: data!)
                if (completion != nil) { completion(res, nil) }
            }
        }
        
        // Start the task (resume is misleading
        postTask.resume()
    }
    
    func jsonPostReq(endpoint: String!, payload: Data) -> URLRequest {
        let endpointUrl = URL.init(string: endpoint)
        var postReq = URLRequest(url: endpointUrl!)
        postReq.setValue("application/json", forHTTPHeaderField: "Content-Type")
        postReq.httpBody = payload
        postReq.httpMethod = "POST"
        return postReq
    }
}
