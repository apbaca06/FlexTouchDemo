//
//  MallyaCharacteristicInfo.swift
//  FlexTouchDemo
//
//  Created by Cindy Chen on 2022/9/27.
//

import Foundation
import CoreBluetooth

struct MallyaCharacteristicInfo {
    let characteristic: CBCharacteristic
    var type: MallyaCharacteristicUUID {
        MallyaCharacteristicUUID(UUID: characteristic.uuid.uuidString)
    }
}
