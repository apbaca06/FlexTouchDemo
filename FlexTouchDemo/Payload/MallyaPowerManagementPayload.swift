//
//  MallyaPowerManagementPayload.swift
//  FlexTouchDemo
//
//  Created by Cindy Chen on 2022/9/26.
//

import Foundation

struct MallyaPowerManagementPayload: Payload {
    let powerFlags: UInt8
    let isLowBattery: Bool
    let isCharging: Bool
    let isChargerPlugged: Bool
    let isBatteryFull: Bool
    let isBatteryLevelPresent: Bool
    private(set)var batteryLevel: UInt8 = 0
    let crc: UInt16
    private let data: Data
    
    enum MallyaPowerType: Int, Flag {
        typealias IntegerType = UInt8
        
        case lowBattery = 0
        case isCharging = 1
        case isChargerPlugged = 2
        case isBatteryFull = 3
        case isBatteryLevelPresent = 4
        case unknown
    }

    init?(_ data: Data) {
        guard !data.isEmpty else { return nil }
        let dataReader = DataReader(data)
        self.data = data
        powerFlags = dataReader.readNext()
        isLowBattery = powerFlags[MallyaPowerType.lowBattery.rawValue]
        isCharging = powerFlags[MallyaPowerType.isCharging.rawValue]
        isChargerPlugged = powerFlags[MallyaPowerType.isChargerPlugged.rawValue]
        isBatteryFull = powerFlags[MallyaPowerType.isBatteryFull.rawValue]
        isBatteryLevelPresent = powerFlags[MallyaPowerType.isBatteryLevelPresent.rawValue]
        
        if isBatteryLevelPresent {
            batteryLevel = dataReader.readNext()
        }
        crc = dataReader.readNext()
    }
}
