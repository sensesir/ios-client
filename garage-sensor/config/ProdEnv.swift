//
//  ProdEnv.swift
//  garage-sensor
//
//  Created by Josh Perry on 2019/05/28.
//  Copyright © 2019 IoT South Africa. All rights reserved.
//

import Foundation
import AWSCore

struct ProdEnv {
    // Networking
    let CLIENT_API_KEY = "WbnpCQykhT7HXBNCuf3GF4z7fKCZ73T52M5vshyr"
    let CLIENT_API_ROOT_URL = "https://lgy6pmz9z8.execute-api.eu-west-1.amazonaws.com/prod/user"
    let ENDPOINT_CREATE_USER       = "/createNewUser"
    let ENDPOINT_LOG_USER_IN       = "/login"
    let ENDPOINT_UPDATE_USER_DATA  = "/updateData"
    let ENDPOINT_ACTIVE_DAY        = "/activeDay"
    let ENDPOINT_ADD_SENSOR        = "/addSensor"
    let ENDPOINT_ACTUATE_DOOR      = "/actuateDoor"
    let ENDPOINT_UPDATE_LAST_SEEN  = "/updateLastSeen"
    let ENDPOINT_GET_SENSOR_STATE  = "/getSensorState"
    let ENDPOINT_GET_SENSOR_DATA   = "/getSensorData"
    let ENDPOINT_INITIALIZE_SENSOR = "/initializeSensor"
    
    let UID_LENGTH = 36
    
    // Adding a new sensor
    let SENSOR_AP_SSID = "GarageDoor-jPtF"
    let SENSOR_ROOT_URL = "http://10.10.10.1"
    let ENDPOINT_GET_SENSOR_UID = "/getSensorUID"
    let ENDPOINT_POST_WIFI_CREDS = "/postWifiCreds"
    let ENDPOINT_SENSOR_UID_RES_CONFIRMATION = "/postSensorUIDConfirm"
    
    let NETWORK_ERROR_GET_SENSOR_UID  = 000
    let NETWORK_ERROR_POST_WIFI_CREDS = 001
    let NETWORK_ERROR_POST_UID_CONF   = 002
    let MAX_SENSOR_INIT_RETIES = 5
    
    // IoT
    let AWS_REGION = AWSRegionType.EUWest1
    let AWS_IDENTITY_POOL_ID = "eu-west-1:f541c19a-4489-469b-bcf4-ab30bbcbb24a"
    let AWS_IOT_ENDPOINT = "wss://a2rpz6e8hvsfm5-ats.iot.eu-west-1.amazonaws.com/mqtt"
    let AWS_PUBSUB_KEY = "AWSPubSub"
    let AWS_IOT_DATA_MANAGER_KEY = "AWSIotDataManager"
    
    // MQTT
    let MQTT_TARGET = "mobileClient"
    let MQTT_SUB_EVENT = "event"
    let MQTT_SUB_DOOR_STATE_CHANGE = "doorStateChange"
    let MQTT_SUB_CONNECTED = "connected"
    let MQTT_SUB_DISCONNECT = "disconnected"
    
    // Bug tracking
    let BUGSNAG_KEY = "acf29ef9a71b19f39c099ae38bf2988e"
}


