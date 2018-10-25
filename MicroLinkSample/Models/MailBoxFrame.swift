//
//  MailBoxFrame.swift
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

class MailBoxFrame: NSObject {

    var mesureTitle: String
    var mesureUnit: String
    var mailBoxNumber: UInt8
    var dataLength: UInt8
    var dataOffset: UInt8
    var frameID: UInt32
    var alphaCoeff: String
    var betaCoeff: String
    
    init(mailBoxNumber: UInt8, dataLength: UInt8, dataOffset: UInt8, frameID: UInt32, mesureTitle: String, mesureUnit: String, alphaCoeff: String, betaCoeff: String) {
        self.mailBoxNumber = mailBoxNumber
        self.dataLength = dataLength
        self.dataOffset = dataOffset
        self.frameID = frameID
        self.mesureTitle = mesureTitle
        self.mesureUnit = mesureUnit
        self.alphaCoeff = alphaCoeff
        self.betaCoeff = betaCoeff
    }
    
    func convertToDictionary() -> [String : Any] {
        let dic: [String: Any] = ["configName":self.mesureTitle, "frameID":self.frameID, "length":self.dataLength, "offset":self.dataOffset, "alpha": self.alphaCoeff, "beta": self.betaCoeff, "unit": self.mesureUnit]
        
        return dic
    }
}
