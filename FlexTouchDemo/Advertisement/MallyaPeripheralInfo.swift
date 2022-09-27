//
//  MallyaPeripheralInfo.swift
//  FlexTouchDemo
//
//  Created by Cindy Chen on 2022/9/27.
//

import Foundation
import CoreBluetooth

struct MallyaPeripheralInfo {
    let peripheral: CBPeripheral
    let bluetoothIdentifier: String
    let advertisementData: MallyaAdvertisementData
    var isNewDevice: Bool { advertisementData.isNewDevice }
    var mallyaMetaDataType: MallyaMetaDataServiceUUID { advertisementData.mallyaType }
}
