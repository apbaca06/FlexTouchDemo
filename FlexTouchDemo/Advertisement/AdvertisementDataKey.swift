//
//  AdvertisementDataKey.swift
//  FlexTouchDemo
//
//  Created by Cindy Chen on 2022/9/27.
//

import Foundation

struct AdvertisementDataKey {
    let key: String
    
    static let localName = AdvertisementDataKey(key: "kCBAdvDataLocalName")
    static let serviceData = AdvertisementDataKey(key: "kCBAdvDataServiceData")
    static let powerLevel = AdvertisementDataKey(key: "kCBAdvDataTxPowerLevel")
}
