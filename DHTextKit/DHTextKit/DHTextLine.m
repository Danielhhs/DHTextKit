//
//  DHTextLine.m
//  DHTextKit
//
//  Created by Huang Hongsen on 17/5/24.
//  Copyright © 2017年 Huang Hongsen. All rights reserved.
//

#import "DHTextLine.h"
#import "DHTextUtils.h"
#import "DHTextAttribute.h"

@interface DHTextLine () {
    CGFloat _firstGlyphPos;
}
@property (nonatomic, readwrite) CTLineRef ctLine;
@property (nonatomic, readwrite) NSRange range;
@property (nonatomic, readwrite) NSUInteger index;
@property (nonatomic, readwrite) NSUInteger row;
@property (nonatomic, readwrite) CGRect bounds;
@property (nonatomic, readwrite) CGSize size;
@property (nonatomic, readwrite) CGFloat width;
@property (nonatomic, readwrite) CGFloat height;
@property (nonatomic, readwrite) CGFloat left;
@property (nonatomic, readwrite) CGFloat right;
@property (nonatomic, readwrite) CGFloat top;
@property (nonatomic, readwrite) CGFloat bottom;

@property (nonatomic, readwrite) CGFloat ascent;
@property (nonatomic, readwrite) CGFloat descent;
@property (nonatomic, readwrite) CGFloat leading;
@property (nonatomic, readwrite) CGFloat lineWidth;
@property (nonatomic, readwrite) CGFloat trailingWhiteSpaceWidth;
@end

@implementation DHTextLine

#pragma mark - Initialze
+ (DHTextLine *) lineWithCTLine:(CTLineRef)ctLine position:(CGPoint)position
{
    DHTextLine *line = [[DHTextLine alloc] init];
    line.ctLine = ctLine;
    line.position = position;
    return line;
}

#pragma mark - Setters & reload
- (void) setCtLine:(CTLineRef)ctLine
{
    if (ctLine != _ctLine) {
        if (ctLine) {
            CFRetain(ctLine);
        }
        if (_ctLine) {
            CFRelease(_ctLine);
        }
        _ctLine = ctLine;
        if (_ctLine) {
            _lineWidth = CTLineGetTypographicBounds(_ctLine, &_ascent, &_descent, &_leading);
            CFRange range = CTLineGetStringRange(_ctLine);
            _range = [DHTextUtils NSRangeFromCFRange:range];
            if (CTLineGetGlyphCount(_ctLine) > 0) {
                CFArrayRef runs = CTLineGetGlyphRuns(_ctLine);
                CTRunRef run = CFArrayGetValueAtIndex(runs, 0);
                CGPoint pos;
                CTRunGetPositions(run, CFRangeMake(0, 1), &pos);
                _firstGlyphPos = pos.x;
            } else {
                _firstGlyphPos = 0;
            }
            _trailingWhiteSpaceWidth = CTLineGetTrailingWhitespaceWidth(_ctLine);
        } else {
            _lineWidth = _ascent = _descent = _leading = _firstGlyphPos = _trailingWhiteSpaceWidth = 0;
            _range = [DHTextUtils emptyNSRange];
        }
        [self reloadLine];
    }
}

- (void) setPosition:(CGPoint)position
{
    _position = position;
    [self reloadLine];
}

- (void) reloadLine
{
    [self updateBounds];
    [self clearOldAttachments];
    
    if (_ctLine == NULL) {
        return;
    }
    [self reloadAttachments];
}

- (void) updateBounds
{
    _bounds = CGRectMake(_position.x, _position.y - _ascent, _lineWidth, _ascent + _descent);
    _bounds.origin.x += _firstGlyphPos;
}

- (void) clearOldAttachments
{
    _attachments = nil;
    _attachmentRects = nil;
    _attachmentRanges = nil;
}

- (void) reloadAttachments
{
    CFArrayRef runs = CTLineGetGlyphRuns(_ctLine);
    CFIndex runCount = CFArrayGetCount(runs);
    if (runCount == 0) {
        return ;
    }
    
    NSMutableArray *attachments = [NSMutableArray array];
    NSMutableArray *attachmentRanges = [NSMutableArray array];
    NSMutableArray *attachmentRects = [NSMutableArray array];
    
    for (CFIndex r = 0; r < runCount; r++) {
        CTRunRef run = CFArrayGetValueAtIndex(runs, r);
        CFIndex glyphCount = CTRunGetGlyphCount(run);
        if (glyphCount == 0) {
            continue;
        }
        NSDictionary *attrs = (id)CTRunGetAttributes(run);
        DHTextAttachment *attachment = attrs[DHTextAttachmentAttributeName];
        if (attachment) {
            CGPoint runPosition;
            CTRunGetPositions(run, CFRangeMake(0, 1), &runPosition);
            CGFloat ascent, descent, leading, runWidth;
            CGRect runTypoBounds;
            runWidth = CTRunGetTypographicBounds(run, [DHTextUtils emptyCFRange], &ascent, &descent, &leading);
            
            runPosition.x += _position.x;
            runPosition.y = self.bounds.origin.y - runPosition.y;
            
            runTypoBounds = CGRectMake(runPosition.x, runPosition.y, runWidth, ascent + descent);
            
            NSRange runRange = [DHTextUtils NSRangeFromCFRange:CTRunGetStringRange(run)];
            [attachments addObject:attachment];
            [attachmentRanges addObject:[NSValue valueWithRange:runRange]];
            [attachmentRects addObject:[NSValue valueWithCGRect:runTypoBounds]];
        }
    }
    _attachments = [attachments count] == 0 ? nil : attachments;
    _attachmentRanges = [attachmentRanges count] == 0 ? nil : attachmentRanges;
    _attachmentRects = [attachmentRects count] == 0 ? nil : attachmentRects;
}

#pragma mark - Drawing
- (void) drawInContext:(CGContextRef)context
                  size:(CGSize)size
              position:(CGPoint)position
                inView:(UIView *)view
               orLayer:(CALayer *)layer
{
    [self drawShadowInContext:context size:size position:position];
    [self drawTextInContext:context size:size position:position];
    [self drawAttachmentsInContext:context size:size position:position inView:view orLayer:layer];
}

- (void) drawShadowInContext:(CGContextRef)context
                        size:(CGSize)size
                    position:(CGPoint)position
{
    
}

- (void) drawTextInContext:(CGContextRef)context
                      size:(CGSize)size
                  position:(CGPoint)position
{
    CGPoint lineOrigin;
    lineOrigin.x = self.position.x;
    lineOrigin.y = self.position.y;
    CFArrayRef runs = CTLineGetGlyphRuns(self.ctLine);
    CFIndex numberOfRuns = CFArrayGetCount(runs);
    for (CFIndex runNo = 0; runNo < numberOfRuns; runNo++) {
        CTRunRef run = CFArrayGetValueAtIndex(runs, runNo);
        CGContextSetTextMatrix(NULL, CGAffineTransformIdentity);
        CGContextSetTextPosition(context, lineOrigin.x, size.height - lineOrigin.y);
        CTRunDraw(run, context, [DHTextUtils emptyCFRange]);
    }
}

- (void) drawAttachmentsInContext:(CGContextRef)context
                             size:(CGSize)size
                         position:(CGPoint)position
                           inView:(UIView *)targetView
                          orLayer:(CALayer *)targetLayer
{
    for (NSInteger i = 0; i < [self.attachments count]; i++) {
        DHTextAttachment *attachment = self.attachments[i];
        if (attachment.content == nil) {
            return;
        }
        
        UIView *view = nil;
        UIImage *image = nil;
        CALayer *layer = nil;
        if ([attachment.content isKindOfClass:[UIImage class]]) {
            image = (UIImage *)attachment.content;
        } else if ([attachment.content isKindOfClass:[UIView class]]) {
            view = (UIView *)attachment.content;
        } else if ([attachment.content isKindOfClass:[CALayer class]]) {
            layer = (CALayer *)attachment.content;
        }
        
        if (!image && !view && !layer) continue;
        if (image && !context) continue;
        if (view && !targetView) continue;
        if (layer && !targetLayer) continue;
        
        CGRect rect = [((NSValue *)self.attachmentRects[i]) CGRectValue];
        rect = UIEdgeInsetsInsetRect(rect, attachment.contentInsets);
        rect = CGRectStandardize(rect);
        rect.origin.x += position.x;
        rect.origin.y += position.y;
        
        if (image) {
            CGImageRef imageRef = image.CGImage;
            if (imageRef) {
                CGContextSaveGState(context);
                CGContextTranslateCTM(context, 0, size.height);   //minY: move to the rect system, maxY: flip around;
                CGContextScaleCTM(context, 1, -1);
                CGContextDrawImage(context, rect, imageRef);
                CGContextRestoreGState(context);
            }
        } else if (view) {
            view.frame = rect;
            [targetView addSubview:view];
        } else if (layer) {
            layer.frame = rect;
            [targetLayer addSublayer:layer];
        }
    }
}
@end
