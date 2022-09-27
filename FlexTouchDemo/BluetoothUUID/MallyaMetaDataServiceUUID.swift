//
//  MallyaMetaDataServiceUUID.swift
//  FlexTouchDemo
//
//  Created by Cindy Chen on 2022/9/27.
//

import Foundation
import CoreBluetooth

enum MallyaMetaDataServiceUUID: String, CaseIterable {
    case flextouch = "EFA1"
    case unknown
    
    init(metaUUID: String) {
        self = MallyaMetaDataServiceUUID.allCases.first(where: { $0.rawValue == metaUUID }) ?? .unknown
    }
    
    var cbUUID: CBUUID {
        CBUUID(string: rawValue)
    }
}
