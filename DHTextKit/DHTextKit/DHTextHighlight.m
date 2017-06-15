//
//  DHTextHighlight.m
//  DHTextKit
//
//  Created by Huang Hongsen on 17/6/13.
//  Copyright © 2017年 Huang Hongsen. All rights reserved.
//

#import "DHTextHighlight.h"
#import <CoreText/CoreText.h>
#import "DHTextAttribute.h"

@implementation DHTextHighlight

+ (instancetype) highlightWithAttributes:(NSDictionary *)attributes
{
    DHTextHighlight *highlight = [DHTextHighlight new];
    highlight.attributes = attributes;
    return highlight;
}

+ (instancetype) highlightWithBackgroundColor:(UIColor *)color
{
    DHTextBorder *highlightBorder = [DHTextBorder new];
    highlightBorder.insets = UIEdgeInsetsMake(-2, -1, -2, -1);
    highlightBorder.cornerRadius = 3;
    highlightBorder.fillColor = color;
    
    DHTextHighlight *highlight = [DHTextHighlight new];
    [highlight setBackgroundBorder:highlightBorder];
    return highlight;
}

- (void) setAttributes:(NSDictionary *)attributes
{
    _attributes = [attributes mutableCopy];
}

#pragma mark - NSCoding
//TO-DO: NSCoding
- (void) encodeWithCoder:(NSCoder *)aCoder
{
    
}

- (instancetype) initWithCoder:(NSCoder *)aDecoder
{
    return nil;
}

#pragma mark - NSCopying
- (instancetype) copyWithZone:(NSZone *)zone
{
    DHTextHighlight *one = [DHTextHighlight new];
    one.attributes = [self.attributes mutableCopy];
    return one;
}

#pragma mark - Setters
- (void) _makeMutableAttributes
{
    if (!_attributes) {
        _attributes = [NSMutableDictionary dictionary];
    } else if (![_attributes isKindOfClass:[NSMutableDictionary class]]) {
        _attributes = [_attributes mutableCopy];
    }
}

- (void) setFont:(UIFont *)font
{
    [self _makeMutableAttributes];
    if (font == (id)[NSNull null] || font == nil) {
        ((NSMutableDictionary *)_attributes)[(id)kCTFontAttributeName] = [NSNull null];
    } else {
        CTFontRef fontRef = CTFontCreateWithName((__bridge CFStringRef)font.fontName, font.pointSize, NULL);
        if (fontRef) {
            ((NSMutableDictionary *)_attributes)[(id)kCTFontAttributeName] = (__bridge id)fontRef;
            CFRelease(fontRef);
        }
    }
}

- (void) setColor:(UIColor *)color
{
    [self _makeMutableAttributes];
    if (color == nil || color == (id)[NSNull null]) {
        ((NSMutableDictionary *)_attributes)[(id)kCTForegroundColorAttributeName] = [NSNull null];
        ((NSMutableDictionary *)_attributes)[NSForegroundColorAttributeName] = [NSNull null];
    } else {
        ((NSMutableDictionary *)_attributes)[(id)kCTForegroundColorAttributeName] = (__bridge id)color.CGColor;
        ((NSMutableDictionary *)_attributes)[NSForegroundColorAttributeName] = color;
    }
}

- (void) setStrokeWidth:(NSNumber *)strokeWidth
{
    [self _makeMutableAttributes];
    if (strokeWidth == nil || strokeWidth == (id)[NSNull null]) {
        ((NSMutableDictionary *)_attributes)[(id)kCTStrokeWidthAttributeName] = [NSNull null];
    } else {
        ((NSMutableDictionary *)_attributes)[(id)kCTStrokeWidthAttributeName] = strokeWidth;
    }
}

- (void) setStrokeColor:(UIColor *)color
{
    [self _makeMutableAttributes];
    if (color == (id)[NSNull null] || color == nil) {
        ((NSMutableDictionary *)_attributes)[(id)kCTStrokeColorAttributeName] = [NSNull null];
        ((NSMutableDictionary *)_attributes)[NSStrokeColorAttributeName] = [NSNull null];
    } else {
        ((NSMutableDictionary *)_attributes)[(id)kCTStrokeColorAttributeName] = (__bridge id)(color.CGColor);
        ((NSMutableDictionary *)_attributes)[NSStrokeColorAttributeName] = color;
    }
}

- (void)setTextAttribute:(NSString *)attribute value:(id)value {
    [self _makeMutableAttributes];
    if (value == nil) value = [NSNull null];
    ((NSMutableDictionary *)_attributes)[attribute] = value;
}

- (void)setShadow:(DHTextShadow *)shadow {
    [self setTextAttribute:DHTextShadowAttributeName value:shadow];
}

- (void)setInnerShadow:(DHTextShadow *)shadow {
    [self setTextAttribute:DHTextInnerShadowAttributeName value:shadow];
}

- (void)setUnderline:(DHTextDecoration *)underline {
    [self setTextAttribute:DHTextUnderlineAttributeName value:underline];
}

- (void)setStrikeThrough:(DHTextDecoration *)strikethrough {
    [self setTextAttribute:DHTextStrikeThroughAttributeName value:strikethrough];
}

- (void)setBackgroundBorder:(DHTextBorder *)border {
    [self setTextAttribute:DHTextBackgroundBorderAttributeName value:border];
}

- (void)setBorder:(DHTextBorder *)border {
    [self setTextAttribute:DHTextBorderAttributeName value:border];
}

- (void)setAttachment:(DHTextAttachment *)attachment {
    [self setTextAttribute:DHTextAttachmentAttributeName value:attachment];
}
@end
