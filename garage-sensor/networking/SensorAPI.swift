//
//  SensorApi.swift
//  garage-sensor
//
//  Created by Josh Perry on 2019/06/10.
//  Copyright © 2019 IoT South Africa. All rights reserved.
//

import Foundation
import PromiseKit
import AwaitKit

class SensorApi: NSObject {
    
    
    func getSensorUID() -> Promise<String> {
        return Promise<String> { seal in
            let endpoint = env.SENSOR_ROOT_URL + env.ENDPOINT_GET_SENSOR_UID
            let request = getReqSimple(endpoint: endpoint)
            
            let getTask = URLSession.shared.dataTask(with: request) { (data, response, error) in
                if (error != nil) {
                    let localServerError = NSError(domain:"", code: env.NETWORK_ERROR_GET_SENSOR_UID, userInfo: ["error": error!])
                    seal.reject(localServerError)
                }
                
                else {
                    let statusCode = ((response as? HTTPURLResponse)?.statusCode)!
                    let body = GDUtilities.shared.jsonDataToDict(jsonData: data!)
                    print("SENSOR API: Received res for getSensorUID => Code: \(statusCode) Body:\(body)")
                    
                    if (!(200 ... 299).contains(statusCode)) {
                        print("SENSOR API: Request failed with code = \(String(describing: statusCode))")
                        let serverError = NSError(domain:"", code:env.NETWORK_ERROR_GET_SENSOR_UID, userInfo: body["message"] as! [String : String])
                        seal.reject(serverError)
                        return
                    }
                    
                    let sensorUID = body["sensorUID"] as! String
                    seal.fulfill(sensorUID)
                }
            }
            
            // Start the task
            print("SENSOR API: Sending GET req for sensor UID")
            getTask.resume()
        }
    }
    
    func postWiFiCreds(ssid: String!, password: String?) -> Promise<Any> {
        return Promise<Any> { seal in
            let wifiCreds = ["wifiSSID": ssid, "wifiPassword": password ?? ""]
            let endpoint = env.SENSOR_ROOT_URL + env.ENDPOINT_POST_WIFI_CREDS
            let request = jsonPostReq(endpoint: endpoint, payload: wifiCreds as [String : Any])
            
            let postTask = URLSession.shared.dataTask(with: request) { (data, response, error) in
                if (error != nil) {
                    let localServerError = NSError(domain:"", code: env.NETWORK_ERROR_POST_WIFI_CREDS, userInfo: ["error": error!])
                    seal.reject(localServerError)
                }
                    
                else {
                    let statusCode = ((response as? HTTPURLResponse)?.statusCode)!
                    let body = GDUtilities.shared.jsonDataToDict(jsonData: data!)
                    print("SENSOR API: Res from posting wifi creds => Code: \(statusCode) Body:\(body)")
                    
                    if (!(200 ... 299).contains(statusCode)) {
                        print("SENSOR API: Request failed with code = \(String(describing: statusCode))")
                        let serverError = NSError(domain:"", code:env.NETWORK_ERROR_POST_WIFI_CREDS, userInfo: body["message"] as! [String : String])
                        seal.reject(serverError)
                        return
                    }
                    
                    seal.fulfill(true)
                }
            }
            
            // Start the task
            print("SENSOR API: Sending POST req to pass wifi creds")
            postTask.resume()
        }
    }
    
    func postSensorUIDResConfirmation() -> Promise<Bool> {
        return Promise<Bool> { seal in
            let endpoint = env.SENSOR_ROOT_URL + env.ENDPOINT_SENSOR_UID_RES_CONFIRMATION
            let request = jsonPostReq(endpoint: endpoint, payload: [:])
            
            let postTask = URLSession.shared.dataTask(with: request) { (data, response, error) in
                if (error != nil) {
                    seal.reject(error!)
                }
                    
                else {
                    let statusCode = ((response as? HTTPURLResponse)?.statusCode)!
                    let body = GDUtilities.shared.jsonDataToDict(jsonData: data!)
                    print("SENSOR API: Res from posting sensor UID confirmation => Code: \(statusCode) Body:\(body)")
                    
                    if (!(200 ... 299).contains(statusCode)) {
                        print("SENSOR API: Request failed with code = \(String(describing: statusCode))")
                        let serverError = NSError(domain:"", code:statusCode, userInfo: body["message"] as! [String : String])
                        seal.reject(serverError)
                        return
                    }
                    
                    seal.fulfill(true)
                }
            }
            
            // Start the task
            print("SENSOR API: Sending POST req confirming sensorUID res")
            postTask.resume()
        }
    }
    
    // MARK: - HTTP Utils -
    
    func getReqSimple(endpoint: String!) -> URLRequest {
        let endpointUrl = URL.init(string: endpoint)
        var getReq = URLRequest(url: endpointUrl!)
        getReq.httpMethod = "GET"
        return getReq
    }
    
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
