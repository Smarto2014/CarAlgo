//
//  OTANewFirmwareHelper.swift
//
//
//  Created by Achraf Letaief on 15/01/2019.
//  Copyright © 2019 Achraf Letaief. All rights reserved.
//

import CoreBluetooth

class OTANewFirmwareHelper: NSObject {
    
    let OTAControlPointUUID = CBUUID(string: "01ff5551-ba5e-f4ee-5ca1-eb1e5e4b1ce0")
    let OTADataUUID = CBUUID(string: "01ff5552-ba5e-f4ee-5ca1-eb1e5e4b1ce0")
    
    var otaControlPointChar: CBCharacteristic?
    var otaDataChar: CBCharacteristic?
    
    var connectedPeripheral: CBPeripheral?
    
    var imageId = [UInt8]()
    var imageVersion = [UInt8]()
    var totalLength = [UInt8]()
    var fileArray = [UInt8]()
    var totalLengthDecimal = 0
    
    // 1. Reading the binary file and extract info
    private func readFileFromPath(path: String) {
        let binaryFileData = readStream(path: path)
        print("data", binaryFileData.count)
        print("imageId", imageId)
        print("imageVersion", imageVersion)
        print("totalLength",totalLength)
    }
    
    
    private func readStream(path: String) -> Data {
        var array = [UInt8]()
        if let stream:InputStream = InputStream(fileAtPath: path) {
            var buf:[UInt8] = [UInt8](repeating: 0, count: 16)
            stream.open()
            while true {
                let len = stream.read(&buf, maxLength: buf.count)
                for i in 0..<len {
                    array.append(buf[i])
                }
                if len < buf.count {
                    break
                }
            }
            stream.close()
        }
        imageId = Array(array[12...13])
        imageVersion = Array(array[14...21])
        totalLength = Array(array[54...57])
        fileArray = array
        totalLengthDecimal = Int(uint32FromFourBytes(totalLength[0], lohiByte: totalLength[1], hiloByte: totalLength[2], hihiByte: totalLength[3]))
        return Data(array)
    }
    
    
    
    //2. Sending first request
    func uploadBtnAction() {
        if totalLength.count > 0 {
            var request = [UInt8]()
            request.append(0x03)
            request.append(contentsOf: imageId)
            request.append(contentsOf: imageVersion)
            request.append(contentsOf: totalLength)
            let data = NSData(bytes: request, length: request.count)
            connectedPeripheral?.writeValue(data as Data, for: otaControlPointChar!, type: .withResponse)
        }
        
    }
    
    func sendBlock(startPosition: Int, blockSize: Int, chunckSize: Int) {
        var offset = startPosition
        var len = blockSize/chunckSize
        if blockSize % chunckSize != 0 {
            len += 1
        }
        for i in 0..<len {
            usleep(15000)
            if (startPosition + (i+1) * chunckSize) < self.fileArray.count {
                len = chunckSize
            }else {
                len = blockSize % chunckSize
            }
            var request = [UInt8]()
            request.append(0x05)
            request.append(UInt8(i))
            request.append(contentsOf: self.fileArray[offset..<offset + len])
            
            let data = NSData(bytes: request, length: request.count)
            self.connectedPeripheral?.writeValue(data as Data, for: self.otaDataChar!, type: CBCharacteristicWriteType.withoutResponse)
            offset += len
            
        }
    }
    
}

// MARK: - CBPeripheral Delegate
extension OTANewFirmwareHelper: CBPeripheralDelegate {

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
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard error == nil else {
            print("didDiscoverCharacteristicsForService error: \(String(describing: error))")
            return
        }
        guard let characteristics = service.characteristics else { return }
        for charateristic in characteristics {
            let thisCharacteristic = charateristic as CBCharacteristic
            switch (thisCharacteristic.uuid) {
            case OTAControlPointUUID:
                self.otaControlPointChar = thisCharacteristic
                peripheral.setNotifyValue(true, for: self.otaControlPointChar!)
                break
            case OTADataUUID:
                self.otaDataChar = thisCharacteristic
                break
            default:
                break
            }
        }
    }
    
    // Get data values when they are updated
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if let data = characteristic.value {
            let array = [UInt8](data)
            if array[0] == 0x04 {
                let startPosition = uint32FromFourBytes(array[3], lohiByte: array[4], hiloByte: array[5], hihiByte: array[6])
                let blockSize = uint32FromFourBytes(array[7], lohiByte: array[8], hiloByte: array[9], hihiByte: array[10])
                let chuckSize = uint16FromTwoBytes(array[11], hiByte: array[12])
                //3. Sending block by block
                sendBlock(startPosition: Int(startPosition), blockSize: Int(blockSize), chunckSize: Int(chuckSize))
            }
            
            //4. After all blocks are sent, check the status
            if array[0] == 0x06 {
                if array[3] == 0x00 {
                    print("Upload done successfully")
                }else {
                    print("Failed to upload Firmware")
                }
                
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error { print("didWriteValueForCharacteristic error: \(error)") }
    }
}
