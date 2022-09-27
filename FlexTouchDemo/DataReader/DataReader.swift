//
//  DataReader.swift
//  FlexTouchDemo
//
//  Created by Cindy Chen on 2022/9/22.
//

import Foundation

class DataReader {
    let data: Data
    private var cursor: Int = 0
    init(_ data: Data) {
        self.data = data
    }
    
    func readNext<T>() -> T {
        // Get the number of bytes occupied by the type T
        let chunkSize = MemoryLayout<T>.size
        // Get the bytes that contain next value
        let nextDataChunk = Data(data[cursor..<cursor+chunkSize])
        // Read the actual value from the data chunk
        let value = nextDataChunk.withUnsafeBytes { bufferPointer in
            bufferPointer.load(fromByteOffset: 0, as: T.self)
        }
        // Move the cursor to the next position
        cursor += chunkSize
        // Return the value that we just read
        return value
    }
    
    func readArrayWithSize<T: Collection>(chunkSize: Int) -> T {
        // Read the actual value from the data chunk
        let result = (0..<chunkSize).map { _ -> T.Element in
            let nextDataChunk = Data(data[cursor..<cursor+1])
            let value = nextDataChunk.withUnsafeBytes { bufferPointer in
                bufferPointer.load(fromByteOffset: 0, as: T.Element.self)
            }
            cursor += 1
            return value
        }
        return result as! T
    }
}
