//
//  OADFirmwareHelper.swift
//  MicroLinkTool
//
//  Created by Achraf Letaief on 19/04/2018.
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

class OTAOldFirmwareHelper: NSObject {

    // OTA Helper methods for the old Device
    let OAD_BLOCK_SIZE: UInt16 = 16
    let HAL_FLASH_WORD_SIZE = 4
    
    var iBlocks = 0 // Number of blocks programmed
    var nBlocks = 0 // Total number of blocks
    
    class func crc16(startCrc: UInt16, startVal: UInt8) -> UInt16 {
        var val = startVal
        var crc = startCrc
        let poly: UInt16 = 0x1021
        
        var cnt = 0
        while cnt < 8 {
            var msb = 0
            
            if (crc & 0x8000) == 0x8000 {
                msb = 1
            } else {
                msb = 0
            }
            
            crc <<= 1
            if (val & 0x80) == 0x80 {
                crc |= 0x0001
            }
            
            if msb == 1 {
                crc ^= poly
            }
            
            cnt += 1
            val <<= 1
        }
        
        return crc
    }
    
    class func calcCRC(data:[UInt8]) -> UInt16 {
        var crc: UInt16 = 0
        for offset in 4..<data.count {
            crc = crc16(startCrc: crc, startVal: data[offset])

        }
        
        crc = UInt16(crc16(startCrc: crc, startVal: 0x00))
        crc = UInt16(crc16(startCrc: crc, startVal: 0x00))
        
        return crc
        
    }
    
    // Calculate CRC over the binary blob
    class func calcImageCRC(startPage: Int, data: Data, len: Int) -> UInt16 {
        var crc: UInt16 = 0
        var addr = startPage * 0x1000
        
        var page = startPage
        var pageEnd = (Int)(len / (0x1000 / 4))
        let osetEnd = (len - (pageEnd * (0x1000 / 4))) * 4
        pageEnd += startPage
        while true {
            var oset = 0
            while oset < 0x1000 {
                
                if (page == startPage) && (oset == 0x00) {
                    
                    //Skip the CRC and shadow.
                    //Note: this increments by 3 because oset is incremented by 1 in each pass
                    //through the loop
                    oset += 3
                    
                } else if (page == pageEnd) && (oset == osetEnd) {
                    
                    crc = UInt16(crc16(startCrc: crc, startVal: 0x00))
                    crc = UInt16(crc16(startCrc: crc, startVal: 0x00))
                    return crc
                    
                } else {
    
                    crc = UInt16(crc16(startCrc: crc, startVal: data[addr + oset]))
                }
                
                oset += 1
            }
            
            page += 1
            addr = page * 0x1000
        }
    }
    
    
    // Generate the image header data to identify with the OAD target
    class func imgIdentifyRequestData(crc0: UInt16, crc1: UInt16, len: Int, imgType: UInt8, addr: UInt32) -> Data {
        let uid = [UInt8](repeating: 0x45, count: 4)
        let ver = 0
        var tmp = Array<UInt8>()
        
        tmp.append(UInt8(crc0 & 0xFF))
        tmp.append(UInt8((crc0 >> 8) & 0xFF))
        tmp.append(UInt8(crc1 & 0xFF))
        tmp.append(UInt8((crc1 >> 8) & 0xFF))
        tmp.append(UInt8(ver & 0xFF))
        tmp.append(UInt8((ver >> 8) & 0xFF))
        tmp.append(UInt8(len & 0xFF))
        tmp.append(UInt8((len >> 8) & 0xFF))
        tmp.append(uid[0])
        tmp.append(uid[1])
        tmp.append(uid[2])
        tmp.append(uid[3])
        tmp.append(UInt8(addr & 0xFF))
        tmp.append(UInt8((addr >> 8) & 0xFF))
        tmp.append(UInt8(imgType & 0xFF))
        tmp.append(UInt8(0xFF))
        
        return Data(bytes: tmp, count: tmp.count)
    }
    
    class  func OADProcessRequestBlock(blockNumber: [UInt8], data: Data, peripheral: CBPeripheral, oadBlockRequestChar: CBCharacteristic) {
        let u16BlockNumber = uint16FromTwoBytes(blockNumber[0], hiByte: blockNumber[1])
       
        let intBlock = Int(u16BlockNumber)
        
        var block = [UInt8](repeating: 0, count: 18)
        block[0] = blockNumber[0]
        block[1] = blockNumber[1]
        
        let range = Range(intBlock * 16..<intBlock * 16 + 16)
        let subdata = data.subdata(in: range)
        subdata.copyBytes(to: &block[2], count: 16)
        
        print("Block == \(block)")

       // let data = Data(bytes: block)
        peripheral.writeValue(Data(bytes: block, count: block.count), for: oadBlockRequestChar, type: .withoutResponse)
        
    }
}
