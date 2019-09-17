# CarAlgo Sample

This project illustrates the interaction between the CarAlgo Device and the iOS platform via BLE written in Swift 4.

## Getting Started

The project contains a folder named "BLE Helpers" and another is called "Models". You can just copy these in your project. But it is **_highly recommanded_** to run the provided sample and read the [documentation](docs/CONTRIBUTING.md) in order to get an idea on how things work.

### Prerequisites

In order to install and run correctly this sample you'll need:
- Xcode 9.2 (mininum).
- CarAlgo peripheral.
- A car simulator software or an actual car.

### Installing

1. Plug the CarAlgo Device in the OBD socket of the car.
2. Activate the Bluetooth on your iOS device and run the sample app.
3. Connect to the "MicroLink" shown.

## Running the tests

Once connected to the peripheral from the app, the central manager will discover all services and characteristics within the peripheral.
The first thing to do after that is requesting **The vehicle communication protocol** using this method:
```
OneshotDataServiceHelper.sendOneshotRequest(request: [3,0,0,0,0], peripheral: connectedPeripheral, oneShotDataRequestChar: oneShotDataRequestChar!)
```
If the peripheral finds the vehicle protocol then you'll get a  response in the method:
```
class func getProtocolResponseProcess(data:[UInt8], peripheral: CBPeripheral, periodicDataRequestChar: CBCharacteristic, periodicDataResponseChar: CBCharacteristic, oneShotDataRequestChar: CBCharacteristic)
```

In case of a negative response (which means the peripheral didn't find any known vehicle protocol), **The Car Connection status** is set to **CAR_CONNECTION_OFF** and the attempts to restore Car connection are launched.

In case of a positive response  **The Car Connection status** is set to **CAR_CONNECTION_ON**
This case means that the CarAlgo Device is set correctly and the interaction between the car, CarAlgo device and iOS device is established.

#### Sending/Getting Vehicle data
##### One shot data
The one shot data is treated by *send/receive* methods.
###### Send one shot request
The method is found in `OneshotDataServiceHelper`
```
func sendOneshotRequest(request: [UInt8], peripheral: CBPeripheral, oneShotDataRequestChar: CBCharacteristic)
```
###### Get one shot response
```
func oneShotDataResponseProcess(array: [UInt8], timeout: Bool)
```
* Send request to get VIN
```
 OneshotDataServiceHelper.sendOneshotRequest(request: [1,0,0,0,0], peripheral: connectedPeripheral, oneShotDataRequestChar: oneShotDataRequestChar!)
```
The returned data is treated in `oneShotDataResponseProcess`
```
let vinValue = OneshotDataServiceHelper.getVIN(data: array)
```
*  Send request to get Battery Level

```
OneshotDataServiceHelper.sendOneshotRequest(request: [2,0,0,0,0], peripheral: connectedPeripheral, oneShotDataRequestChar: oneShotDataRequestChar!)
```
* Get Battery Level

```
let batteryLevel = OneshotDataServiceHelper.getBatteryValue(data: array)
```
And the same goes with all one shot requests/responses.
##### Periodic data
When the car connection is on, you can send **The periodic configuration** and set the notify to its characteristic to true.
You will then get data every second or two (depending on the vehicle protocol) and you can process that data via the methods declared in the `PeriodicDataServiceHelper` class.

###### Send periodic configuration
```
peripheral.setNotifyValue(true, for: periodicDataResponseChar)
PeriodicDataServiceHelper.periodicConfiguration(peripheral: peripheral, periodicDataRequestChar: periodicDataRequestChar)
```
###### Process periodic response

You can process the periodic response in  `func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?)` via the method:
`periodicResponseProcess(array:[UInt8])`

#### Firmware Upgrade

The methods to achieve the firmware upgrade for the peripheral are implemented in the `OTANewFirmwareHelper` class.
The process is done by Request/Response mechanism. Here are the steps to do so:

1. Import the binary file which contains the new firmware revision into your project.
2. Use the method `readStream(path: String)` to extract the **imageId**, **imageVersion** and **totalLength**.
3. Send the first request to the peripheral; The request is in this form: 
`[0x03,imageId,imageVersion,totalLength]` on the **otaControlPointChar**.
4. Getting the response from the first request and extracting the **startPosition**, **blockSize** and the **chunckSize**
5. Proceed by sending blocks by using `sendBlock(startPosition: Int(startPosition), blockSize: Int(blockSize), chunckSize: Int(chuckSize))`
6. Repeat step 5 until receiving the value **0x06 on the first byte** of the response which means that all blocks are sent.

## Author

**Achraf Letaief** achraf.letaief@smarto.fr

## Contributors
**Toufik Nacer** toufik.nacer@smarto.fr
**Hatem Drira**  hatem.drira@smarto.fr

## License
```
Copyright (c) 2018 SMARTO SAS 25 Quai Gallieni 92150 SURESNES FRANCE

Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the "Software"), to deal in
the Software without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
the Software, and to permit persons to whom the Software is furnished to do so,
subject to the following conditions:

The person need to buy the CarAlgo device.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
```


