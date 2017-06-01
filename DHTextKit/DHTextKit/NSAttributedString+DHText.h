//
//  NSAttributedString+DHText.h
//  DHTextKit
//
//  Created by Huang Hongsen on 17/5/25.
//  Copyright © 2017年 Huang Hongsen. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <CoreText/CoreText.h>
#import "DHTextAttribute.h"
#import "DHTextShadow.h"
#import "DHTextAttachment.h"
#import "DHTextBorder.h"

@interface NSAttributedString (DHText)

+ (nullable NSAttributedString *) dh_attachmentStringWithContent:(nullable id)content
                                                     contentMode:(UIViewContentMode)contentMode
                                                  attachmentSize:(CGSize)size
                                                     alignToFont:(nullable UIFont *)font
                                               verticalAlignment:(DHTextVerticalAlignment)verticalAlignment;

+ (nullable NSAttributedString *) dh_attachmentStringWithContent:(nullable id)content
                                                     contentMode:(UIViewContentMode)contentMode
                                                           width:(CGFloat)width
                                                          ascent:(CGFloat)ascent
                                                         descent:(CGFloat)decent;

@end

@interface NSMutableAttributedString (DHText)

#pragma mark - Set Attributes
- (void) setAttributes:(nullable NSDictionary<NSString *, id> *)attributes;
- (void) setAttribute:(nonnull NSString *)attribute value:(nullable id) value;
- (void) setAttribute:(nonnull NSString *)attribute value:(nullable id) value range:(NSRange)range;
- (void) removeAttributesInRange:(NSRange)range;

- (void) setFont:(nullable UIFont *)font;
- (void) setKern:(nullable NSNumber *)kern;
- (void) setColor:(nullable UIColor *)color;
- (void) setBackgroundColor:(nullable UIColor *)backgroundColor;
- (void) setStrokeWidth:(nullable NSNumber *)strokeWidth;
- (void) setStrokeColor:(nullable UIColor *)strokeColor;
- (void) setShadow:(nullable NSShadow *)shadow;
- (void) setInnerShadow:(nullable DHTextShadow *)innerShadow;
- (void) setParagraphStyle:(nullable NSParagraphStyle *) paragraphStyle;
- (void) setAliegnment:(NSTextAlignment)alignment;
- (void) setLineBreakMode:(NSLineBreakMode)lineBreakMode;
- (void) setLineSpacing:(CGFloat)lineSpacing;
- (void) setParagraphSpacing:(CGFloat)paragraphSpacing;
- (void) setRunDelegate:(nullable CTRunDelegateRef)runDelegate;
- (void) setAttachment:(nullable NSTextAttachment *)attachment;
- (void) setTextAttachment:(nullable DHTextAttachment *)textAttachment;
- (void) setBackgroundBorder:(nullable DHTextBorder *)border;

- (void) setFont:(nullable UIFont *)font forRange:(NSRange)range;
- (void) setKern:(nullable NSNumber *)kern forRange:(NSRange)range;
- (void) setColor:(nullable UIColor *)color forRange:(NSRange)range;
- (void) setBackgroundColor:(nullable UIColor *)backgroundColor forRange:(NSRange)range;
- (void) setStrokeWidth:(nullable NSNumber *)strokeWidth forRange:(NSRange)range;
- (void) setStrokeColor:(nullable UIColor *)strokeColor forRange:(NSRange)range;
- (void) setShadow:(nullable NSShadow *)shadow forRange:(NSRange)range;
- (void) setInnerShadow:(nullable DHTextShadow *)innerShadow forRange:(NSRange)range;
- (void) setParagraphStyle:(nullable NSParagraphStyle *) paragraphStyle forRange:(NSRange)range;
- (void) setAliegnment:(NSTextAlignment)alignment forRange:(NSRange)range;
- (void) setLineBreakMode:(NSLineBreakMode)lineBreakMode forRange:(NSRange)range;
- (void) setLineSpacing:(CGFloat)lineSpacing forRange:(NSRange)range;
- (void) setParagraphSpacing:(CGFloat)paragraphSpacing forRange:(NSRange)range;
- (void) setRunDelegate:(nullable CTRunDelegateRef)runDelegate forRange:(NSRange)range;
- (void) setAttachment:(nullable NSTextAttachment *)attachment forRange:(NSRange)range;
- (void) setTextAttachment:(nullable DHTextAttachment *)textAttachment forRange:(NSRange)range;
- (void) setBackgroundBorder:(nullable DHTextBorder *)border forRange:(NSRange)range;

@end
