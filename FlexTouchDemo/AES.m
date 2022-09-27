//
//  AES.m
//  FlexTouchDemo
//
//  Created by Cindy Chen on 2022/9/27.
//

#import <Foundation/Foundation.h>
#import <CommonCrypto/CommonCrypto.h>
#import "AES.h"

@implementation AesForBioCorp

- (NSMutableData *)doAESForMallya:(NSData *)dataIn keyIV:(NSData *)keyIV keyEK:(NSData *)keyEK context:(CCOperation)kCCEncrypt_or_kCCDecrypt error:(NSError **)error {
    
    CCCryptorStatus ccStatus   = kCCSuccess;
    size_t          cryptBytes = 0;
    UInt16 cmdLen = dataIn.length;
    
    // Test
    //NSMutableData *dataOut = [NSMutableData dataWithLength:cmdLen];//+ kCCBlockSizeAES128];
    NSMutableData *dataOut = [NSMutableData dataWithLength:cmdLen + kCCBlockSizeAES128];
    
    //NSData *iv = [NSData dataWithBytes:keyIV_BioCorp length:16];
    //NSData *key = [NSData dataWithBytes:keyEK_BioCorp length:16];
    
#if 0
    NSData *keyIVx = [[BioCorp sharedInstance] mallyaKeyIV];
    NSData *keyEKx = [[BioCorp sharedInstance] mallyaKeyEk];
    
    NSLog(@"=== (doAES For Mallya) IVXX == %@", keyIVx);
    NSLog(@"=== (doAES For Mallya) EKXX == %@", keyEKx);
#else
    NSLog(@"=== (doAES For Mallya) IV(LIB) == %@", keyIV);
    NSLog(@"=== (doAES For Mallya) EK(LIB) == %@", keyEK);
#endif
    
    
    /// ==========  Cryptor Create With Mode ==========
    CCCryptorRef cryptor = nil;
    ccStatus = CCCryptorCreateWithMode(
                                       //kCCEncrypt, kCCModeCBC, kCCAlgorithmAES, ccNoPadding,
                                       kCCEncrypt_or_kCCDecrypt, kCCModeCBC, kCCAlgorithmAES, ccPKCS7Padding,
                                       
                                       keyIV.bytes,
                                       keyEK.bytes, keyEK.length,
                                       nil, 0, 0,
                                       kCCModeOptionCTR_BE,
                                       &cryptor
                                       );
    
    if (ccStatus != kCCSuccess) {
        *error = [NSError errorWithDomain:@"kEncryptionError"
                                     code:ccStatus
                                 userInfo:nil];
        return nil;
    }
    NSLog(@"====== CCCryptorCreateWithMode ======");
    NSLog(@"==== Create Mode == %d and %d aa", (int)cryptBytes, (int)cryptBytes);
    
    /// ========== Cryptor Update ==========
    size_t written = 0;
    ccStatus = CCCryptorUpdate(
                               cryptor,
                               dataIn.bytes, dataIn.length,
                               dataOut.mutableBytes, dataOut.length,
                               &written
                               );
    
    NSLog(@"==== Update Status %d ====", (SInt16)ccStatus);
    NSLog(@"(BIO) Update, written = %d", (int)written);
    NSLog(@"(BIO)Update, dataOut = %@", dataOut);
    
    if (ccStatus != kCCSuccess) {
        *error = [NSError errorWithDomain:@"kEncryptionError"
                                     code:ccStatus
                                 userInfo:nil];
        return nil;
    }
    
    /// ==========  Cryptor Final ==========
    size_t writtenF = 0;
    ccStatus = CCCryptorFinal(
                              cryptor,
                              //output.mutableBytes + written, output.length - written,
                              dataOut.mutableBytes + written, dataOut.length - written,
                              &writtenF);
    
    /// ==========  Cryptor Release ==========
    CCCryptorRelease(cryptor);
    dataOut.length = written + writtenF;
    
    NSLog(@"(Final) Actual: %d bytes", (int)dataOut.length);
    NSLog(@"==== FINAL cryptBytes(dataOut) ????? == %@", dataOut);
    
    if (ccStatus != kCCSuccess) {
        *error = [NSError errorWithDomain:@"kEncryptionError"
                                     code:ccStatus
                                 userInfo:nil];
        dataOut = nil;
        return nil;
    }
    
    //dataOut.length = cryptBytes;
    NSLog(@"==== FINAL cryptBytes(dataOut) == %@", dataOut);
    //NSLog(@"==== FINAL cryptBytes length == %d and %d ", (int)cryptBytes, (SInt32)cryptBytes);
    return dataOut;
}

@end
