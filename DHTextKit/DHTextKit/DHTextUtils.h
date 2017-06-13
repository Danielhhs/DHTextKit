//
//  DTTextUtils.h
//  DHTextKit
//
//  Created by Huang Hongsen on 17/5/26.
//  Copyright © 2017年 Huang Hongsen. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreText/CoreText.h>
#import "DHTextAttribute.h"

#ifndef DH_SWAP // swap two value
#define DH_SWAP(_a_, _b_)  do { __typeof__(_a_) _tmp_ = (_a_); (_a_) = (_b_); (_b_) = _tmp_; } while (0)
#endif

@interface DHTextUtils : NSObject

+ (NSRange) NSRangeFromCFRange:(CFRange)cfRange;
+ (CFRange) CFRangeFromNSRange:(NSRange)nsRange;

+ (NSRange) emptyNSRange;
+ (CFRange) emptyCFRange;

+ (CTLineTruncationType) ctLineTruncationTypeFromDHTurncationType:(DHTextTruncationType)dhTruncationType;
+ (DHTextTruncationType) dhTruncationTypeFromCTLineTruncationType:(CTLineTruncationType)ctTruncationType;

+ (UIColor *) defaultColor;

+ (CGFloat) CGFloatPixelRound:(CGFloat)number;
+ (CGFloat) CGFloatPixelFloor:(CGFloat)number;

+ (CGFloat) screenScale;
+ (CGFloat) CGFloatToPixel:(CGFloat)number;
+ (CGFloat) CGFloatPixelHalf:(CGFloat)number;

+ (CGRect) mergeRect:(CGRect)rect1 withRect:(CGRect)rect2 isVertical:(BOOL) isVertical;

+ (BOOL) isLineBreakString:(NSString *)string;
+ (BOOL) isLineBreakChar:(unichar)c;

+ (NSInteger) lineBreakTailLength:(NSString *) str;
@end
