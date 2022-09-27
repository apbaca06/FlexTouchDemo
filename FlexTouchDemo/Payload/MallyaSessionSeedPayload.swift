//
//  MallyaSessionSeedPayload.swift
//  FlexTouchDemo
//
//  Created by Cindy Chen on 2022/9/22.
//

import Foundation

struct MallyaSessionSeedPayload: Payload {
    private let type: UInt8
    private(set)var seed: [UInt8] = Array(repeating: 0, count: 16)
    var isSessionSeedEmpty: Bool {
        seed.filter{ $0 == .zero }.count == seed.count
    }
    let crc: UInt16

    init?(_ data: Data) {
        guard !data.isEmpty else { return nil }
        let dataReader = DataReader(data)
        type = dataReader.readNext()
        
        if type == .zero {
            seed = dataReader.readArrayWithSize(chunkSize: 16)
        }
        crc = dataReader.readNext()
    }
}
