//
// 
//  MicroLinkSample
//
//  Created by Achraf Letaief on 03/09/2018.
//  Copyright © 2018 Achraf Letaief. All rights reserved.
//

import UIKit
import CoreBluetooth

class MainViewController: UIViewController {
    
    @IBOutlet weak var toggleDataTypeBtn: UIButton!
    @IBOutlet weak var tableView: UITableView!
    var connectedPeripheral: CBPeripheral!
    
    // BLE Characteristics
    var oneShotDataRequestChar: CBCharacteristic?
    var oneShotDataResponseChar: CBCharacteristic?
    
    var oadRequestChar: CBCharacteristic?
    var oadBlockRequestChar: CBCharacteristic?
    
    var periodicDataRequestChar: CBCharacteristic?
    var periodicDataResponseChar: CBCharacteristic?
    
    var accelerometerRequestChar: CBCharacteristic?
    
    var dtcDataRequestChar: CBCharacteristic?
    var dtcDataResponseChar: CBCharacteristic?
    
    var canDiagRequestChar: CBCharacteristic?
    var canDiagResponseChar: CBCharacteristic?
    
    var functionalFrameRequestChar: CBCharacteristic?
    var functionalFrameResponseChar: CBCharacteristic?
    
    
    var rpm: Double = 0
    var speed: Double = 0
    var airFlow: Double = 0
    var airTemp: Double = 0
    var manAbsPressure: Double = 0
    var engineLoad: Double = 0
    
    var itemsArray: [String] = ["VIN","Battery Level","Timestamp","Mileage","DTC Num","Device Info"]
    var batteryLvl: Double = 0
    var vinValue: String = ""
    var mileage: Double = 0
    var timestamp: String = ""
    
    var allCharacs = 0
    var didGetProtocol: Bool = false
    var oneShotDataResponseIsRead: Bool = false
    var isPlainPeriodicData: Bool = true
    var dtcNumber: UInt8 = 0
    var deviceInfo = DeviceInfo(systemID: "", modelNumber: "", manufacturer: "", firmwareRevision: "", serialNumber: "", softwareRevision: "", hardwareRevision: "")
    
    @IBOutlet weak var logText: UITextView!
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        discoverServices()
    }
    
    func setupTableView() {
        self.tableView.register(UINib (nibName: "ItemCell", bundle: nil), forCellReuseIdentifier: "itemCell")
        self.tableView.delegate = self
        self.tableView.dataSource = self
        self.tableView.tableFooterView = UIView()
        self.tableView.allowsSelection = false
    }
    
    
    @IBAction func clearLogAction(_ sender: UIButton) {
        logText.text = ""
    }
    
    @IBAction func periodicBtnAction(_ sender: UIButton) {
        if isPlainPeriodicData {
            toggleDataTypeBtn.setTitle("Plain Data", for: UIControlState.normal)
        }else {
            toggleDataTypeBtn.setTitle("OBD Data", for: UIControlState.normal)
        }
        isPlainPeriodicData = !isPlainPeriodicData
    }
    
    func discoverServices() {
        if  connectedPeripheral != nil {
            sysState = SystemState.INIT
            connectedPeripheral.delegate = self
            connectedPeripheral.discoverServices(nil)
        }
    }
    
}

// MARK: - UITableView Delegate and DataSource

extension MainViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return itemsArray.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = self.tableView.dequeueReusableCell(withIdentifier: "itemCell", for: indexPath) as! ItemCell
        cell.itemTitle.text = itemsArray[indexPath.row]
        cell.getValueBtn.tag = indexPath.row
        cell.getValueBtn.addTarget(self, action: #selector(getValueBtnAction(_:)), for: UIControlEvents.touchUpInside)
        switch indexPath.row {
        case 0:
            cell.itemValue.text = vinValue
            break
        case 1:
            cell.itemValue.text = String(batteryLvl)
            break
        case 2:
            cell.itemValue.text = String(timestamp)
            break
        case 3:
            cell.itemValue.text = String(mileage)
            break
        case 4:
            cell.itemValue.text = String(dtcNumber)
            break
        default:
            break
        }
        return cell
    }
    
    @objc func getValueBtnAction(_ sender: UIButton) {
        switch sender.tag {
        case 0:
            // Send one shot request to get VIN
            OneshotDataServiceHelper.sendOneshotRequest(request: [1,0,0,0,0], peripheral: connectedPeripheral, oneShotDataRequestChar: oneShotDataRequestChar!)
            break
        case 1:
            // Send one shot request to get Battery Level
            OneshotDataServiceHelper.sendOneshotRequest(request: [2,0,0,0,0], peripheral: connectedPeripheral, oneShotDataRequestChar: oneShotDataRequestChar!)
            break
        case 2:
            // Send one shot request to get Timestamp
            OneshotDataServiceHelper.sendOneshotRequest(request: [0x0C,0,0,0,0], peripheral: connectedPeripheral, oneShotDataRequestChar: oneShotDataRequestChar!)
            break
        case 3:
            // Send one shot request to get Mileage
            OneshotDataServiceHelper.sendOneshotRequest(request: [0x11,0,0,0,0], peripheral: connectedPeripheral, oneShotDataRequestChar: oneShotDataRequestChar!)
            break
        case 4:
            // Send DTC request to get DTC number
            DTCDataServiceHelper.sendDiagnosticRequest(dtc: 3, peripheral: connectedPeripheral, dtcDataRequestChar: dtcDataRequestChar!)
            break
        case 5:
            // Read Device Info
            let alert = UIAlertController(title: "Device Info", message: DeviceInfo.formatToString(deviceInfo: self.deviceInfo), preferredStyle: UIAlertControllerStyle.alert)
            alert.addAction(UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.default, handler: nil))
            self.present(alert, animated: true, completion: nil)
            break
        default:
            break
        }
    }
}

//MARK:- CBPeripheral Delegate
extension MainViewController: CBPeripheralDelegate {
    
    // Send request to get protocol
    func sendProtocolRequest() {
        guard let oneshotC = oneShotDataRequestChar else {return}
        if didGetProtocol {
            OneshotDataServiceHelper.sendOneshotRequest(request: [3,0,0,0,0], peripheral: connectedPeripheral, oneShotDataRequestChar: oneshotC)
            didGetProtocol = false
        }
    }
    
    func oneShotDataResponseProcess(array: [UInt8], timeout: Bool) {
        if !timeout {
            switch array[0] {
            case OneShotDataResponseEnum.BATTERY_LEVEL.rawValue:
                if let batteryLevel = OneshotDataServiceHelper.getBatteryValue(data: array) as? Double {
                    batteryLvl = batteryLevel
                    // MIL Value
                    if array[5] == 0x01 {
                        // MIL value is ON
                    }else {
                        // MIL value is OFF/Unknown
                    }
                }
                break
            case OneShotDataResponseEnum.VIN.rawValue:
                vinValue = OneshotDataServiceHelper.getVIN(data: array)
                break
            case OneShotDataResponseEnum.GET_PROTOCOL.rawValue:
                OneshotDataServiceHelper.getProtocolResponseProcess(data: array, peripheral: connectedPeripheral, periodicDataRequestChar: periodicDataRequestChar!, periodicDataResponseChar: periodicDataResponseChar!, oneShotDataRequestChar: oneShotDataRequestChar!)
                
                break
            case OneShotDataResponseEnum.SET_PROTOCOL.rawValue:
                OneshotDataServiceHelper.setProtocolResponseProcess(data: array, peripheral: connectedPeripheral, periodicDataResponseChar: periodicDataResponseChar!, periodicDataRequestChar: periodicDataRequestChar!, oneShotDataRequestChar: oneShotDataRequestChar!)
                break
            case OneShotDataResponseEnum.MODE_1.rawValue:
                let pidArray = array[1..<array.count]
                _ = OneshotDataServiceHelper.getSupportedPID(data: [UInt8](pidArray))
                
                break
            case OneShotDataResponseEnum.GET_MILEAGE.rawValue:
                mileage = OneshotDataServiceHelper.getMileage(data: array)
                break
            case OneShotDataResponseEnum.GET_TIMESTAMP.rawValue:
                timestamp = OneshotDataServiceHelper.getTimestamp(data: array)
                break
            default:
                break
            }
        }
        self.tableView.reloadData()
    }
    
    func periodicResponseProcess(array: [UInt8]) {
        // Getting Periodic data
        getObdParams(array: array)
        if isPlainPeriodicData {
            logText.text = logText.text + String(describing: array) + "\n"
        }else {
            logText.text = logText.text + String(format:"rpm = %0.1f, speed = %0.1f, airFlow = %0.1f, airTemp, manAbsPressure = %0.1f, engineLoad = %0.1f \n", rpm, speed, airFlow, airTemp, manAbsPressure, engineLoad)
        }
        logText.simpleScrollToBottom()
    }
    
    
    // Get OBD Params
    func getObdParams(array: [UInt8]) {
        rpm = PeriodicDataServiceHelper.getEngineRPM(response: array)
        speed = PeriodicDataServiceHelper.getVehiculeSpeed(response: array)
        airFlow = PeriodicDataServiceHelper.getAirFlowRate(response: array)
        airTemp = PeriodicDataServiceHelper.getAirTemperature(response: array)
        manAbsPressure = PeriodicDataServiceHelper.getAbsolutePressure(response: array)
        engineLoad = PeriodicDataServiceHelper.getEngineLoad(response: array)
    }
    
    // MARK: - Did Discover Services
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard error == nil else {
            print("didDiscoverServices error: \(String(describing: error))")
            return
        }
        guard let services = peripheral.services else { return }
        for service in services {
            let thisService = service as CBService
            peripheral.discoverCharacteristics(nil, for: thisService)
        }
    }
    
    // MARK: - Did Discover Characteristics
    // Enable notification and sensor for each characteristic of valid service
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard error == nil else {
            print("didDiscoverCharacteristicsForService error: \(String(describing: error))")
            return
        }
        guard let characteristics = service.characteristics else { return }
        for charateristic in characteristics {
            let thisCharacteristic = charateristic as CBCharacteristic
            switch (thisCharacteristic.uuid) {
            case SerialNumberUUID, FirmwareRevisionUUID, HardwareRevisionUUID, SoftwareRevisionUUID, ManufacturerNameUUID, ModelNumberUUID:
                peripheral.readValue(for: thisCharacteristic)
                break
            case OneShotDataCharRequestUUID:
                didGetProtocol = true
                self.oneShotDataRequestChar = thisCharacteristic
                break
            case OneShotDataCharResponseUUID:
                self.oneShotDataResponseChar = thisCharacteristic
                peripheral.setNotifyValue(true, for: self.oneShotDataResponseChar!)
                sendProtocolRequest()
                break
            case PeriodicDataCharRequestUUID:
                self.periodicDataRequestChar = thisCharacteristic
                break
            case PeriodicDataCharResponseUUID:
                self.periodicDataResponseChar = thisCharacteristic
                break
            case FunctionalFrameRequestUUID:
                self.functionalFrameRequestChar = thisCharacteristic
                break
            case FunctionalFrameResponseUUID:
                self.functionalFrameResponseChar = thisCharacteristic
                peripheral.setNotifyValue(false, for: functionalFrameResponseChar!)
            case OADImageNotifyUUID:
                self.oadRequestChar = thisCharacteristic
                break
            case OADImageBlockRequestUUID:
                self.oadBlockRequestChar = thisCharacteristic
                break
            case AccelerometerCharRequestUUID:
                self.accelerometerRequestChar = thisCharacteristic
                break
            case DTCCharRequestUUID:
                self.dtcDataRequestChar = thisCharacteristic
                break
            case DTCCharResponseUUID:
                self.dtcDataResponseChar = thisCharacteristic
                peripheral.setNotifyValue(true, for: self.dtcDataResponseChar!)
                break
            case CanDiagCharRequestUUID:
                self.canDiagRequestChar = thisCharacteristic
                break
            case CanDiagCharResponseUUID:
                self.canDiagResponseChar = thisCharacteristic
                peripheral.setNotifyValue(true, for: self.canDiagResponseChar!)
                break
            default:
                break
            }
        }
        
        // If all characteristics are found properly, we should update our connection status and send
        // the get protocol request.
        allCharacs += characteristics.count
        if allCharacs >= 27 {
            carCheckStatus = CarChecker.CAR_OFF_PHONE_ON
            sendProtocolRequest()
        }
    }
    
    // MARK: - Did Update Value for Characteristic
    // Get data values when they are updated
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        switch characteristic.uuid {
        // Get Device info:
        case ModelNumberUUID:
            if let modelNumber = String(data: characteristic.value!, encoding: .utf8) {
                deviceInfo.modelNumber = modelNumber
            }
            break
        case SerialNumberUUID:
            if let serialNumber = String(data: characteristic.value!, encoding: .utf8) {
                deviceInfo.serialNumber = serialNumber
            }
            break
        case FirmwareRevisionUUID:
            if let firmwareRevision = String(data: characteristic.value!, encoding: .utf8) {
                deviceInfo.firmwareRevision = firmwareRevision
            }
            break
        case ManufacturerNameUUID:
            if let manufacturer = String(data: characteristic.value!, encoding: .utf8) {
                deviceInfo.manufacturer = manufacturer
            }
            break
        case SoftwareRevisionUUID:
            if let softwareRevision = String(data: characteristic.value!, encoding: .utf8) {
                deviceInfo.softwareRevision = softwareRevision
            }
            break
        case HardwareRevisionUUID:
            if let hardwareRevision = String(data: characteristic.value!, encoding: .utf8) {
                deviceInfo.hardwareRevision = hardwareRevision
            }
            break
        case OneShotDataCharResponseUUID:
            if !oneShotDataResponseIsRead {
                if self.oneShotDataResponseChar != nil {
                    peripheral.readValue(for: self.oneShotDataResponseChar!)
                    oneShotDataResponseIsRead = true
                }
            }else {
                let oneShotDataResponseValue = characteristic.value
                let oneShotDataResponseData = [UInt8](oneShotDataResponseValue!)
                oneShotDataResponseProcess(array: oneShotDataResponseData, timeout: false)
                oneShotDataResponseIsRead = false
            }
            break
        case PeriodicDataCharResponseUUID:
            periodicResponseProcess(array:[UInt8](characteristic.value!))
            break
        case FunctionalFrameResponseUUID:
            break
        case OADImageNotifyUUID:
            break
        case OADImageBlockRequestUUID:
            break
        case DTCCharResponseUUID:
            let data = [UInt8](characteristic.value!)
            (_ ,dtcNumber) = DTCDataServiceHelper.diagnosticDataResponse(array: data)
            self.tableView.reloadData()
            break
        case CanDiagCharResponseUUID:
            break
        default:
            break
        }
        
    }
    
    // MARK: - Did Write Value for Characteristic
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        
        if let error = error { print("didWriteValueForCharacteristic error: \(error)") }
        switch characteristic.uuid {
        case AccelerometerCharRequestUUID:
            break
        case PeriodicDataCharRequestUUID:
            break
        default:
            break
        }
        
    }
}

extension UITextView {
    func simpleScrollToBottom() {
        let textCount: Int = text.count
        guard textCount >= 1 else { return }
        scrollRangeToVisible(NSMakeRange(textCount - 1, 1))
    }
}

