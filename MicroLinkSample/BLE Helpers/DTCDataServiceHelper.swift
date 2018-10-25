//
//  DTCDataServiceHelper.swift
//  CarAlgo
//
//  Created by Achraf Letaief on 17/05/2018.
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

let DTCServiceUUID           = CBUUID(string: "DD20")
let DTCCharRequestUUID       = CBUUID(string: "DD21")
let DTCCharResponseUUID      = CBUUID(string: "DD22")

public enum DTCDataResponseEnum: UInt8 {
    case CONFIRMED_DTC = 0x41
    case PENDING_DTC = 0x42
    case NUMBER_DTC = 0x43
    case CLEAR_DTC = 0x44
}

class DTCDataServiceHelper {
    
    class func sendDiagnosticRequest(dtc: UInt8, peripheral: CBPeripheral, dtcDataRequestChar: CBCharacteristic) {
        var value = dtc
        let data = NSData(bytes: &value, length: 1)
            peripheral.writeValue(data as Data, for: dtcDataRequestChar, type: CBCharacteristicWriteType.withResponse)
    }
    
    class func diagnosticDataResponse(array:[UInt8]) -> ([String], UInt8) {
        var dtcBrutArray = [UInt16]()
        var dtcArray = [UInt8]()
        var allDtcArray = [String]()
        var dtcNumber: UInt8 = 0
        switch array[0] {
        case DTCDataResponseEnum.CONFIRMED_DTC.rawValue:
            dtcArray = getDTCs(array: array)
            dtcBrutArray = extractOneDtc(array: dtcArray)
            allDtcArray = getFinalDtcs(tempDtcArray: dtcBrutArray)
            break
        case DTCDataResponseEnum.NUMBER_DTC.rawValue:
            dtcNumber = (array[1] & 0x0F)
            break
        default:
            break
        }
        return (allDtcArray, dtcNumber)
    }
    
    class func getDTCs(array:[UInt8]) -> [UInt8] {
        let dataLength = Int((array[1] * 2) + 1)
        if dataLength > 1 {
            let data = array[2...dataLength]
            return [UInt8](data)
        }
            return []
    }

    class func extractOneDtc(array: [UInt8]) -> [UInt16] {
        var returnedArray = [UInt16]()
        for i in stride(from: 0, through: array.count - 1, by: 2) {
            let value =  uint16FromTwoBytes(array[i + 1], hiByte: array[i])
                returnedArray.append(value)
            }
        return returnedArray
    }
    
    class func getDTCName(dtc: UInt16) -> String {
        let dtctype = (dtc & 0xC000) >> 14
        let value = (dtc & 0x3FFF)
        let stringNumber = String(format:"%04X",value)
        switch dtctype {
        case 0:
            return "P" + stringNumber
        case 1:
            return "C" + stringNumber
        case 2:
            return "B" + stringNumber
        case 3:
            return "U" + stringNumber
        default:
            break
        }
        return ""
    }
    
    class func getFinalDtcs(tempDtcArray:[UInt16]) -> [String] {
        var allDtcArray = [String]()
        for i in 0..<tempDtcArray.count {
            let dtc = getDTCName(dtc: tempDtcArray[i])
            allDtcArray.append(dtc)
        }
        return allDtcArray
    }
}


// String Extensions
extension String {
    subscript (i: Int) -> Character {
        return self[index(startIndex, offsetBy: i)]
    }
    subscript (bounds: CountableRange<Int>) -> Substring {
        let start = index(startIndex, offsetBy: bounds.lowerBound)
        let end = index(startIndex, offsetBy: bounds.upperBound)
        return self[start ..< end]
    }
    subscript (bounds: CountableClosedRange<Int>) -> Substring {
        let start = index(startIndex, offsetBy: bounds.lowerBound)
        let end = index(startIndex, offsetBy: bounds.upperBound)
        return self[start ... end]
    }
    subscript (bounds: CountablePartialRangeFrom<Int>) -> Substring {
        let start = index(startIndex, offsetBy: bounds.lowerBound)
        let end = index(endIndex, offsetBy: -1)
        return self[start ... end]
    }
    subscript (bounds: PartialRangeThrough<Int>) -> Substring {
        let end = index(startIndex, offsetBy: bounds.upperBound)
        return self[startIndex ... end]
    }
    subscript (bounds: PartialRangeUpTo<Int>) -> Substring {
        let end = index(startIndex, offsetBy: bounds.upperBound)
        return self[startIndex ..< end]
    }
}
extension Substring {
    subscript (i: Int) -> Character {
        return self[index(startIndex, offsetBy: i)]
    }
    subscript (bounds: CountableRange<Int>) -> Substring {
        let start = index(startIndex, offsetBy: bounds.lowerBound)
        let end = index(startIndex, offsetBy: bounds.upperBound)
        return self[start ..< end]
    }
    subscript (bounds: CountableClosedRange<Int>) -> Substring {
        let start = index(startIndex, offsetBy: bounds.lowerBound)
        let end = index(startIndex, offsetBy: bounds.upperBound)
        return self[start ... end]
    }
    subscript (bounds: CountablePartialRangeFrom<Int>) -> Substring {
        let start = index(startIndex, offsetBy: bounds.lowerBound)
        let end = index(endIndex, offsetBy: -1)
        return self[start ... end]
    }
    subscript (bounds: PartialRangeThrough<Int>) -> Substring {
        let end = index(startIndex, offsetBy: bounds.upperBound)
        return self[startIndex ... end]
    }
    subscript (bounds: PartialRangeUpTo<Int>) -> Substring {
        let end = index(startIndex, offsetBy: bounds.upperBound)
        return self[startIndex ..< end]
    }
}
