//
//  NSAttributedString+DHText.m
//  DHTextKit
//
//  Created by Huang Hongsen on 17/5/25.
//  Copyright © 2017年 Huang Hongsen. All rights reserved.
//

#import "NSAttributedString+DHText.h"
#import "DHTextAttachment.h"
#import "DHTextRunDelegate.h"
#import "NSParagraphStyle+DHText.h"

@implementation NSAttributedString (DHText)
+ (NSAttributedString *) dh_attachmentStringWithContent:(id)content
                                            contentMode:(UIViewContentMode)contentMode
                                                  width:(CGFloat)width
                                                 ascent:(CGFloat)ascent
                                                descent:(CGFloat)decent
{
    NSMutableAttributedString *attrStr = [[NSMutableAttributedString alloc] initWithString:DHTextAttachmentToken];
    DHTextAttachment *attachment = [[DHTextAttachment alloc] init];
    attachment.content = content;
    attachment.contentMode = contentMode;
    [attrStr setTextAttachment:attachment forRange:NSMakeRange(0, [attrStr length])];
    
    DHTextRunDelegate *runDelegate = [[DHTextRunDelegate alloc] init];
    runDelegate.width = width;
    runDelegate.ascent = ascent;
    runDelegate.descent = decent;
    [attrStr setRunDelegate:runDelegate.CTRunDelegate forRange:NSMakeRange(0, [attrStr length])];
    return attrStr;
}

+ (NSAttributedString *) dh_attachmentStringWithContent:(id)content
                                            contentMode:(UIViewContentMode)contentMode
                                         attachmentSize:(CGSize)size
                                            alignToFont:(UIFont *)font
                                      verticalAlignment:(DHTextVerticalAlignment)verticalAlignment
{
    NSMutableAttributedString *attrStr = [[NSMutableAttributedString alloc] initWithString:DHTextAttachmentToken];
    
    DHTextAttachment *attachment = [[DHTextAttachment alloc] init];
    attachment.content = content;
    attachment.contentMode = contentMode;
    [attrStr setTextAttachment:attachment forRange:NSMakeRange(0, [attrStr length])];
    
    DHTextRunDelegate *runDelegate = [[DHTextRunDelegate alloc] init];
    runDelegate.width = size.width;
    switch (verticalAlignment) {
        case DHTextVerticalAlignmentTop: {
            runDelegate.ascent = font.ascender;
            runDelegate.descent = size.height - font.ascender;
            if (runDelegate.descent < 0) {
                runDelegate.descent = 0;
                runDelegate.ascent = size.height;
            }
        }break;
        case DHTextVerticalAlignmentBottom: {
            runDelegate.ascent = size.height + font.descender;
            runDelegate.descent = -font.descender;  //Usually descender is a negative value, if we don't leave some space for descender, the bottom part will not be displayed
            if (runDelegate.ascent < 0) {
                runDelegate.ascent = 0;
                runDelegate.descent = size.height;
            }
        }break;
        case DHTextVerticalAlignmentCenter: {
            CGFloat fontHeight = font.ascender - font.descender;
            CGFloat yOffset = font.ascender - fontHeight * 0.5;
            runDelegate.ascent = size.height * 0.5 + yOffset;
            runDelegate.descent = size.height - runDelegate.ascent;
            if (runDelegate.descent < 0) {
                runDelegate.descent = 0;
                runDelegate.ascent = size.height;
            }
        }break;
        default:
            break;
    }
    CTRunDelegateRef delegate = runDelegate.CTRunDelegate;
    [attrStr setRunDelegate:delegate forRange:NSMakeRange(0, [attrStr length])];
    if (delegate) {
        CFRelease(delegate);
    }
    return attrStr;
}

@end

@implementation NSMutableAttributedString (DHText)

#pragma mark - Set Common Attributes
- (void) setAttributes:(NSDictionary<NSString *,id> *)attributes
{
    if ([attributes isEqual:[NSNull null]]) {
        attributes = nil;
    }
    [self setAttributes:@{} range:NSMakeRange(0, self.length)]; //Remove Old Attributes
    [attributes enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        [self setAttribute:key value:obj];
    }];
}

- (void) setAttribute:(NSString *)attribute value:(id)value
{
    [self setAttribute:attribute value:value range:NSMakeRange(0, [self length])];
}

- (void) setAttribute:(NSString *)attribute value:(id)value range:(NSRange)range
{
    if (attribute == nil || [[NSNull null] isEqual:attribute]) return;
    if (value && ![[NSNull null] isEqual:value]) {
        [self addAttribute:attribute value:value range:range];
    } else {
        [self removeAttribute:attribute range:range];
    }
}

- (void) removeAttributesInRange:(NSRange)range
{
    [self setAttributes:nil range:range];
}

#pragma mark - Convenience Setters
#define ParagraphStyleSet(_attr_) \
[self enumerateAttribute:NSParagraphStyleAttributeName \
                 inRange:range \
                 options:kNilOptions \
                 usingBlock: ^(NSParagraphStyle *value, NSRange subRange, BOOL *stop) { \
                        NSMutableParagraphStyle *style = nil; \
                        if (value) { \
                            if (CFGetTypeID((__bridge CFTypeRef)(value)) == CTParagraphStyleGetTypeID()) { \
                                value = [NSParagraphStyle styleWithCTStyle:(__bridge CTParagraphStyleRef)(value)]; \
                            } \
                            if (value. _attr_ == _attr_) return; \
                            if ([value isKindOfClass:[NSMutableParagraphStyle class]]) { \
                                style = (id)value; \
                            } else { \
                                style = value.mutableCopy; \
                            } \
                        } else { \
                            if ([NSParagraphStyle defaultParagraphStyle]. _attr_ == _attr_) return; \
                            style = [NSParagraphStyle defaultParagraphStyle].mutableCopy; \
                        } \
                        style. _attr_ = _attr_; \
                        [self setParagraphStyle:style forRange:subRange]; \
}];

- (void) setFont:(UIFont *)font
{
    [self setFont:font forRange:NSMakeRange(0, [self length])];
}

- (void) setFont:(UIFont *)font forRange:(NSRange)range
{
    [self setAttribute:NSFontAttributeName value:font range:range];
}

- (void) setColor:(UIColor *)color
{
    [self setColor:color forRange:NSMakeRange(0, [self length])];
}

- (void) setColor:(UIColor *)color forRange:(NSRange)range
{
    [self setAttribute:NSForegroundColorAttributeName value:color range:range];
}

- (void) setBackgroundColor:(UIColor *)backgroundColor
{
    [self setBackgroundColor:backgroundColor forRange:NSMakeRange(0, [self length])];
}

- (void) setBackgroundColor:(UIColor *)backgroundColor forRange:(NSRange)range
{
    [self setAttribute:NSBackgroundColorAttributeName value:backgroundColor range:range];
}

- (void) setKern:(NSNumber *)kern
{
    [self setKern:kern forRange:NSMakeRange(0, [self length])];
}

- (void) setKern:(NSNumber *)kern forRange:(NSRange)range
{
    [self setAttribute:NSKernAttributeName value:kern range:range];
}

- (void) setStrokeWidth:(NSNumber *)strokeWidth
{
    [self setStrokeWidth:strokeWidth forRange:NSMakeRange(0, [self length])];
}

- (void) setStrokeWidth:(NSNumber *)strokeWidth forRange:(NSRange)range
{
    [self setAttribute:NSStrokeWidthAttributeName value:strokeWidth range:range];
}

- (void) setStrokeColor:(UIColor *)strokeColor
{
    [self setStrokeColor:strokeColor forRange:NSMakeRange(0, [self length])];
}

- (void) setStrokeColor:(UIColor *)strokeColor forRange:(NSRange)range
{
    [self setAttribute:NSStrokeColorAttributeName value:strokeColor range:range];
}

- (void) setShadow:(NSShadow *)shadow
{
    [self setShadow:shadow forRange:NSMakeRange(0, [self length])];
}

- (void) setShadow:(NSShadow *)shadow forRange:(NSRange)range
{
    [self setAttribute:NSShadowAttributeName value:shadow range:range];
}

- (void) setInnerShadow:(DHTextShadow *)innerShadow
{
    [self setInnerShadow:innerShadow forRange:NSMakeRange(0, [self length])];
}

- (void) setInnerShadow:(DHTextShadow *)innerShadow forRange:(NSRange)range
{
    [self setAttribute:DHTextInnerShadowAttributeName value:innerShadow range:range];
}

- (void) setParagraphStyle:(NSParagraphStyle *)paragraphStyle
{
    [self setParagraphStyle:paragraphStyle forRange:NSMakeRange(0, [self length])];
}

- (void) setParagraphStyle:(NSParagraphStyle *)paragraphStyle forRange:(NSRange)range
{
    [self setAttribute:NSParagraphStyleAttributeName value:paragraphStyle range:range];
}

- (void) setAliegnment:(NSTextAlignment)alignment
{
    [self setAliegnment:alignment forRange:NSMakeRange(0, [self length])];
}

- (void) setAliegnment:(NSTextAlignment)alignment forRange:(NSRange)range
{
    ParagraphStyleSet(alignment);
}

- (void) setParagraphSpacing:(CGFloat)paragraphSpacing
{
    [self setParagraphSpacing:paragraphSpacing forRange:NSMakeRange(0, [self length])];
}

- (void) setParagraphSpacing:(CGFloat)paragraphSpacing forRange:(NSRange)range
{
    ParagraphStyleSet(paragraphSpacing);
}

- (void) setLineBreakMode:(NSLineBreakMode)lineBreakMode
{
    [self setLineBreakMode:lineBreakMode forRange:NSMakeRange(0, [self length])];
}

- (void) setLineBreakMode:(NSLineBreakMode)lineBreakMode forRange:(NSRange)range
{
    ParagraphStyleSet(lineBreakMode);
}

- (void) setLineSpacing:(CGFloat)lineSpacing
{
    [self setLineSpacing:lineSpacing forRange:NSMakeRange(0, [self length])];
}

- (void) setLineSpacing:(CGFloat)lineSpacing forRange:(NSRange)range
{
    ParagraphStyleSet(lineSpacing);
}

- (void) setRunDelegate:(CTRunDelegateRef)runDelegate
{
    [self setRunDelegate:runDelegate forRange:NSMakeRange(0, [self length])];
}

- (void) setRunDelegate:(CTRunDelegateRef)runDelegate forRange:(NSRange)range
{
    [self setAttribute:(id)kCTRunDelegateAttributeName value:(__bridge id)runDelegate range:range];
}

- (void) setAttachment:(NSTextAttachment *)attachment
{
    [self setAttachment:attachment forRange:NSMakeRange(0, [self length])];
}

- (void) setAttachment:(NSTextAttachment *)attachment forRange:(NSRange)range
{
    [self setAttribute:NSAttachmentAttributeName value:attachment range:range];
}

- (void) setTextAttachment:(DHTextAttachment *)textAttachment
{
    [self setTextAttachment:textAttachment forRange:NSMakeRange(0, [self length])];
}

- (void) setTextAttachment:(DHTextAttachment *)textAttachment forRange:(NSRange)range
{
    [self setAttribute:DHTextAttachmentAttributeName value:textAttachment range:range];
}

@end
