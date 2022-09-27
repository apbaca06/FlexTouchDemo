//
//  MallyaCurrentTimePayload.swift
//  FlexTouchDemo
//
//  Created by Cindy Chen on 2022/9/26.
//

import Foundation

struct MallyaCurrentTimePayload: Payload {
    let currentTime: UInt32
    let crc: UInt16
    private let data: Data

    init?(_ data: Data) {
        guard !data.isEmpty else { return nil }
        let dataReader = DataReader(data)
        self.data = data
        currentTime = dataReader.readNext()
        crc = dataReader.readNext()
    }
}
