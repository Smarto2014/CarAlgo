//
//  CanDiagServiceHelper.swift
//  MicroLinkSample
//
//  Created by Achraf Letaief on 21/05/2018.
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

let CanDiagServiceUUID           = CBUUID(string: "BB00")
let CanDiagCharRequestUUID       = CBUUID(string: "BB01")
let CanDiagCharResponseUUID      = CBUUID(string: "BB02")


class CANDiagServiceHelper: NSObject {
    
    class func sendCanRequest(request: [UInt8], peripheral: CBPeripheral, canDiagRequestChar: CBCharacteristic) {
        var arrayToSend = request
        let data = NSData(bytes: &arrayToSend, length: request.count)
        peripheral.writeValue(data as Data, for: canDiagRequestChar, type: CBCharacteristicWriteType.withResponse)
    }
    

}
