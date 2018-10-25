//
//  PeriodicDataServiceHelper.swift
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

let PeriodicDataServiceUUID           = CBUUID(string: "DD00")
let PeriodicDataCharRequestUUID       = CBUUID(string: "DD01")
let PeriodicDataCharResponseUUID      = CBUUID(string: "DD02")


class PeriodicDataServiceHelper: NSObject {
    
    class func periodicConfiguration(peripheral: CBPeripheral, periodicDataRequestChar: CBCharacteristic) {
        print("send periodicConfiguration")
        // Send custom configuration
        let array: [UInt8] = [0x01,0x06,0x01,0x04,0x01,0x0B,0x02,0x0C,0x01,0x0D,0x01,0x0F,0x02,0x10,0x00,0x00]
        let data = NSData(bytes: array, length: 16)
        peripheral.writeValue(data as Data, for: periodicDataRequestChar, type: CBCharacteristicWriteType.withResponse)
        
    }
    
    // Get Engine Load
    class func getEngineLoad(response: [UInt8]) -> Double {
        let validity = response[4]
        if validity == 1 {
            UserDefaults.standard.set(Double(response[5]) / 2.55, forKey: "getEngineLoad")
            return Double(response[5]) / 2.55
        }else {
            let v = getValueIfExists(value: "getEngineLoad")
            return v
        }
    }
    
    // Get Absolute Pressure
    class func getAbsolutePressure(response: [UInt8]) -> Double {
        let validity = response[6]
        if validity == 1 {
            UserDefaults.standard.set(response[7], forKey: "getAbsolutePressure")
            return Double(response[7])
        }else {
            let v = getValueIfExists(value: "getAbsolutePressure")
            return v
        }
    }
    
    // Get Engine RPM
    class func getEngineRPM(response: [UInt8]) -> Double {
        let validity = response[8]
        if validity == 1 {
            let rpm = (UInt16(response[9]) * UInt16(256) + UInt16(response[10])) / 4
             UserDefaults.standard.set(rpm, forKey: "getEngineRPM")
            return Double(rpm)
        }else {
            return -1
        }
    }
    
    // Get Vehicule Speed
    class func getVehiculeSpeed(response: [UInt8]) -> Double {
        let validity = response[11]
        if validity == 1 {
            UserDefaults.standard.set(response[12], forKey: "getVehiculeSpeed")
            return Double(response[12])
        }else {
            let v = getValueIfExists(value: "getVehiculeSpeed")
            return v
        }
    }
    
    // Get Air Temperature
    class func getAirTemperature(response: [UInt8]) -> Double {
        let validity = response[13]
        if validity == 1 {
          //  let n: Float = Float(response[14] - 40)
             UserDefaults.standard.set(response[14], forKey: "getAirTemperature")
            return Double(0)
        }else {
            let v = getValueIfExists(value: "getAirTemperature")
            return v
        }
    }
    
    // Get Air Flow Rate
    // MAF = ((256 x A) + B )/ 100
    class func getAirFlowRate(response: [UInt8]) -> Double {
        let validity = response[15]
        if validity == 1 {
            let airFlow = ((256 * Int(response[16])) + Int(response[17])) / 100
            UserDefaults.standard.set(airFlow, forKey: "getAirFlowRate")
            return Double(airFlow)
        }else {
            let v = getValueIfExists(value: "getAirFlowRate")
            return v
        }
    }
    
    class func getInstantFuelConsumption(fuelFlow: Double, vss: Double) -> Double {
        return fuelFlow / vss
    }
    
    class func getValueIfExists(value: String) -> Double {
        if let v = UserDefaults.standard.object(forKey: value) as? Double {
            return v
        }else {
            return 0
        }
    }
    
}
