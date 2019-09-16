//
//  ArchiveInfo.h
//  DSYMTools
//
//  Created by Andy on 9/16/19.
//  Copyright © 2019 Andy. All rights reserved.
//

#import <Foundation/Foundation.h>

@class UUIDInfo;

@interface DSYMInfo : NSObject

/**
 *  dSYM 路径
 */
@property (nonatomic, copy) NSString *dSYMFilePath;

/**
 * dSYM 文件名
 */
@property (nonatomic, copy) NSString *dSYMFileName;

/**
 * uuids
 */
@property (nonatomic, strong) NSArray<UUIDInfo *> *uuidInfos;

@end
