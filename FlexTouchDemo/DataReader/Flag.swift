//
//  Flag.swift
//  FlexTouchDemo
//
//  Created by Cindy Chen on 2022/9/27.
//

import Foundation

protocol Flag: RawRepresentable, CaseIterable where RawValue == Int {
    associatedtype IntegerType: UnsignedInteger
}

extension Flag {
    var bitIndex: Int {
        rawValue
    }
}

extension UnsignedInteger {
    func flags<FlagType: Flag>() -> [FlagType] {
        FlagType.allCases.filter { self[$0.bitIndex] }
    }
    
    subscript(index: Int) -> Bool {
        guard index < self.bitWidth else {
            fatalError("Index out of range!")
        }
        let bit: Self = 1
        let indexByte = bit << index
        let logicalValue = (self & indexByte) >> index
        return logicalValue != 0
    }
}
