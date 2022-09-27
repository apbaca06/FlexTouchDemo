//
//  Data+Extension.swift
//  FlexTouchDemo
//
//  Created by Cindy Chen on 2022/9/27.
//

import Foundation

extension Data {
    var hexString: String {
        self.withUnsafeBytes { bufferPointer in
            bufferPointer.map{String(format: "%02X", $0)}.joined()
        }
    }
    
    private func getByteArray(pointer: UnsafePointer<UInt8>) -> [UInt8] {
        let buffer = UnsafeBufferPointer<UInt8>(start: pointer, count: count)
        
        return [UInt8](buffer)
    }
    
    /// data: data that's needs to calculate CRC
    /// seed: previous CRC value that needs to add up this time
    func crc16ccitt(seed: UInt16 = 0xFFFF, final: UInt16 = 0xffff) -> UInt16 {
        let polynomial: UInt16 = 0x1021
        var crc = seed
        self.forEach { (byte) in
            crc ^= UInt16(byte) << 8
            (0..<8).forEach({ _ in
                crc = (crc & 0x8000) != 0 ? (crc << 1) ^ polynomial : crc << 1
            })
        }
        return crc & final
    }
}
