//
//  FileHashUtil.m
//  FileHashT
//
//  Created by 刘杰 on 2018/9/29.
//  Copyright © 2018年 jerry. All rights reserved.
//

#import "FileHashUtil.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <CommonCrypto/CommonDigest.h>

#define HashComputationContextInitialize(context, algorithmName) \
CC_##algorithmName##_CTX hashObj; \
context.initFunction = (HashInitFunction)CC_##algorithmName##_Init; \
context.updateFunction = (HashUpdateFunction)CC_##algorithmName##_Update; \
context.finalFunction = (HashFinalFunction)CC_##algorithmName##_Final; \
context.hashObj = (void *)&hashObj; \
context.digestLength = CC_##algorithmName##_DIGEST_LENGTH;

typedef int (*HashInitFunction)   (void * hashObj);
typedef int (*HashUpdateFunction) (void * hashObj, const void *data, CC_LONG len);
typedef int (*HashFinalFunction)  (unsigned char * value, void *hashObj);
typedef struct _FileHashComputationContext {
    HashInitFunction initFunction;
    HashUpdateFunction updateFunction;
    HashFinalFunction finalFunction;
    size_t digestLength;
    void * hashObj;
} FileHashComputationContext;

@interface NSData(Hash)
- (NSString *)hexString;
@end

@implementation NSData(Hash)
- (NSString *)hexString {
    NSUInteger length = self.length;
    NSMutableString *result = [NSMutableString stringWithCapacity:length * 2];
    const unsigned char *byte = self.bytes;
    for (int i = 0; i < length; i++, byte++) {
        [result appendFormat:@"%02X", *byte];
    }
    return result;
}
@end

@implementation FileHashUtil
+ (NSString *)hashOfFileAtPath:(NSString *)filePath algorithm:(HashAlgorithm)algorithm{
    return [[FileHashUtil hashOfFileAtPath:filePath file: nil offset: 0 length: 0  algorithm:algorithm] hexString];
}
+ (NSString *)hashOfFileAtPath:(NSString *)filePath algorithm:(HashAlgorithm)algorithm offset:(UInt64)offset length:(UInt64)length{
    return [[FileHashUtil hashOfFileAtPath:filePath file: nil offset: offset length: length algorithm:algorithm] hexString];
}
+ (NSString *)hashOfFileWith:(FILE *)file algorithm:(HashAlgorithm)algorithm{
    return [[FileHashUtil hashOfFileAtPath: nil file: file offset: 0 length: 0  algorithm:algorithm] hexString];
}
+ (NSString *)hashOfFileWith:(FILE *)file algorithm:(HashAlgorithm)algorithm offset:(UInt64)offset length:(UInt64)length{
    return [[FileHashUtil hashOfFileAtPath: nil file: file offset: offset length: length  algorithm:algorithm] hexString];
}

+ (NSData *)hashDataOfFileAtPath:(NSString *)filePath algorithm:(HashAlgorithm)algorithm{
    return [FileHashUtil hashOfFileAtPath:filePath file: nil offset: 0 length: 0  algorithm:algorithm];
}
+ (NSData *)hashDataOfFileAtPath:(NSString *)filePath algorithm:(HashAlgorithm)algorithm offset:(UInt64)offset length:(UInt64)length{
    return [FileHashUtil hashOfFileAtPath:filePath file: nil offset: offset length: length algorithm:algorithm];
}
+ (NSData *)hashDataOfFileWith:(FILE *)file algorithm:(HashAlgorithm)algorithm{
    return [FileHashUtil hashOfFileAtPath: nil file: file offset: 0 length: 0  algorithm:algorithm];
}
+ (NSData *)hashDataOfFileWith:(FILE *)file algorithm:(HashAlgorithm)algorithm offset:(UInt64)offset length:(UInt64)length{
    return [FileHashUtil hashOfFileAtPath: nil file: file offset: offset length: length  algorithm:algorithm];
}

/*
 计算过程有两个地方比较耗时：读文件、计算hash， 主要耗时是在计算hash上。
 各种方式读文件的性能： (fread ≈≈ CFStream) > NSFileHandle。（注: CFSream 不能 seek，所以此处使用了 fread）
 */
+ (NSData *)hashOfFileAtPath:(NSString *)filePath file:(FILE *)file offset:(UInt64)offset length:(UInt64)length algorithm:(HashAlgorithm)algorithm{
    size_t BUFFER_SIZE = 1024 * 8;
    FileHashComputationContext context;
    switch (algorithm) {
        case HashAlgorithmMD5:{
            HashComputationContextInitialize(context, MD5)
            break;
        }
        case HashAlgorithmSHA1:{
            HashComputationContextInitialize(context, SHA1)
            break;
        }
        case HashAlgorithmSHA256:{
            HashComputationContextInitialize(context, SHA256)
            break;
        }
        case HashAlgorithmSHA512:{
            HashComputationContextInitialize(context, SHA512)
            break;
        }
    }
    context.initFunction(context.hashObj);
    
    FILE * fp = file;
    if(fp == nil){
        fp = fopen([filePath UTF8String], "rb");
    }
    
    if(fp == nil){
        return nil;
    }
    
    if(offset > 0){
        fseek(fp, offset, SEEK_SET);
    }
    size_t maxReadLen = 0;
    if(length > 0){
        maxReadLen = length;
    }
    
    size_t didReadedLen = 0;
    BOOL isReadSuc = YES;
    char buf[BUFFER_SIZE];
    while(YES){
        size_t toReadLen = BUFFER_SIZE;
        if(maxReadLen > 0){
            if(toReadLen + didReadedLen > maxReadLen){
                toReadLen = maxReadLen - didReadedLen;
            }
        }
        //读取结束
        if(toReadLen == 0){
            break;
        }
        
        size_t readLen = fread(buf, sizeof(char), toReadLen, fp);
        if(ferror(fp)){
            isReadSuc = NO;
            break;
        }
        context.updateFunction(context.hashObj, buf, (CC_LONG) readLen);
        //读取结束
        if(feof(fp)){
            break;
        }
        didReadedLen += readLen;
    }
    
    unsigned char hashValue[context.digestLength];
    context.finalFunction(hashValue, context.hashObj);
    //如果是外部传入的 file，则不 close
    if(file == nil){
        fclose(fp);
    }
    
    if(!isReadSuc){
        return nil;
    }
    return [[NSData alloc]initWithBytes:hashValue length:context.digestLength];
}


@end



