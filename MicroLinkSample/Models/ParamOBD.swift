//
//  ParamOBD.swift
//  MicroLinkSample
//
//  Created by Achraf Letaief on 24/05/2018.
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

class ParamOBD: NSObject {

    var engineLoad: String
    var manAbsPressure: String
    var batteryLvl: String
    var engineRpm: String
    var airTemperature: String
    var airFlowRate: String
    var speed: String
    
    init(engineLoad: String, manAbsPressure: String, batteryLvl: String, engineRpm: String, airTemperature: String, airFlowRate: String, speed: String) {
        self.engineLoad = engineLoad
        self.manAbsPressure = manAbsPressure
        self.batteryLvl = batteryLvl
        self.engineRpm = engineRpm
        self.airTemperature = airTemperature
        self.airFlowRate = airFlowRate
        self.speed = speed
        
        super.init()
        
    }
    
    func convertToDictionary() -> [String : Any] {
        let dic: [String: Any] = ["engineLoad":self.engineLoad, "manAbsPressure":self.manAbsPressure, "batteryLvl":self.batteryLvl, "engineRpm":self.engineRpm, "airTemperature":self.airTemperature, "airFlowRate":self.airFlowRate, "speed":self.speed]
        
        return dic
    }
}
