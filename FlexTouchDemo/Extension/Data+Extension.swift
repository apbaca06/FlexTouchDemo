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
}
