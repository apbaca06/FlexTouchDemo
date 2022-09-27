//
//  MallyaAdvertisementData.swift
//  FlexTouchDemo
//
//  Created by Cindy Chen on 2022/9/27.
//

import Foundation
import CoreBluetooth

struct MallyaAdvertisementData {
    let kCBAdvDataLocalName: String?
    let kCBAdvDataServiceData: [CBUUID: Data]
    let kCBAdvDataTxPowerLevel: Int
    var mallyaType: MallyaMetaDataServiceUUID {
        kCBAdvDataServiceData.keys.map{ MallyaMetaDataServiceUUID(metaUUID: $0.uuidString)}.first ?? .unknown
    }
    var isNewDevice: Bool { kCBAdvDataTxPowerLevel < 0 }
}
