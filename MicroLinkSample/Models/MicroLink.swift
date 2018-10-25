//
//  MicroLink.swift
//  CarAlgo
//
//  Created by Achraf Letaief on 23/03/2018.
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

let DeviceInfoServiceUUID      = CBUUID(string: "180A")
let SystemIDUUID               = CBUUID(string: "2A23")
let ModelNumberUUID            = CBUUID(string: "2A24")
let ManufacturerNameUUID       = CBUUID(string: "2A29")
let FirmwareRevisionUUID       = CBUUID(string: "2A26")
let SoftwareRevisionUUID       = CBUUID(string: "2A28")
let HardwareRevisionUUID       = CBUUID(string: "2A27")
let DIServiceUUID              = CBUUID(string: "DD00")
let SerialNumberUUID           = CBUUID(string: "2A25")


let OADServiceUUID             =   CBUUID(string:"F000FFC0-0451-4000-B000-000000000000")
let OADImageNotifyUUID         =   CBUUID(string:"F000FFC1-0451-4000-B000-000000000000")
let OADImageBlockRequestUUID   =   CBUUID(string:"F000FFC2-0451-4000-B000-000000000000")


let isValidData = 0x01
let isInvalidData = 0xFF

public enum CarChecker: UInt8 {
    case CAR_OFF_PHONE_OFF = 0
    case CAR_OFF_PHONE_ON = 1
    case CAR_ON_PHONE_ON = 2
}

var CarConnectionStatus = MicroLinkCarConnectionState.CAR_CONNECTION_OFF
var carCheckStatus = CarChecker.CAR_OFF_PHONE_OFF

//MARK:- Device readings
struct DeviceInfo {
    var systemID: String
    var modelNumber: String
    var manufacturer: String
    var firmwareRevision: String
    var serialNumber: String
    var softwareRevision: String
    var hardwareRevision: String
    
    init(systemID: String, modelNumber: String, manufacturer: String, firmwareRevision: String, serialNumber: String, softwareRevision: String, hardwareRevision: String) {
        self.systemID = systemID
        self.modelNumber = modelNumber
        self.manufacturer = manufacturer
        self.firmwareRevision = firmwareRevision
        self.serialNumber = serialNumber
        self.softwareRevision = softwareRevision
        self.hardwareRevision = hardwareRevision
    }
    
    static func formatToString(deviceInfo: DeviceInfo) -> String {
        return String(format: "Model Number: %@ \n Manufacturer: %@ \n Firmware: %@ \n Software: %@ \n Hardware: %@ \n Serial Number: %@", deviceInfo.modelNumber, deviceInfo.manufacturer, deviceInfo.firmwareRevision, deviceInfo.softwareRevision, deviceInfo.hardwareRevision, deviceInfo.serialNumber)
    }
    
}

public enum MicroLinkCarConnectionState: Int {
    case CAR_CONNECTION_OFF = 0
    case CAR_CONNECTION_ON = 1
}


// Conversion helpers
func uint32ToLittleEndianBytesArray(_ uint32: UInt32) -> [UInt8] {
    var littleEndian = uint32.littleEndian
    
    let count = MemoryLayout<UInt32>.size
    
    let bytePtr = withUnsafePointer(to: &littleEndian) {
        $0.withMemoryRebound(to: UInt8.self, capacity: count) {
            UnsafeBufferPointer(start: $0, count: count)
        }
    }
    let byteArray = Array(bytePtr)
    return byteArray
}

func uint16ToLittleEndianBytesArray(_ uint16: UInt16) -> [UInt8] {
    var littleEndian = uint16.littleEndian
    
    let count = MemoryLayout<UInt16>.size
    
    let bytePtr = withUnsafePointer(to: &littleEndian) {
        $0.withMemoryRebound(to: UInt8.self, capacity: count) {
            UnsafeBufferPointer(start: $0, count: count)
        }
    }
    let byteArray = Array(bytePtr)
    return byteArray
}




func uint16FromTwoBytes(_ loByte: UInt8, hiByte: UInt8) -> UInt16 {
    let lowByte  = UInt16(loByte & 0xFF)
    let highByte = UInt16(hiByte & 0xFF) << 8
    return highByte | lowByte
}

func int16FromTwoBytes(_ loByte: UInt8, hiByte: UInt8) -> Int16 {
    let lowByte  = Int16(loByte & 0xFF)
    let highByte = Int16(hiByte & 0xFF) << 8
    return highByte | lowByte
}



func uint32FromFourBytes(_ loloByte: UInt8, lohiByte: UInt8, hiloByte: UInt8, hihiByte: UInt8) -> UInt32 {
    let lowLowByte   = UInt32(loloByte & 0xFF)
    let lowHighByte  = UInt32(lohiByte & 0xFF) << 8
    let highLowByte  = UInt32(hiloByte & 0xFF) << 16
    let highHighByte = UInt32(hihiByte & 0xFF) << 24
    return highHighByte | highLowByte | lowHighByte | lowLowByte
}

func dataToIntegerArray<T: BinaryInteger>(_ value: Data) -> [T] {
    let dataLength = value.count
    let count = dataLength / MemoryLayout<T>.size
    var array = [T](repeating: 0x00, count: count)
    (value as NSData).getBytes(&array, length:dataLength)
    return array
}

func toByteArray<T>(_ value: T) -> [UInt8] {
    var value = value
    return withUnsafePointer(to: &value) {
        $0.withMemoryRebound(to: UInt8.self, capacity: MemoryLayout<T>.size) {
            Array(UnsafeBufferPointer(start: $0, count: MemoryLayout<T>.size))
        }
    }
}

func fromByteArray<T>(_ value: [UInt8], _: T.Type) -> T {
    return value.withUnsafeBufferPointer {
        $0.baseAddress!.withMemoryRebound(to: T.self, capacity: 1) {
            $0.pointee
        }
    }
}

extension FloatingPoint {
    
    init?(_ bytes: [UInt8]) {
        
        guard bytes.count == MemoryLayout<Self>.size else { return nil }
        
        self = bytes.withUnsafeBytes {
            
            return $0.load(fromByteOffset: 0, as: Self.self)
        }
    }
}

extension UInt8 {
    var char: Character {
        return Character(UnicodeScalar(self))
    }
}

extension Int {
    var char: Character {
        return Character(UnicodeScalar(self)!)
    }
}
