//
//  GDUtilities.swift
//  garage-sensor
//
//  Created by Josh Perry on 2018/04/10.
//  Copyright © 2018 IoT South Africa. All rights reserved.
//

import Foundation
import SystemConfiguration.CaptiveNetwork

struct dbProfileKeys {
    let ActiveDayKey = "activeDays"
    let AppVersionKey = "appVersion"
    let AssignedLocalIPKey = "assignedLocalIP"
    let CityKey = "city"
    let CountryKey = "country"
    let RegionKey = "region"
    let DoorStateKey = "doorState"
    let EmailKey = "email"
    let FirmwareVersionKey = "firmwareVersion"
    let LastSeenKey = "lastSeen"
    let PremiumKey = "premium"
    let UIDKey = "userUID"
    let UserAddressKey = "address"
    let UserFirstNameKey = "userFirstName"
    let UserLastNameKey = "userLastName"
    let UserNameKey = "username"
    let UserMobileNumKey = "mobileNumber"
    let UserPasswordKey = "password"
    let SensorUIDKey = "sensorUID"
}

struct dbSensorKeys {
    let ONLINE = "online"
    let DOOR_STATE = "doorState"
    let LAST_PING = "lastPing"
    let NETWORK_DOWN = "networkDown"
    let SENSOR_UID = "sensorUID"
}

struct doorInterfaceErrors {
    let errorCodeResolver = [1: "Not authorized for action",
                             2: "Door is unreachable",
                             3: "Door is unreachable",
                             4: "Door is offline",
                             5: "Door is not responding",
                             6: "User data incorrect",
                             7: "Server is not responding",
                             8: "Incorrect sensor LAN IP assignement",
                             9: "Client side http error"] as [Int:String]
}

struct doorInterfaceErrorDesc {
    let errorCodeResolver = [1: "You are not currently authorized to perform this action",
                             2: "Door is unreachable. The IP address is incorrect, try turning your sensor off and on again. Our system has logged this fault and we'll get on it ASAP!",
                             3: "Door is unreachable. The port address is incorrect, try turning your sensor off and on again. Our system has logged this fault and we'll get on it ASAP!",
                             4: "Door is offline. Try turning your sensor off and on again. Our system has logged this fault and we'll get on it ASAP!",
                             5: "Door is not responding. Try turning your sensor off and on again. Our system has logged this fault and we'll get on it ASAP!",
                             6: "User data incorrect. Our records of your information are incorrect. Please get in touch with us to resolve this.",
                             7: "Our server is currently not responding, it will up soon and you can try again.",
                             8: "The sensor config started up incorrectly. You can still check the door state, but can't trigger it. Turn it off and on and try again. If this problem persists check the router virtual server.",
                             9: "Could not send request to server - error in app."] as [Int:String]
}

struct doorInterfaceErrorTitles {
    let errorCodeResolver = [1: "Not authorized",
                             2: "Door Trigger Unavaliable",
                             3: "Door Trigger Unavaliable",
                             4: "Door is Offline",
                             5: "Door not responding",
                             6: "User data incorrect",
                             7: "Server not responding",
                             8: "Incorrect Sensor Config",
                             9: "App Error"] as [Int:String]
}

class GDUtilities: NSObject {
    // Create singleton (static instance)
    
    static let shared = GDUtilities()
    private override init() {
        // No initializer needed
    }
    
    // MARK: - Data Handling -
    
    func jsonDataToDict(jsonData: Data?) -> Dictionary <String, Any> {
        // Converts data to dictionary or nil if error
        do {
            let jsonDict = try JSONSerialization.jsonObject(with: jsonData!, options: []) // as! [String: Int]
            let convertedDict = jsonDict as! [String: Any]
            return convertedDict
        } catch {
            // Couldn't get JSON
            return [:]
        }
    }
    
    // MARK: - Time handling methods -
    func generateTimeStampForNow() -> Int {
        let timestamp = Int(Date.init().timeIntervalSince1970) * 1000           // Convert to Millis
        return timestamp
    }
}

public class SSID {
    class func fetchSSIDInfo() ->  String? {
        var currentSSID = ""
        if let interfaces = CNCopySupportedInterfaces() {
            for i in 0..<CFArrayGetCount(interfaces) {
                let interfaceName: UnsafeRawPointer = CFArrayGetValueAtIndex(interfaces, i)
                let rec = unsafeBitCast(interfaceName, to: AnyObject.self)
                let unsafeInterfaceData = CNCopyCurrentNetworkInfo("\(rec)" as CFString)
                if let interfaceData = unsafeInterfaceData as? [String: AnyObject] {
                    currentSSID = interfaceData["SSID"] as! String
                }
            }
        }
        return currentSSID
    }
    
    class func getAllWiFiNameList() -> String? {
        var ssid: String?
        if let interfaces = CNCopySupportedInterfaces() as NSArray? {
            for interface in interfaces {
                if let interfaceInfo = CNCopyCurrentNetworkInfo(interface as! CFString) as NSDictionary? {
                    ssid = interfaceInfo[kCNNetworkInfoKeySSID as String] as? String
                    break
                }
            }
        }
        return ssid
    }
}

extension String {
    func capitalizingFirstLetter() -> String {
        return prefix(1).uppercased() + self.lowercased().dropFirst()
    }
    
    mutating func capitalizeFirstLetter() {
        self = self.capitalizingFirstLetter()
    }
}











