//
//  MallyaServiceUUID.swift
//  FlexTouchDemo
//
//  Created by Cindy Chen on 2022/9/27.
//

import Foundation

enum MallyaServiceUUID: String, CaseIterable {
    case connection = "E300"
    case sessionSeed = "E310"
    case immediateAlert = "E320"
    case linkLoss = "E330"
    case powerManagement = "E340"
    case deviceInfo = "E350"
    case injectionEvents = "E360"
    case configuration = "E390"
    case traceEvents = "E370"
    case errorEvents = "E380"
    case status = "E3A0"
    case time = "E3B0"
    case unknown
    
    init(serviceUUID: String) {
        self = MallyaServiceUUID.allCases.first(where: { $0.rawValue == serviceUUID }) ?? .unknown
    }
}
