//
//  DevEnv.swift
//  garage-sensor
//
//  Created by Josh Perry on 2019/05/28.
//  Copyright © 2019 IoT South Africa. All rights reserved.
//

import Foundation

struct DevEnv {
    // Networking
    let CLIENT_API_KEY = "ByjI6NHlPd7knghHSBCKJ871aJnKyfBw18BteCWK"
    let CLIENT_API_ROOT_URL = "https://1hnr9288rb.execute-api.eu-west-1.amazonaws.com/dev/user"
    let ENDPOINT_CREATE_USER      = "/createNewUser"
    let ENDPOINT_LOG_USER_IN      = "/login"
    let ENDPOINT_UPDATE_USER_DATA = "/updateData"
    let ENDPOINT_ACTIVE_DAY       = "/activeDay"
    let ENDPOINT_ADD_SENSOR       = "/addSensor"
    let ENDPOINT_ACTUATE_DOOR     = "/actuateDoor"
    let ENDPOINT_UPDATE_LAST_SEEN = "/updateLastSeen"
    let ENDPOINT_GET_SENSOR_DATA  = "/getSensorData"
    
    let UID_LENGTH = 36
}
