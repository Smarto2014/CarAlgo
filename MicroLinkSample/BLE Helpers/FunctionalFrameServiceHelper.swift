//
//  FunctionalFrameServiceHelper.swift
//  MicroLinkTool
//
//  Created by Achraf Letaief on 03/04/2018.
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

let FunctionalFrameServiceUUID        = CBUUID(string: "DD30")
let FunctionalFrameRequestUUID        = CBUUID(string: "DD31")
let FunctionalFrameResponseUUID       = CBUUID(string: "DD32")

class FunctionalFrameServiceHelper: NSObject {

    class func functionalFrameConfig(mailBox: MailBoxFrame) -> [UInt8] {
        var configArray = [UInt8](repeating: UInt8(), count: 12)
        configArray[0] = 0x01 // Byte0: 0x00 -> Read / 0x01 -> write
        configArray[1] = 0x01 // Byte1: 0x00 ->Disable / 0x01 ->Enable
        configArray[2] = mailBox.mailBoxNumber // Byte2: MailBox Number(3<= Mailbox Number<=30)
        configArray[3] = 0x01 // Byte3: Notif Type  /  0x00 -> Périodique Notification / 0x01 ->NewData Notification
        configArray[4] = 0x00 // Byte4: Period
        configArray[5] = 0x00 // Byte5: Unit Period / 0x00 -> 100 ms unit / 0x01 -> 1s unit
        configArray[6] = 0x00 // Byte6: type ID / 0 -> Standard  1 -> Extended
        configArray[7] = UInt8(mailBox.frameID & 0xFF) //    Byte7-10: ID Frame
        configArray[8] = UInt8((mailBox.frameID & 0xFF00) >> 8)
        configArray[9] = UInt8((mailBox.frameID & 0xFF0000) >> 16)
        configArray[10] = UInt8((mailBox.frameID & 0xFF000000) >> 24)
        configArray[11] = 0x00 // Byte11: Status
       
        return configArray
    }
    
    class func functionalFrameConfigDisable(mailBox: MailBoxFrame) -> [UInt8] {
        var configArray = [UInt8](repeating: UInt8(), count: 12)
        configArray[0] = 0x01 // Byte0: 0x00 -> Read / 0x01 -> write
        configArray[1] = 0x00 // Byte1: 0x00 ->Disable / 0x01 ->Enable
        configArray[2] = mailBox.mailBoxNumber // Byte2: MailBox Number(3<= Mailbox Number<=30)
        
        return configArray
    }
    
    class func functionalFrameRequest(request: [UInt8],peripheral: CBPeripheral ,functionalFrameRequestChar: CBCharacteristic) {
        var arrayToSend = request
        let data = NSData(bytes: &arrayToSend, length: 12)
        peripheral.writeValue(data as Data, for: functionalFrameRequestChar, type: CBCharacteristicWriteType.withResponse)
    }
    
    
    class func functionalFrameResponseProcess(data:[UInt8],mailBoxArray: [MailBoxFrame]) -> Double {
        let cfgMailBox = mailBoxArray[Int(data[0])]
        let value = extractData(data: data, mailBoxFrame: cfgMailBox)
        return value
    }
    
    class func extractData(data:[UInt8], mailBoxFrame: MailBoxFrame) -> Double {
        let array = data[1..<data.count]
        let data = Data(bytes: array.reversed())
        var value = UInt64(littleEndian: data.withUnsafeBytes { $0.pointee })
        let mask = createMask(length: mailBoxFrame.dataLength , offset: mailBoxFrame.dataOffset)
        value = value & mask
    
        value = value >> (64 - (mailBoxFrame.dataLength + mailBoxFrame.dataOffset))

        return Double(value)
    }
    
    class func createMask(length: UInt8 , offset: UInt8) -> UInt64 {
        var mask : UInt64 = 0x8000000000000000
        for _ in 0..<(length - 1){
            mask = (mask >> UInt64(1))
            mask = mask | 0x8000000000000000
        }
        
        for _ in 0..<offset{
            mask = (mask >> UInt64(1))
        }
        return UInt64(mask)
    }
    
   
}



