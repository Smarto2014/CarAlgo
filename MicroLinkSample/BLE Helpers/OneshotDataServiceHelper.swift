//
//  OneshotDataServiceHelper.swift
//  MicroLinkTool
//
//  Created by Achraf Letaief on 30/03/2018.
// **********************************************************************************
// *             Copyright(c) 2015, SMARTO All rights reserved.                     *
// **********************************************************************************
// *           This source code is the exclusive property of                        *
// *           SMARTO SAS 25 Quai Gallieni 92150 SURESNES FRANCE                    *
// *           Any reproduction is strictly prohibited                              *
// **********************************************************************************

// Created by: Achraf Letaief on 26/03/2018
// Copyright (c) 2018 SMARTO
//

import UIKit
import CoreBluetooth

var oneshotDataRequestInProgress : UInt8 = 0

let OneShotDataServiceUUID           = CBUUID(string: "DD10")
let OneShotDataCharRequestUUID       = CBUUID(string: "DD11")
let OneShotDataCharResponseUUID      = CBUUID(string: "DD12")
let AccelerometerCharRequestUUID     = CBUUID(string: "FFA4")

public enum OneShotDataResponseEnum: UInt8 {
    case VIN = 0x41
    case BATTERY_LEVEL = 0x42
    case GET_PROTOCOL = 0x43
    case SET_PROTOCOL = 0x44
    case MODE_1 = 0x45
    case MODE_2 = 0x46
    case MODE_5 = 0x47
    case MODE_6 = 0x48
    case MODE_8 = 0x49
    case MODE_9 = 0x4A
    case CAN_TRACE_STATUS = 0x52
    case GET_MILEAGE = 0x51
    case CAN_TRACE_BLOCK_PROCESS = 0x53
    case GET_TIMESTAMP = 0x4C
}

public enum SystemState: UInt8 {
    case INIT = 0
    case RUNNING = 1
    case WAITING_CAR_CONNECTION_ON = 2
    case CAR_CONNECTION_LOST = 3
}

var sysState = SystemState.INIT

// KConnectionAttempt is constant that is set depending on the number of attempts to restore the Car Connection
// Ideally its set to 12 which translates into 300 sec
let KConnectionAttempt: Int = 0
var attemptCarConnection: Int = 0
var actualAttemptCarConnection: Int = 0

class OneshotDataServiceHelper {
    
    class func sendOneshotRequest(request: [UInt8], peripheral: CBPeripheral, oneShotDataRequestChar: CBCharacteristic) {
        var arrayToSend = request
        oneshotDataRequestInProgress = request[0] + (UInt8)(0x40)
        let data = NSData(bytes: &arrayToSend, length: 5)
        peripheral.writeValue(data as Data, for: oneShotDataRequestChar, type: CBCharacteristicWriteType.withResponse)
        
    }
    
    // Get Battery Level
    class func getBatteryValue(data:[UInt8]) -> Double {
        let batteryLevelString = String(data[1]) + String(data[2]) + "." + String(data[3]) + String(data[4])
        let batteryLevel = Double(batteryLevelString)
        return batteryLevel!
    }
    
    // Get Vehicle VIN
    class func getVIN(data:[UInt8]) -> String {
        var vinString = ""
        let isValidVin = data[1]
        if isValidVin == isValidData {
            for i in 2..<22 {
                vinString.append(String(data[i].char))
            }
            return vinString
        }
        return "Invalid"
    }
    
    // Get Mileage
    class func getMileage(data:[UInt8]) -> Double {
        var mileage: Double = 0
        var value = uint32FromFourBytes(data[1], lohiByte: data[2], hiloByte: data[3], hihiByte: data[4])
        value = value / 10
        mileage = Double(value)
        return mileage
    }
    
    // Get Timestamp
    class func getTimestamp(data:[UInt8]) -> String {
        let value = uint32FromFourBytes(data[1], lohiByte: data[2], hiloByte: data[3], hihiByte: data[4])
        let date = NSDate(timeIntervalSince1970: TimeInterval(value))
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEEE d MMM"
        let stringDate = dateFormatter.string(from: date as Date)
        return stringDate
    }
    
    // Set Protocol Response
    class func setProtocolResponseProcess(data:[UInt8], peripheral: CBPeripheral, periodicDataResponseChar: CBCharacteristic, periodicDataRequestChar: CBCharacteristic, oneShotDataRequestChar: CBCharacteristic) {
        let isValidProtocol = data[1]
        if isValidProtocol == isValidData {
            if data[2] != 0x7F {
                UserDefaults.standard.set(data[2], forKey: "ProtocolNumber")
                CarConnectionStatus = MicroLinkCarConnectionState.CAR_CONNECTION_ON
            }else {
                
                CarConnectionStatus = MicroLinkCarConnectionState.CAR_CONNECTION_OFF
            }
        }else {
            CarConnectionStatus = MicroLinkCarConnectionState.CAR_CONNECTION_OFF
        }
        
        // Generate Event
        updateMicroLinkFSM(peripheral: peripheral, oneShotDataRequestChar: oneShotDataRequestChar, periodicDataRequestChar: periodicDataRequestChar, periodicDataResponseChar: periodicDataResponseChar)
    }
    
    // Get Protocol Response
    class func getProtocolResponseProcess(data:[UInt8], peripheral: CBPeripheral, periodicDataRequestChar: CBCharacteristic, periodicDataResponseChar: CBCharacteristic, oneShotDataRequestChar: CBCharacteristic) {
        if data[1] != 0x7F {
            if data[1] < 6 {
                // If the protocol number is less than 6, the period is 2 sec.
                UserDefaults.standard.set(2.0, forKey: "period")
            }else {
                UserDefaults.standard.set(1.0, forKey: "period")
            }
            UserDefaults.standard.set(data[1], forKey: "ProtocolNumber")
            CarConnectionStatus = MicroLinkCarConnectionState.CAR_CONNECTION_ON
        }else {
            CarConnectionStatus = MicroLinkCarConnectionState.CAR_CONNECTION_OFF
        }
        updateMicroLinkFSM(peripheral: peripheral, oneShotDataRequestChar: oneShotDataRequestChar, periodicDataRequestChar: periodicDataRequestChar, periodicDataResponseChar: periodicDataResponseChar )
    }
    
    // FSM
    class func updateMicroLinkFSM(peripheral: CBPeripheral, oneShotDataRequestChar: CBCharacteristic, periodicDataRequestChar: CBCharacteristic, periodicDataResponseChar: CBCharacteristic) {
        switch peripheral.state {
        case CBPeripheralState.connected:
            switch CarConnectionStatus {
            case MicroLinkCarConnectionState.CAR_CONNECTION_ON:
                print("CAR_CONNECTION_ON")
                // Init vars
                actualAttemptCarConnection = 0
                attemptCarConnection = 0
                switch sysState {
                case SystemState.INIT, SystemState.CAR_CONNECTION_LOST:
                    // System from INIT/CAR CONNECTION LOST to RUNNING
                    sysState = SystemState.RUNNING
                    break
                case SystemState.WAITING_CAR_CONNECTION_ON:
                    // Restored Car Connection -> System is RUNNING again
                    sysState = SystemState.RUNNING
                    break
                default:
                    break
                }
                // If the Car Connection is ON, we start the periodic data
                peripheral.setNotifyValue(true, for: periodicDataResponseChar)
                PeriodicDataServiceHelper.periodicConfiguration(peripheral: peripheral, periodicDataRequestChar: periodicDataRequestChar)
                carCheckStatus = .CAR_ON_PHONE_ON
                break
            case MicroLinkCarConnectionState.CAR_CONNECTION_OFF:
                print("CAR_CONNECTION_OFF")
                switch sysState {
                case SystemState.INIT:
                    // Setting the protocol from INIT
                    let protocolNumber = UserDefaults.standard.object(forKey: "ProtocolNumber") as! UInt8
                    sendOneshotRequest(request: [0x04,protocolNumber,0,0,0], peripheral: peripheral, oneShotDataRequestChar: oneShotDataRequestChar)
                    sysState = .WAITING_CAR_CONNECTION_ON
                    break
                    
                case SystemState.WAITING_CAR_CONNECTION_ON:
                    actualAttemptCarConnection += 1
                    print("actualAttemptCarConnection", actualAttemptCarConnection)
                    if actualAttemptCarConnection > 4 {
                        actualAttemptCarConnection = 0
                        attemptCarConnection += 1
                        if attemptCarConnection <= KConnectionAttempt {
                            // Set Protocol
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: {
                                // Trying to set the protocol from WAITING FOR CAR CONNECTION ON
                                let protocolNumber = UserDefaults.standard.object(forKey: "ProtocolNumber") as! UInt8
                                // Send one shot request to set the protocol
                                sendOneshotRequest(request: [0x04,protocolNumber,0,0,0], peripheral: peripheral, oneShotDataRequestChar: oneShotDataRequestChar)
                            })
                        } else {
                            // All attempts failed to restore the Car Connection
                            sysState = .CAR_CONNECTION_LOST
                            self.updateMicroLinkFSM(peripheral: peripheral, oneShotDataRequestChar: oneShotDataRequestChar, periodicDataRequestChar: periodicDataRequestChar, periodicDataResponseChar: periodicDataResponseChar)
                        }
                    }
                    break
                case SystemState.RUNNING:
                    // System state from RUNNING to WAITING FOR CAR CONNECTION ON
                    // Increment first attempt to reconnect
                    actualAttemptCarConnection += 1
                    sysState = .WAITING_CAR_CONNECTION_ON
                    break
                case SystemState.CAR_CONNECTION_LOST:
                    // System state from WAITING FOR CAR CONNECTION ON to CAR CONNECTION LOST
                    // All attemps failed to restore the protocol
                    break
                }
                // Regardless of the System state, the Car connection is not established
                carCheckStatus = .CAR_OFF_PHONE_ON
                break
            }
            break
        case CBPeripheralState.disconnected:
            //Periph disconnected
            break
        default:
            break
        }
    }
    
    // Getting supported PIDs
    class func getSupportedPID(data:[UInt8]) -> [UInt8] {
        var returnedPID = [UInt8]()
        let nonZeros = data.filter{($0 != 0)}
        var ind = 0
        for i in 0..<nonZeros.count {
            let binValue =  String(nonZeros[i], radix: 2)
            let binValue8 = pad(string: binValue, toSize: 8)
            for j in 0..<binValue8.count {
                ind += 1
                if binValue8[j] == "1" {
                    returnedPID.append(UInt8(ind))
                }
            }
        }
        return returnedPID
    }
    
    class func pad(string : String, toSize: Int) -> String {
        var padded = string
        for _ in 0..<(toSize - string.characters.count) {
            padded = "0" + padded
        }
        return padded
    }
    
    // Set Mileage
    class func setMileage(mileage: String, peripheral: CBPeripheral, oneShotDataRequestChar: CBCharacteristic) {
        if let u_32 = UInt32(mileage) {
            let m = u_32 * 10
            let byte1 = UInt8(m & 0xFF)
            let byte2 = UInt8((m & 0xFF00) >> 8)
            let byte3 = UInt8((m & 0xFF0000) >> 16)
            let byte4 = UInt8((m & 0xFF000000) >> 24)
            print("byte1 \(byte1) byte2 \(byte2) byte3 \(byte3) byte4 \(byte4) ")
            OneshotDataServiceHelper.sendOneshotRequest(request: [0x10,byte1,byte2,byte3,byte4], peripheral: peripheral, oneShotDataRequestChar: oneShotDataRequestChar)
        }
    }
    
    
    class func sendRequestGetMileage(peripheral: CBPeripheral, oneShotDataRequestChar: CBCharacteristic) {
        OneshotDataServiceHelper.sendOneshotRequest(request: [0x11,0,0,0,0], peripheral: peripheral, oneShotDataRequestChar: oneShotDataRequestChar )
    }
}
