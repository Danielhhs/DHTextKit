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
#import "DHTextShadow.h"
#import "DHTextBorder.h"

@interface DHTextLine () {
    CGFloat _firstGlyphPos;
}
@property (nonatomic, readwrite) CTLineRef ctLine;
@property (nonatomic, readwrite) NSRange range;
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

//Improve drawing efficiency.
@property (nonatomic) BOOL needToDrawShadow;
@property (nonatomic) BOOL needToDrawAttachment;
@property (nonatomic) BOOL needToDrawInnerShadow;
@property (nonatomic) BOOL needToDrawText;
@property (nonatomic) BOOL needToDrawBackgroundBorder;
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
    if (!CGPointEqualToPoint(position, _position)) {
        _position = position;
        [self reloadLine];
    }
}

//TO-DO: Called twice while initialization;
- (void) reloadLine
{
    [self updateBounds];
    [self clearOldAttachments];
    
    if (_ctLine == NULL) {
        return;
    }
    [self reloadAttachments];
    [self reloadDrawingStatus];
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

- (void) reloadDrawingStatus
{
    [self clearDrawingStatus];
    CFArrayRef runs = CTLineGetGlyphRuns(self.ctLine);
    CFIndex runCount = CFArrayGetCount(runs);
    for (CFIndex runNo = 0; runNo < runCount; runNo++) {
        CTRunRef run = CFArrayGetValueAtIndex(runs, runNo);
        NSDictionary *attribtues = (id) CTRunGetAttributes(run);
        if (CTRunGetGlyphCount(run) > 0) {
            self.needToDrawText = YES;
        }
        if (attribtues[NSShadowAttributeName] || attribtues[DHTextShadowAttributeName]) {
            self.needToDrawShadow = YES;
        }
        if (attribtues[DHTextAttachmentAttributeName]) {
            self.needToDrawAttachment = YES;
        }
        if (attribtues[DHTextInnerShadowAttributeName]) {
            self.needToDrawInnerShadow = YES;
        }
    }
}

- (void) clearDrawingStatus
{
    self.needToDrawShadow = NO;
    self.needToDrawAttachment = NO;
    self.needToDrawInnerShadow = NO;
}

#pragma mark - Drawing
- (void) drawInContext:(CGContextRef)context
                  size:(CGSize)size
              position:(CGPoint)position
                inView:(UIView *)view
               orLayer:(CALayer *)layer
{
    [self drawBorderInContext:context size:size position:position type:DHTextBorderTypeBackground];
    [self drawShadowInContext:context size:size position:position];
    [self drawTextInContext:context size:size position:position];
    [self drawInnerShadowInContext:context size:size position:position];
    [self drawAttachmentsInContext:context size:size position:position inView:view orLayer:layer];
}

- (void) drawBorderInContext:(CGContextRef)context
                        size:(CGSize)size
                    position:(CGPoint)position
                        type:(DHTextBorderType)type
{
    CGFloat linePosX = self.position.x;
    CGFloat linePosY = size.height - self.position.y;
    CGContextSaveGState(context);
    NSString *attributeKey = (type == DHTextBorderTypeNormal ? DHTextBorderAttributeName : DHTextBackgroundBorderAttributeName);
    CFArrayRef runs = CTLineGetGlyphRuns(self.ctLine);
    CFIndex runCount = CFArrayGetCount(runs);
    CFRange lineRange = CTLineGetStringRange(self.ctLine);
    for (CFIndex runNo = 0; runNo < runCount; runNo++) {
        CTRunRef run = CFArrayGetValueAtIndex(runs, runNo);
        CFIndex glyphCount = CTRunGetGlyphCount(run);
        if (glyphCount == 0) {
            continue;
        }
        
        NSDictionary *attributes = (id)CTRunGetAttributes(run);
        DHTextBorder *border = attributes[attributeKey];
        if (!border) continue;
        
        CFRange textRange = CTRunGetStringRange(run);
        if (textRange.location == kCFNotFound || textRange.length == 0) continue;
        if (textRange.location + textRange.length > lineRange.location + lineRange.length) continue;
        
        NSMutableArray *runRects = [NSMutableArray array];
        CGPoint runPosition = CGPointZero;
        CTRunGetPositions(run, CFRangeMake(0, 1), &runPosition);
        CGFloat ascent, descent;
        CGFloat width = CTRunGetTypographicBounds(run, CFRangeMake(0, 0), &ascent, &descent, NULL);
        runPosition.x += linePosX;
        CGRect boundingRect = CGRectMake(runPosition.x, linePosY - descent, width, ascent + descent);
        [runRects addObject:[NSValue valueWithCGRect:boundingRect]];
        [self drawBorder:border inRects:runRects inContext:context size:size position:position];
    }
    CGContextRestoreGState(context);
}

- (void) drawBorder:(DHTextBorder *)border
            inRects:(NSArray *)rects
          inContext:(CGContextRef)context
               size:(CGSize)size
           position:(CGPoint)position
{
    if ([rects count] == 0) return;
    
    DHTextShadow *shadow = border.shadow;
    if (shadow.color) {
        CGContextSaveGState(context);
        CGContextSetShadowWithColor(context, shadow.offset, shadow.radius, shadow.color.CGColor);
        CGContextBeginTransparencyLayer(context, NULL);
    }
    
    NSMutableArray *paths = [NSMutableArray array];
    for (NSValue *value in rects) {
        CGRect rect = [value CGRectValue];
        rect = UIEdgeInsetsInsetRect(rect, border.insets);
        UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:rect cornerRadius:border.cornerRadius];
        [path closePath];
        [paths addObject:path];
    }
    
    if (border.fillColor) {
        CGContextSaveGState(context);
        CGContextSetFillColorWithColor(context, border.fillColor.CGColor);
        for (UIBezierPath *path in paths) {
            CGContextAddPath(context, path.CGPath);
        }
        CGContextFillPath(context);
        CGContextRestoreGState(context);
    }
    
    if (border.strokeColor && border.lineStyle > 0 && border.strokeWidth > 0) {
        //Draw Single line;
        CGContextSaveGState(context);
        for (UIBezierPath *path in paths) {
            CGRect bounds = CGRectUnion(path.bounds, CGRectMake(0, 0, size.width, size.height));
            bounds = CGRectInset(bounds, -2 * border.strokeWidth, -2 * border.strokeWidth);
            CGContextAddRect(context, bounds);
            CGContextAddPath(context, path.CGPath);
            CGContextEOClip(context);
        }
        [border.strokeColor setStroke];
        CGFloat inset = -border.strokeWidth * 0.5;
        if ((border.lineStyle & 0xFF) == DHTextLineStyleThick) {
            inset *= 2;
            CGContextSetLineWidth(context, border.strokeWidth * 2);
        } else {
            CGContextSetLineWidth(context, border.strokeWidth);
        }
        CGFloat radiusDelta = -inset;   //inset is a negtive value, because the border should be larger than the text rect
        if (border.cornerRadius <= 0) {
            radiusDelta = 0;
        }
        CGContextSetLineJoin(context, border.lineJoin);
        for (NSValue *value in rects) {
            CGRect rect = [value CGRectValue];
            rect = UIEdgeInsetsInsetRect(rect, border.insets);
            rect = CGRectInset(rect, inset, inset);
            UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:rect cornerRadius:border.cornerRadius + radiusDelta];
            [path closePath];
            CGContextAddPath(context, path.CGPath);
        }
        CGContextStrokePath(context);
        CGContextRestoreGState(context);
    }
}

- (void) drawShadowInContext:(CGContextRef)context
                        size:(CGSize)size
                    position:(CGPoint)position
{
    if (self.needToDrawShadow == NO) {
        return ;
    }
    CGFloat offsetAlterX = size.width + 0xFFFF;     //Move out of context to avoid blend
    CGContextSaveGState(context);
    CGFloat linePosX = self.position.x;
    CGFloat linePosY = size.height - self.position.y;
    CFArrayRef runs = CTLineGetGlyphRuns(_ctLine);
    CFIndex numberOfRuns = CFArrayGetCount(runs);
    for (CFIndex runNo = 0; runNo < numberOfRuns; runNo++) {
        CTRunRef run = CFArrayGetValueAtIndex(runs, runNo);
        CGContextSetTextMatrix(context, CGAffineTransformIdentity);
        CGContextSetTextPosition(context, linePosX, linePosY);
        NSDictionary *attributes = (id)CTRunGetAttributes(run);
        DHTextShadow *shadow = attributes[DHTextShadowAttributeName];
        DHTextShadow *nsShadow = [DHTextShadow shadowWithNSShadow:attributes[NSShadowAttributeName]];
        if (nsShadow) {
            nsShadow.subShadow = shadow;
            shadow = nsShadow;
        }
        while (shadow) {
            if (shadow.color == nil) {
                shadow = shadow.subShadow;
                continue;
            }
            CGSize offset = shadow.offset;
            offset.width -= offsetAlterX;
            CGContextSaveGState(context); {
                CGContextSetShadowWithColor(context, offset, shadow.radius, shadow.color.CGColor);
                CGContextSetBlendMode(context, shadow.blendMode);
                CGContextTranslateCTM(context, offsetAlterX, 0);
                CTRunDraw(run, context, CFRangeMake(0, 0));
            }
            CGContextRestoreGState(context);
            shadow = shadow.subShadow;
        }
    }
    
}

- (void) drawTextInContext:(CGContextRef)context
                      size:(CGSize)size
                  position:(CGPoint)position
{
    if (self.needToDrawText == NO) {
        return;
    }
    CGPoint lineOrigin;
    lineOrigin.x = self.position.x;
    lineOrigin.y = self.position.y;
    CFArrayRef runs = CTLineGetGlyphRuns(self.ctLine);
    CFIndex numberOfRuns = CFArrayGetCount(runs);
    for (CFIndex runNo = 0; runNo < numberOfRuns; runNo++) {
        CTRunRef run = CFArrayGetValueAtIndex(runs, runNo);
        CGContextSetTextMatrix(context, CGAffineTransformIdentity);
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
    if (self.needToDrawAttachment == NO) {
        return;
    }
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

- (void) drawInnerShadowInContext:(CGContextRef)context
                             size:(CGSize)size
                         position:(CGPoint)position
{
    if (self.needToDrawInnerShadow == NO) {
        return ;
    }
    CGPoint lineOrigin;
    lineOrigin.x = self.position.x;
    lineOrigin.y = self.position.y;
    CFArrayRef runs = CTLineGetGlyphRuns(self.ctLine);
    CFIndex runCount = CFArrayGetCount(runs);
    for (CFIndex runNo = 0; runNo < runCount; runNo++) {
        CTRunRef run = CFArrayGetValueAtIndex(runs, runNo);
        if (CTRunGetGlyphCount(run) == 0) continue;
        CGContextSetTextMatrix(context, CGAffineTransformIdentity);
        CGContextSetTextPosition(context, lineOrigin.x, size.height - lineOrigin.y);
        NSDictionary *attributes = (id)CTRunGetAttributes(run);
        DHTextShadow *shadow = attributes[DHTextInnerShadowAttributeName];
        while (shadow) {
            if (!shadow.color) {
                shadow = shadow.subShadow;
                continue;
            }
            CGPoint runPosition = CGPointZero;
            CTRunGetPositions(run, CFRangeMake(0, 1), &runPosition);
            CGRect runImageBounds = CTRunGetImageBounds(run, context, CFRangeMake(0, 0));
            runImageBounds.origin.x += runPosition.x;
            if (runImageBounds.size.width < 0.1 || runImageBounds.size.height < 0.1) continue;  //Too small to draw
            
            CFDictionaryRef runAttrs = CTRunGetAttributes(run);
            NSValue *glyphTransform = CFDictionaryGetValue(runAttrs, (__bridge const void *)DHTextGlyphTransformAttributeName);
            if (glyphTransform) {
                runImageBounds = CGRectMake(0, 0, size.width, size.height);
            }
            
            CGContextSaveGState(context); {
                CGContextSetBlendMode(context, shadow.blendMode);
                CGContextSetShadowWithColor(context, CGSizeZero, 0, shadow.color.CGColor);
                CGContextSetAlpha(context, CGColorGetAlpha(shadow.color.CGColor));
                CGContextClipToRect(context, runImageBounds);
                CGContextBeginTransparencyLayer(context, NULL); {
                    UIColor *opaqueShadowColor = [shadow.color colorWithAlphaComponent:1];
                    CGContextSetShadowWithColor(context, shadow.offset, shadow.radius, opaqueShadowColor.CGColor);
                    CGContextSetFillColorWithColor(context, opaqueShadowColor.CGColor);
                    CGContextSetBlendMode(context, kCGBlendModeSourceOut);
                    CGContextBeginTransparencyLayer(context, NULL);{
                        CGContextFillRect(context, runImageBounds);
                        CGContextSetBlendMode(context, kCGBlendModeDestinationIn);
                        CGContextBeginTransparencyLayer(context, NULL); {
                            CTRunDraw(run, context, CFRangeMake(0, 0));
                        } CGContextEndTransparencyLayer(context);
                    }CGContextEndTransparencyLayer(context);
                }CGContextEndTransparencyLayer(context);
            }
            CGContextRestoreGState(context);
            shadow = shadow.subShadow;
        }
    }
}
@end
