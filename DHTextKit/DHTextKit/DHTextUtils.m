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

+ (CTLineTruncationType) ctLineTruncationTypeFromDHTurncationType:(DHTextTruncationType)dhTruncationType
{
    switch (dhTruncationType) {
        case DHTextTruncationTypeStart:
            return kCTLineTruncationStart;
        case DHTextTruncationTypeEnd:
            return kCTLineTruncationEnd;
        case DHTextTruncationTypeMiddle:
            return kCTLineTruncationMiddle;
        default:
            return kCTLineTruncationStart;
    }
}

+ (DHTextTruncationType) dhTruncationTypeFromCTLineTruncationType:(CTLineTruncationType)ctTruncationType
{
    switch (ctTruncationType) {
        case kCTLineTruncationStart:
            return DHTextTruncationTypeStart;
        case kCTLineTruncationMiddle:
            return DHTextTruncationTypeMiddle;
        case kCTLineTruncationEnd:
            return DHTextTruncationTypeEnd;
    }
}

+ (UIColor *) defaultColor
{
    return [UIColor blackColor];
}

+ (CGFloat) screenScale
{
    static CGFloat screenScale;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        screenScale = [UIScreen mainScreen].scale;
    });
    return screenScale;
}

+ (CGFloat) CGFloatPixelFloor:(CGFloat)number
{
    CGFloat scale = [DHTextUtils screenScale];
    return (floor(number * scale)) / scale;
}

+ (CGFloat) CGFloatPixelRound:(CGFloat)number
{
    CGFloat scale = [DHTextUtils screenScale];
    return (round(number * scale)) / scale;
}

+ (CGFloat) CGFloatToPixel:(CGFloat)number
{
    CGFloat scale = [DHTextUtils screenScale];
    return number * scale;
}

+ (CGFloat) CGFloatPixelHalf:(CGFloat)number
{
    CGFloat scale = [DHTextUtils screenScale];
    return (floor(number * scale) + 0.5) / scale;
}

+ (CGRect) mergeRect:(CGRect)rect1 withRect:(CGRect)rect2 isVertical:(BOOL)isVertical
{
    if (isVertical) {
        CGFloat top = MIN(rect1.origin.y, rect2.origin.y);
        CGFloat bottom = MAX(rect1.origin.y + rect1.size.height, rect2.origin.y + rect2.size.height);
        CGFloat width = MAX(rect1.size.width, rect2.size.width);
        return CGRectMake(rect1.origin.x, top, width, bottom - top);
    } else {
        CGFloat left = MIN(rect1.origin.x, rect2.origin.x);
        CGFloat right = MAX(rect1.origin.x + rect1.size.width, rect2.origin.x + rect2.size.width);
        CGFloat height = MAX(rect1.size.height, rect2.size.height);
        return CGRectMake(left, rect1.origin.y, right - left, height);
    }
}

+ (BOOL) isLineBreakString:(NSString *)str
{
    if (str.length > 2 || str.length == 0) return NO;
    if (str.length == 1) {
        unichar c = [str characterAtIndex:0];
        return [DHTextUtils isLineBreakChar:c];
    } else {
        return ([str characterAtIndex:0] == '\r') && ([str characterAtIndex:1] == '\n');
    }
}

+ (BOOL) isLineBreakChar:(unichar)c {
    switch (c) {
        case 0x000D:
        case 0x2028:
        case 0x000A:
        case 0x2029:
            return YES;
        default:
            return NO;
    }
}

+ (NSInteger) lineBreakTailLength:(NSString *)str
{
    if ([str length] >= 2) {
        unichar c2 = [str characterAtIndex:[str length] - 1];
        if ([DHTextUtils isLineBreakChar:c2]) {
            unichar c1 = [str characterAtIndex:[str length] - 2];
            if (c1 == '\r' && c2 == '\n') return 2;
            else return 1;
        } else {
            return 0;
        }
    } else if ([str length] == 1) {
        return [DHTextUtils isLineBreakChar:[str characterAtIndex:0]] ? 1 : 0;
    } else {
        return 0;
    }
}

@end
