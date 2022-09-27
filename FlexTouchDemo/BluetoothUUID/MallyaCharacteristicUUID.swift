//
//  MallyaCharacteristicUUID.swift
//  FlexTouchDemo
//
//  Created by Cindy Chen on 2022/9/27.
//

import Foundation

enum MallyaCharacteristicUUID: String, CaseIterable {
    case connectionStatus = "E301"
    case registration = "E302"
    case sessionSeed = "E311"
    case powerManagement = "E341"
    case manufacturer = "E351"
    case modelNumber = "E352"
    case serialNumber = "E353"
    case hardwareRevision = "E354"
    case firmwareRevision = "E355"
    case softwareRevision = "E356"
    case hardwareSerialNumber = "E357"
    case injectionEventRequest = "E361"
    case injectionEvent = "E362"
    case traceEventRequest = "E371"
    case traceEvent = "E372"
    case errorEventRequest = "E381"
    case errorEvent = "E382"
    case status = "E3A1"
    case currentDeviceTimeRequest = "E3B1"
    case currentDeviceTime = "E3B2"
    case timeServiceRequest = "E3B3"
    case unknown
    
    init(UUID: String) {
        self = MallyaCharacteristicUUID.allCases.first(where: { $0.rawValue == UUID }) ?? .unknown
    }
}
