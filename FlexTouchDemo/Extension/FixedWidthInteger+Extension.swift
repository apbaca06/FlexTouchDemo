//
//  FixedWidthInteger+Extension.swift
//  FlexTouchDemo
//
//  Created by Cindy Chen on 2022/9/27.
//

import Foundation

extension FixedWidthInteger {
    var data: Data {
        let data = withUnsafeBytes(of: self) { Data($0) }
        return data
    }
    
    /// iOS platform is default with little endian
    var bytes: [UInt8] {
        [UInt8](withUnsafeBytes(of: self) { Data($0) })
    }
    
    var bigEndianBytes: [UInt8] {
        [UInt8](withUnsafeBytes(of: self.bigEndian) { Data($0) })
    }
    
    var littleEndianBytes: [UInt8] {
        [UInt8](withUnsafeBytes(of: self.littleEndian) { Data($0) })
    }
}
