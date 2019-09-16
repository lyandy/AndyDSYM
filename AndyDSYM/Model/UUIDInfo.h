//
//  UUIDInfo.h
//  DSYMTools
//
//  Created by Andy on 9/16/19.
//  Copyright © 2019 Andy. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface UUIDInfo : NSObject

/**
 *  arch 类型
 */
@property (nonatomic, copy) NSString *arch;

/**
 * 默认的 __PAGEZERO 地址
 */
@property (nonatomic, copy, readonly) NSString *defaultSlideAddress;

/**
 地址偏移
 */
@property (nonatomic, copy) NSString *baseAddress;

/**
 *  uuid 值
 */
@property (nonatomic, copy) NSString *uuid;

/**
 *  可执行文件路径
 */
@property (nonatomic, copy) NSString *executableFilePath;

@end
