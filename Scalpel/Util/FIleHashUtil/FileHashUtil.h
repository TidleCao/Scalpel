//
//  FileHashUtil.h
//  FileHashT
//
//  Created by 刘杰 on 2018/9/29.
//  Copyright © 2018年 jerry. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(int,HashAlgorithm) {
    HashAlgorithmMD5,
    HashAlgorithmSHA1,
    HashAlgorithmSHA256,
    HashAlgorithmSHA512
};
@interface FileHashUtil : NSObject

/**
 计算文件 hash
 @param filePath 文件路径
 @param algorithm 要使用的hash算法
 @return 文件的hash值
 */
+ (NSString *)hashOfFileAtPath:(NSString *)filePath algorithm:(HashAlgorithm)algorithm;
/**
 计算文件 hash
 @param filePath 文件路径
 @param algorithm 要使用的hash算法
 @param offset 文件读取的起始位置
 @param length 读取长度, 0 表示读取所有。
 @return 文件的hash值
 */
+ (NSString *)hashOfFileAtPath:(NSString *)filePath algorithm:(HashAlgorithm)algorithm offset:(UInt64)offset length:(UInt64)length;
/**
 计算文件 hash
 @param file 文件句柄，如果传了该参数，则会忽略 filePath，如果外部有频繁调用需求，可以通过传递 file 参数以避免频繁的 fopen 导致的性能问题。
 @param algorithm 要使用的hash算法
 @return 文件的hash值
 */
+ (NSString *)hashOfFileWith:(FILE *)file algorithm:(HashAlgorithm)algorithm;
/**
 计算文件 hash
 @param file 文件句柄，如果传了该参数，则会忽略 filePath，如果外部有频繁调用需求，可以通过传递 file 参数以避免频繁的 fopen 导致的性能问题。
 @param algorithm 要使用的hash算法
 @param offset 文件读取的起始位置
 @param length 读取长度, 0 表示读取所有。
 @return 文件的hash值
 */
+ (NSString *)hashOfFileWith:(FILE *)file algorithm:(HashAlgorithm)algorithm offset:(UInt64)offset length:(UInt64)length;

+ (NSData *)hashDataOfFileAtPath:(NSString *)filePath algorithm:(HashAlgorithm)algorithm;
+ (NSData *)hashDataOfFileAtPath:(NSString *)filePath algorithm:(HashAlgorithm)algorithm offset:(UInt64)offset length:(UInt64)length;
+ (NSData *)hashDataOfFileWith:(FILE *)file algorithm:(HashAlgorithm)algorithm;
+ (NSData *)hashDataOfFileWith:(FILE *)file algorithm:(HashAlgorithm)algorithm offset:(UInt64)offset length:(UInt64)length;
@end
