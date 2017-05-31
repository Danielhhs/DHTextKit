//
//  NSParagraphStyle+DHText.h
//  DHTextKit
//
//  Created by Huang Hongsen on 17/5/31.
//  Copyright © 2017年 Huang Hongsen. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreText/CoreText.h>

@interface NSParagraphStyle (DHText)

+ (nullable NSParagraphStyle *) styleWithCTStyle:(nullable CTParagraphStyleRef)ctStyle;

- (nullable CTParagraphStyleRef) ctStyle CF_RETURNS_RETAINED;   //You have to release it your self

@end
