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
- (void) setFont:(UIFont *)font forRange:(NSRange)range
{
    [self setAttribute:NSFontAttributeName value:font range:range];
}

- (void) setColor:(UIColor *)color forRange:(NSRange)range
{
    [self setAttribute:NSForegroundColorAttributeName value:color range:range];
}

- (void) setBackgroundColor:(UIColor *)backgroundColor forRange:(NSRange)range
{
    [self setAttribute:NSBackgroundColorAttributeName value:backgroundColor range:range];
}

- (void) setKern:(NSNumber *)kern forRange:(NSRange)range
{
    [self setAttribute:NSKernAttributeName value:kern range:range];
}

- (void) setStrokeWidth:(NSNumber *)strokeWidth forRange:(NSRange)range
{
    [self setAttribute:NSStrokeWidthAttributeName value:strokeWidth range:range];
}

- (void) setStrokeColor:(UIColor *)strokeColor forRange:(NSRange)range
{
    [self setAttribute:NSStrokeColorAttributeName value:strokeColor range:range];
}

- (void) setShadow:(NSShadow *)shadow forRange:(NSRange)range
{
    [self setAttribute:NSShadowAttributeName value:shadow range:range];
}

- (void) setParagraphSytle:(NSParagraphStyle *)paragraphStyle forRange:(NSRange)range
{
    [self setAttribute:NSParagraphStyleAttributeName value:paragraphStyle range:range];
}

- (void) setAliegnment:(NSTextAlignment)alignment forRange:(NSRange)range
{
}

- (void) setParagraphSpacing:(NSNumber *)paragraphSpacing forRange:(NSRange)range
{
    
}

- (void) setLineBreakMode:(NSLineBreakMode)lineBreakMode forRange:(NSRange)range
{
    
}

- (void) setLineSpacing:(NSNumber *)lineSpacing forRange:(NSRange)range
{
    
}

- (void) setRunDelegate:(CTRunDelegateRef)runDelegate forRange:(NSRange)range
{
    [self setAttribute:(id)kCTRunDelegateAttributeName value:(__bridge id)runDelegate range:range];
}

- (void) setAttachment:(NSTextAttachment *)attachment forRange:(NSRange)range
{
    [self setAttribute:NSAttachmentAttributeName value:attachment range:range];
}

- (void) setTextAttachment:(DHTextAttachment *)textAttachment forRange:(NSRange)range
{
    [self setAttribute:DHTextAttachmentAttributeName value:textAttachment range:range];
}

@end
