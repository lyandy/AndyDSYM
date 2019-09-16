//
//  UUIDInfo.m
//  DSYMTools
//
//  Created by Andy on 9/16/19.
//  Copyright © 2019 Andy. All rights reserved.
//

#import "UUIDInfo.h"

@interface UUIDInfo()

/**
 * 默认的 Slide Address
 */
@property (nonatomic, readwrite) NSString *defaultSlideAddress;

@end

@implementation UUIDInfo

- (void)setArch:(NSString *)arch
{
    _arch = arch;
    if ([arch isEqualToString:@"arm64"] || [arch isEqualToString:@"x86_64"])
    {
        _defaultSlideAddress = @"0x0000000100000000";
    }
    else if ([arch isEqualToString:@"armv7"])
    {
        _defaultSlideAddress = @"0x00004000";
    }
    else
    {
        _defaultSlideAddress = @"";
    }
}

@end
