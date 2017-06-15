//
//  DHTextHighlight.h
//  DHTextKit
//
//  Created by Huang Hongsen on 17/6/13.
//  Copyright © 2017年 Huang Hongsen. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DHTextShadow.h"
#import "DHTextDecoration.h"
#import "DHTextBorder.h"
#import "DHTextAttachment.h"

@interface DHTextHighlight : NSObject<NSCoding, NSCopying>

@property (nonnull, strong, nonatomic) NSDictionary *attributes;

@property (nonatomic, nullable, strong) DHTextAction tapAction;
@property (nonatomic, nullable, strong) DHTextAction longPressAction;
@property (nonatomic, nullable, strong) NSDictionary *userInfo;

+ (nullable instancetype) highlightWithAttributes:(nullable NSDictionary *)attributes;
+ (nullable instancetype) highlightWithBackgroundColor:(nullable UIColor *)color;

- (void) setFont:(nullable UIFont *)font;
- (void) setColor:(nullable UIColor *)color;
- (void) setStrokeWidth:(nullable NSNumber *)strokeWidth;
- (void) setStrokeColor:(nullable UIColor *)strokeColor;
- (void) setShadow:(nullable DHTextShadow *)shadow;
- (void) setInnerShadow:(nullable DHTextShadow *)innerShadow;
- (void) setUnderline:(nullable DHTextDecoration *)underline;
- (void) setStrikeThrough:(nullable DHTextDecoration *)strikeThrough;
- (void) setBackgroundBorder:(nullable DHTextBorder *)backgroundBorder;
- (void) setBorder:(nullable DHTextBorder *)border;
- (void) setAttachment:(nullable DHTextAttachment *)attachment;
@end
