//
//  Crypto.swift
//  FlexTouchDemo
//
//  Created by Cindy Chen on 2022/9/26.
//

import Foundation
import CommonCrypto
import CryptoKit

extension AES.CBC {
    /// Advanced Cipher, provides incremental crypto operation (encryption/decryption) on data.
    public class Cipher {
        private var context: CCCryptorRef
        private var buffer = Data()
        
        /// Initialize new cipher instance that can operate on data to either encrypt or decrypt it.
        /// - Parameters:
        ///   - operation: the cryptografic operation
        ///   - key: a symmetric key for operation
        ///   - iv: initial vector data
        /// - Throws: when fails to create a cryptografic context
        public init(_ operation: Operation, using key: SymmetricKey, iv: Data, options: CCOptions = pkcs7Padding) throws {
            let keyData = key.dataRepresentation.bytes
            let ivData = iv.bytes
            var cryptorRef: CCCryptorRef?
            let status = CCCryptorCreateWithMode(operation.operation,
                                                 CCMode(kCCModeCBC),
                                                 CCAlgorithm(kCCAlgorithmAES),
                                                 options,
                                                 ivData.withUnsafeBytes{ $0.baseAddress },
                                                 keyData.withUnsafeBytes{ $0.baseAddress },
                                                 keyData.count,
                                                 nil,
                                                 0,
                                                 0,
                                                 CCModeOptions(kCCModeOptionCTR_BE),
                                                 &cryptorRef)
            guard status == CCCryptorStatus(kCCSuccess),
                  let cryptor = cryptorRef else {
                throw CBCError(message: "Could not create cryptor", status: status)
            }
            context = cryptor
//            let status = CCCryptorCreate(
//                operation.operation, CCAlgorithm(kCCAlgorithmAES), options,
//                keyData, keyData.count, ivData, &cryptorRef)
            
        }
        
        /// releases the crypto context
        deinit {
            CCCryptorRelease(context)
        }
        
        /// updates the cipher with data.
        ///
        /// - Parameter data: input data to process
        /// - Throws: an error when failing to process the data
        /// - Returns: processed data, after crypto operation (encryption/decryption)
        public func update(_ data: Data) throws -> Data {
            let outputLength = CCCryptorGetOutputLength(context, data.count, false)
            buffer.count = outputLength
            var dataOutMoved = 0
            
            let rawData = data.bytes
            let status = buffer.withUnsafeMutableBytes { bufferPtr in
                CCCryptorUpdate(context, rawData, rawData.count, bufferPtr.baseAddress!, outputLength, &dataOutMoved)
            }
            
            guard status == CCCryptorStatus(kCCSuccess) else {
                throw CBCError(message: "Could not update", status: status)
            }
            
            buffer.count = dataOutMoved
            return buffer
        }
        
        /// finalizing the crypto process on the internal buffer.
        ///
        /// after this call the internal buffer resets.
        /// - Throws: an error when failing to process the data
        /// - Returns: the remaining data to process. possible to be just the padding
        public func finalize() throws -> Data {
            let outputLength = CCCryptorGetOutputLength(context, 0, true)
            var dataOutMoved = 0
            
            let status = buffer.withUnsafeMutableBytes { bufferPtr in
                CCCryptorFinal(context, bufferPtr.baseAddress!, outputLength, &dataOutMoved)
            }
            
            guard status == CCCryptorStatus(kCCSuccess) else {
                throw CBCError(message: "Could not finalize", status: status)
            }
            
            buffer.count = dataOutMoved
            defer { buffer = Data() }
            return buffer
        }
    }
}

internal struct CBCError: LocalizedError {
    let message: String
    let status: Int32
    
    var errorDescription: String? {
        return "CBC Error: \"\(message)\", status: \(status)"
    }
}


public extension Data {
    var bytes: [UInt8] {
        [UInt8](self)
    }
}

public extension SymmetricKey {
    /// A Data instance created safely from the contiguous bytes without making any copies.
    var dataRepresentation: Data {
        return withUnsafeBytes { bytes in
            let cfdata = CFDataCreateWithBytesNoCopy(nil, bytes.baseAddress?.assumingMemoryBound(to: UInt8.self), bytes.count, kCFAllocatorNull)
            return (cfdata as Data?) ?? Data()
        }
    }
}
extension AES {
    /// The Advanced Encryption Standard (AES) Cipher Block Chaining (CBC) cipher suite.
    enum CBC {
        public static var pkcs7Padding: CCOptions { CCOptions(kCCOptionPKCS7Padding) }
        
        /// Encrypt data with AES-CBC algorithm
        /// - Parameters:
        ///   - data: the data to encrypt
        ///   - key: a symmetric key for encryption
        ///   - iv: initial vector data
        /// - Throws: when fails to encrypt
        /// - Returns: encrypted data
        public static func encrypt(_ data: Data, using key: SymmetricKey, iv: Data, options: CCOptions = pkcs7Padding) throws -> Data {
            try process(data, using: key, iv: iv, operation: .encrypt, options: options)
        }
        
        /// Decrypts encrypted data with AES-CBC algorithm
        /// - Parameters:
        ///   - data: encrypted data to decrypt
        ///   - key: a symmetric key for encryption
        ///   - iv: initial vector data
        /// - Throws: when fails to decrypt
        /// - Returns: clear text data after decryption
        public static func decrypt(_ data: Data, using key: SymmetricKey, iv: Data, options: CCOptions = pkcs7Padding) throws -> Data {
            try process(data, using: key, iv: iv, operation: .decrypt, options: options)
        }
        
        /// Process data, either encrypt or decrypt it
        private static func process(_ data: Data, using key: SymmetricKey, iv: Data, operation: Operation, options: CCOptions) throws -> Data {
            let inputBuffer = data.bytes
            let keyData = key.dataRepresentation.bytes
            let ivData = iv.bytes
            
            let bufferSize = inputBuffer.count + kCCBlockSizeAES128
            var outputBuffer = [UInt8](repeating: 0, count: bufferSize)
            var numBytesProcessed = 0
            
            let cryptStatus = CCCrypt(
                operation.operation, CCAlgorithm(kCCAlgorithmAES), options, //params
                keyData, keyData.count, ivData, inputBuffer, inputBuffer.count, //input data
                &outputBuffer, bufferSize, &numBytesProcessed //output data
            )
            
            guard cryptStatus == CCCryptorStatus(kCCSuccess) else {
                throw CBCError(message: "Operation Failed", status: cryptStatus)
            }
            
            outputBuffer.removeSubrange(numBytesProcessed..<outputBuffer.count) //trim extra padding
            return Data(outputBuffer)
        }
        
        public enum Operation {
            case encrypt
            case decrypt
            
            internal var operation: CCOperation {
                CCOperation(self == .encrypt ? kCCEncrypt : kCCDecrypt)
            }
        }
    }
}

func encrypt(key: Data,
             initializationVector: Data, dataIn: Data) -> Data? {
    do {
        let cipher = try AES.CBC.Cipher(.encrypt, using: SymmetricKey(data: key), iv: initializationVector)
        let encrypted = try cipher.update(dataIn)
        return encrypted
    } catch {
        print(error)
        return nil
    }
}

func decrypt(key: Data,
             initializationVector: Data, dataIn: Data) -> Data? {
    do {
        let cipher = try AES.CBC.Cipher(.decrypt, using: SymmetricKey(data: key), iv: initializationVector)
        
        let decrypted = try cipher.update(dataIn)
        return decrypted
    } catch {
        print(error)
        return nil
    }
}
    


//func crypt(operation: Int, algorithm: Int, options: Int, key: Data,
//        initializationVector: Data, dataIn: Data) -> Data? {
//    return key.withUnsafeBytes { keyUnsafeRawBufferPointer in
//        return dataIn.withUnsafeBytes { dataInUnsafeRawBufferPointer in
//            return initializationVector.withUnsafeBytes { ivUnsafeRawBufferPointer in
//                // Give the data out some breathing room for PKCS7's padding.
//                let dataOutSize: Int = dataIn.count + kCCBlockSizeAES128 + initializationVector.count
//                let dataOut = UnsafeMutableRawPointer.allocate(byteCount: dataOutSize,
//                    alignment: 1)
//                defer { dataOut.deallocate() }
//                var dataOutMoved: Int = 0
//                let status = CCCrypt(CCOperation(operation), CCAlgorithm(algorithm),
//                    CCOptions(options),
//                    keyUnsafeRawBufferPointer.baseAddress, key.count,
//                    ivUnsafeRawBufferPointer.baseAddress,
//                    dataInUnsafeRawBufferPointer.baseAddress, dataIn.count,
//                    dataOut, dataOutSize, &dataOutMoved)
//                guard status == kCCSuccess else {
//                    print(status)
//                    return nil
//                }
//                return Data(bytes: dataOut, count: dataOutMoved)
//            }
//        }
//    }
//}
//
//func randomGenerateBytes(count: Int) -> Data? {
//    let bytes = UnsafeMutableRawPointer.allocate(byteCount: count, alignment: 1)
//    defer { bytes.deallocate() }
//    let status = CCRandomGenerateBytes(bytes, count)
//    guard status == kCCSuccess else { return nil }
//    return Data(bytes: bytes, count: count)
//}
//
//extension Data {
//    /// Encrypts for you with all the good options turned on: CBC, an IV, PKCS7
//    /// padding (so your input data doesn't have to be any particular length).
//    /// Key can be 128, 192, or 256 bits.
//    /// Generates a fresh IV for you each time, and prefixes it to the
//    /// returned ciphertext.
//    func encryptAES256_CBC_PKCS7_IV(key: Data, iv: Data) -> Data? {
////        guard let iv = randomGenerateBytes(count: kCCBlockSizeAES128) else { return nil }
//        // No option is needed for CBC, it is on by default.
//        guard let ciphertext = crypt(operation: kCCEncrypt,
//                                    algorithm: kCCAlgorithmAES,
//                                    options: kCCOptionPKCS7Padding,
//                                    key: key,
//                                    initializationVector: iv,
//                                    dataIn: self) else { return nil }
//        return iv + ciphertext
//    }
//
//    /// Decrypts self, where self is the IV then the ciphertext.
//    /// Key can be 128/192/256 bits.
//    func decryptAES256_CBC_PKCS7_IV(key: Data) -> Data? {
//        guard count > kCCBlockSizeAES128 else { return nil }
//        let iv = prefix(kCCBlockSizeAES128)
//        let ciphertext = suffix(from: kCCBlockSizeAES128)
//        return crypt(operation: kCCDecrypt, algorithm: kCCAlgorithmAES,
//            options: kCCOptionPKCS7Padding, key: key, initializationVector: iv,
//            dataIn: ciphertext)
//    }
//}
