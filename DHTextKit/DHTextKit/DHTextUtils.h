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
@end
