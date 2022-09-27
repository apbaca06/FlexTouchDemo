//
//  AES.h
//  FlexTouchDemo
//
//  Created by Cindy Chen on 2022/9/27.
//

#import <Foundation/Foundation.h>
#import <CommonCrypto/CommonCrypto.h>

@interface AesForBioCorp : NSObject

- (NSMutableData *)doAESForMallya:(NSData *)dataIn keyIV:(NSData *)keyIV keyEK:(NSData *)keyEK context:(CCOperation)kCCEncrypt_or_kCCDecrypt error:(NSError **)error;


@end
