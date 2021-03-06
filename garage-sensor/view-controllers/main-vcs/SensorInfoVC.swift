//
//  SensorInfoVC.swift
//  garage-sensor
//
//  Created by Josh Perry on 2019/07/03.
//  Copyright © 2019 IoT South Africa. All rights reserved.
//

import UIKit

class SensorInfoVC: UIViewController, UITableViewDataSource, SensorStateProtocol {
    @IBOutlet var sensorInfoTable: UITableView!
    @IBOutlet var refreshRSSI: UIButton!
    
    let rowTitles = ["Sensor State",
                     "Door State",
                     "Last Ping",
                     "RSSI",
                     "Network Down",
                     "Sensor WiFi SSID",
                     "WiFi Password"]
    
    override func viewDidLoad() {
        sensorInfoTable.dataSource = self
        sensorInfoTable.rowHeight = 48.0
    }
    
    override func viewWillAppear(_ animated: Bool) {
        sensorInfoTable.reloadData()
        GDoorModel.main.sensorStateDelegate = self
    }
    
    override func viewDidLayoutSubviews() {
        refreshRSSI.layer.cornerRadius = refreshRSSI.frame.height/2.0
    }
    
    // MARK: - Table view handling -
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return rowTitles.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    
        var cell = tableView.dequeueReusableCell(withIdentifier: "SensorInfoCell") as? SensorInfoCell
        if (cell == nil) { cell = SensorInfoCell.init(style: .default, reuseIdentifier: "SensorInfoCell") }
        
        // Set values
        cell?.descriptor.text = rowTitles[indexPath.row]
        
        switch indexPath.row {
        case 0:
            if (GDoorModel.main.networkState == "Sensor Online") { cell?.value.text = "Connected" }
            else { cell?.value.text = "Disconnected" }
        case 1:
            cell?.value.text = GDoorModel.main.doorState
        case 2:
            if (GDoorModel.main.lastPing == nil) { cell?.value.text = "Never" }
            else { cell?.value.text = GDoorModel.main.lastPing!.toString(dateFormat: "HH:mm  dd-MMM-yyyy") }
        case 3:
            if (GDoorModel.main.lastRSSI == nil) { cell?.value.text = "Unknown" }
            else { cell?.value.text = "\(GDoorModel.main.lastRSSI!)" }
        case 4:
            if (GDoorModel.main.networkDown == nil) { cell?.value.text = "Never" }
            else { cell?.value.text = GDoorModel.main.networkDown!.toString(dateFormat: "HH:mm  dd-MMM-yyyy") }
        case 5:
            if (GDoorModel.main.wifiSSID == nil) { cell?.value.text = "" }
            else { cell?.value.text = GDoorModel.main.wifiSSID }
        case 6:
            if (GDoorModel.main.wifiPassword == nil) { cell?.value.text = "" }
            else { cell?.value.text = GDoorModel.main.wifiPassword }
        default:
            print("SENSOR INFO VC: Error - unknown table row \(indexPath.row)")
        }
        
        return cell!
    }
    
    @IBAction func updateRSSI(sender: UIButton) {
        GDoorModel.main.updateRSSI()
    }
    
    func sensorStateUpdated() {
        DispatchQueue.main.async {
            self.sensorInfoTable.reloadData()
        }
    }
    
    func sensorLanIPError() {
        // Nothing to do here
    }
}
