//
//  DTTextUtils.m
//  DHTextKit
//
//  Created by Huang Hongsen on 17/5/26.
//  Copyright © 2017年 Huang Hongsen. All rights reserved.
//

#import "DHTextUtils.h"

@implementation DHTextUtils

+ (NSRange) NSRangeFromCFRange:(CFRange)cfRange
{
    return NSMakeRange(cfRange.location, cfRange.length);
}

+ (CFRange) CFRangeFromNSRange:(NSRange)nsRange
{
    return CFRangeMake(nsRange.location, nsRange.length);
}

+ (CFRange) emptyCFRange
{
    return CFRangeMake(0, 0);
}

+ (NSRange) emptyNSRange
{
    return NSMakeRange(0, 0);
}

@end
