//
//  MallyaConnectionStatusPayload.swift
//  FlexTouchDemo
//
//  Created by Cindy Chen on 2022/9/22.
//

import Foundation

struct MallyaConnectionStatusPayload: Payload {
    var statusType: MallyaConnectionStatus { MallyaConnectionStatus(value: status) }
    var errorInLastEventType: MallyaConnectionErrorEvent { MallyaConnectionErrorEvent(value: errorInLastEvent) }
    private let status: UInt8
    private let errorInLastEvent: UInt8
    private(set)var registrationID: UInt32?
    private(set)var rtcID: UInt16?
    private(set)var resolvableUniqueIdentifier: UInt32?
    let crc: UInt16

    enum MallyaConnectionStatus: Int, Flag {
        typealias IntegerType = UInt8
        
        case paired = 0
        case registered = 1
        case appTimeManagementVerified = 2
        case unknown
        
        init(value: UInt8) {
            self = MallyaConnectionStatus(rawValue: Int(value)) ?? .unknown
        }
    }

    enum MallyaConnectionErrorEvent: Int, Flag {
        typealias IntegerType = UInt8
        case none = 0
        case registrationFailed = 1
        case unknown
        
        init(value: UInt8) {
            self = MallyaConnectionErrorEvent(rawValue: Int(value)) ?? .unknown
        }
    }
    
    init?(_ data: Data) {
        guard !data.isEmpty else { return nil }
        let dataReader = DataReader(data)
        self.status = dataReader.readNext()
        
        self.errorInLastEvent = dataReader.readNext()
        
        if status.flags().contains(MallyaConnectionStatus.paired) {
            self.registrationID = .some(dataReader.readNext())
            self.rtcID = .some(dataReader.readNext())
            self.resolvableUniqueIdentifier = .some(dataReader.readNext())
        }
        self.crc = dataReader.readNext()
    }
}
