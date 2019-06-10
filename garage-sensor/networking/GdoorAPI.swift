//
//  GdoorAPI.swift
//  garage-sensor
//
//  Created by Josh Perry on 2019/05/28.
//  Copyright © 2019 IoT South Africa. All rights reserved.
//

import Foundation

class GDoorAPI: NSObject {
    
    // MARK: - User profile APIs -
    
    /**
     *  userData (# table): Required =>
     *      1. userName
     *      2. userEmail
     *      3. userPassword
     */
    
    func createNewUser(userData: [String:String]!,
                       completion: @escaping (_ newUserUID: String?,_ error: Error?) -> Void) {
        
        let endpoint = env.CLIENT_API_ROOT_URL + env.ENDPOINT_CREATE_USER;
        let request = jsonPostReq(endpoint: endpoint, payload: userData)
        
        let postTask = URLSession.shared.dataTask(with: request) { (data, response, error) in
            if (error != nil) {
                completion(nil, error!)
                return
            }
            
            let statusCode = ((response as? HTTPURLResponse)?.statusCode)!
            let body = GDUtilities.shared.jsonDataToDict(jsonData: data!)
            print("CLIENT API: Create user response => Code: \(statusCode) Body:\(body)")
            
            if (!(200 ... 299).contains(statusCode)) {
                print("CLIENT API: Request failed with code = \(String(describing: statusCode))")
                let serverError = NSError(domain:"", code:statusCode, userInfo: body["message"] as! [String : String])
                completion(nil, serverError)
                return
            }
        
            let newUserUID = body["userUID"] as! String
            completion(newUserUID, nil)
        }
        
        // Start the task
        print("CLIENT API: Sending req to create new user")
        postTask.resume()
    }
    
    func logUserIn(userCreds: [String:String]!,
                   completion: @escaping (_ resBody: [String: Any]?,_ error: Error?) -> Void) {
        
        let endpoint = env.CLIENT_API_ROOT_URL + env.ENDPOINT_LOG_USER_IN;
        let request = jsonPostReq(endpoint: endpoint, payload: userCreds)
        
        let postTask = URLSession.shared.dataTask(with: request) { (data, response, error) in
            if (error != nil) {
                completion(nil, error!)
                return;
            }

            let statusCode = ((response as? HTTPURLResponse)?.statusCode)!
            let body = GDUtilities.shared.jsonDataToDict(jsonData: data!)
            print("CLIENT API: Login response => Code: \(statusCode) Body:\(body)")
            
            if (!(200 ... 299).contains(statusCode)) {
                let serverError = NSError(domain:"", code:statusCode, userInfo: body)
                completion(body, serverError)
                return
            }
        
            completion(body, nil)
        }
        
        // Start the task
        print("CLIENT API: Sending req to log user in")
        postTask.resume()
    }
    
    func updateLastSeen(userUID: String!,
                        completion: ((_ response: [String:Any]?, _ error: Error?) -> Void)? ) {
        
        let endpoint = env.CLIENT_API_ROOT_URL + env.ENDPOINT_UPDATE_LAST_SEEN
        let request = jsonPostReq(endpoint: endpoint, payload: ["userUID": userUID])
        
        let postTask = URLSession.shared.dataTask(with: request) { (data, response, error) in
            if (error != nil) {
                print("API: Failed to update last seen => \(String(describing: error))")
                if (completion != nil) { completion!(nil, error!) }
                return;
            }
            
            let statusCode = ((response as? HTTPURLResponse)?.statusCode)!
            let body = GDUtilities.shared.jsonDataToDict(jsonData: data!)
            print("CLIENT API: Update last seen => Code: \(statusCode) Body:\(body)")
            
            if (!(200 ... 299).contains(statusCode)) {
                let serverError = NSError(domain:"", code:statusCode, userInfo: body)
                if (completion != nil) { completion!(body, serverError) }
                return
            }
            
            if (completion != nil) { completion!(body, nil) }
        }
        
        // Start the task (resume is misleading
        postTask.resume()
    }
    
    // MARK: - Sensor APIs -
    
    func getSensorData(userUID: String!,
                       completion: @escaping (_ sensorData: [String:Any]?,_ error: Error?) -> Void) {
        
        let endpoint = env.CLIENT_API_ROOT_URL + env.ENDPOINT_GET_SENSOR_DATA;
        let request = jsonPostReq(endpoint: endpoint, payload: ["userUID": userUID])
        
        let postTask = URLSession.shared.dataTask(with: request) { (data, response, error) in
            if (error != nil) {
                completion(nil, error!)
                return
            }
            
            let statusCode = ((response as? HTTPURLResponse)?.statusCode)!
            let body = GDUtilities.shared.jsonDataToDict(jsonData: data!)
            print("CLIENT API: Get sensor data res => Code: \(statusCode) Body:\(body)")
            
            if (!(200 ... 299).contains(statusCode)) {
                print("CLIENT API: Request failed with code = \(String(describing: statusCode))")
                let serverError = NSError(domain:"", code:statusCode, userInfo: body)
                completion(nil, serverError)
                return
            }
            
            completion(body, nil)
        }
        
        // Start the task
        print("CLIENT API: Sending req to get sensor data")
        postTask.resume()
    }
    
    // MARK: - Utilities -
    
    func jsonPostReq(endpoint: String!, payload: [String: Any]!) -> URLRequest {
        let endpointUrl = URL.init(string: endpoint)
        var postReq = URLRequest(url: endpointUrl!)
        let serialPayload = try! JSONSerialization.data(withJSONObject: payload, options: [])
        
        postReq.setValue("application/json", forHTTPHeaderField: "Content-Type")
        postReq.setValue(env.CLIENT_API_KEY, forHTTPHeaderField: "x-api-key")
        postReq.httpBody = serialPayload
        postReq.httpMethod = "POST"
        return postReq
    }
}
