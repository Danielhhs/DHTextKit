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
#import "DHTextDecoration.h"

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
@property (nonatomic) BOOL needToDrawUnderline;
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
        if (attribtues[DHTextBackgroundBorderAttributeName]) {
            self.needToDrawBackgroundBorder = YES;
        }
        if (attribtues[DHTextUnderlineAttributeName]) {
            self.needToDrawUnderline = YES;
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
    [self drawDecorationInContext:context size:size position:position type:DHTextDecorationTypeUnderLine];
    [self drawTextInContext:context size:size position:position];
    [self drawInnerShadowInContext:context size:size position:position];
    [self drawAttachmentsInContext:context size:size position:position inView:view orLayer:layer];
    
}

- (void) drawBorderInContext:(CGContextRef)context
                        size:(CGSize)size
                    position:(CGPoint)position
                        type:(DHTextBorderType)type
{
    if (type == DHTextBorderTypeBackground && self.needToDrawBackgroundBorder == NO) {
        return;
    }
    CGFloat linePosX = self.position.x;
    CGFloat linePosY = size.height - self.position.y;
    CGContextSaveGState(context);
    NSString *attributeKey = (type == DHTextBorderTypeNormal ? DHTextBorderAttributeName : DHTextBackgroundBorderAttributeName);
    CFArrayRef runs = CTLineGetGlyphRuns(self.ctLine);
    CFIndex runCount = CFArrayGetCount(runs);
    CFRange lineRange = CTLineGetStringRange(self.ctLine);
    BOOL needToSkipRun = NO;
    NSInteger jumpRunIndex = 0;
    for (CFIndex runNo = 0; runNo < runCount; runNo++) {
        if (needToSkipRun == YES) {
            needToSkipRun = NO;
            runNo = jumpRunIndex + 1;
            if (runNo >= runCount) break;
        }
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
        BOOL endFound = NO;
        NSInteger endRunIndex = runNo;
        for (CFIndex rr = runNo; rr < runCount; rr++) {
            CTRunRef iRun = CFArrayGetValueAtIndex(runs, rr);
            NSDictionary *attrs = (id)CTRunGetAttributes(iRun);
            DHTextBorder *iBorder = attrs[attributeKey];
            if (![border isEqual:iBorder]) {
                endFound = YES;
                break;
            }
            endRunIndex = rr;
            CGPoint runPosition = CGPointZero;
            CTRunGetPositions(iRun, CFRangeMake(0, 1), &runPosition);
            CGFloat ascent, descent;
            CGFloat width = CTRunGetTypographicBounds(iRun, CFRangeMake(0, 0), &ascent, &descent, NULL);
            runPosition.x += linePosX;
            CGRect boundingRect = CGRectMake(runPosition.x, linePosY - descent, width, ascent + descent);
            [runRects addObject:[NSValue valueWithCGRect:boundingRect]];
        }
        
        //Merge rects in the same line
        NSMutableArray *drawRects = [NSMutableArray array];
        CGRect currentRect = [[runRects firstObject] CGRectValue];
        for (NSInteger rectNo = 0; rectNo < [runRects count]; rectNo++) {
            CGRect rect = [runRects[rectNo] CGRectValue];
            if (fabs(rect.origin.y - currentRect.origin.y) < 1) {
                currentRect = [DHTextUtils mergeRect:rect withRect:currentRect isVertical:NO];
            } else {
                [drawRects addObject:[NSValue valueWithCGRect:currentRect]];
            }
        }
        if (!CGRectEqualToRect(currentRect, CGRectZero)) {
            [drawRects addObject:[NSValue valueWithCGRect:currentRect]];
        }
        [self drawBorder:border inRects:drawRects inContext:context size:size position:position];
        needToSkipRun = YES;
        jumpRunIndex = endRunIndex;
    }
    CGContextRestoreGState(context);
}

#pragma mark - Draw Border
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
        [self updateLinePatternForStyle:border.lineStyle lineWidth:border.strokeWidth inContext:context phase:0];
        CGFloat inset = -border.strokeWidth * 0.5;
        if ((border.lineStyle & 0xFF) == DHTextLineStyleThick) {
            inset *= 2;
            CGContextSetLineWidth(context, border.strokeWidth * 2);
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
        
        if ((border.lineStyle & 0xFF) == DHTextLineStyleDouble) {       //Draw double line
            CGContextSaveGState(context);
            CGFloat inset = -border.strokeWidth * 2;
            for (NSValue *value in rects) {
                CGRect rect = [value CGRectValue];
                rect = UIEdgeInsetsInsetRect(rect, border.insets);
                rect = CGRectInset(rect, inset, inset);
                UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:rect cornerRadius:border.cornerRadius + 2 *border.strokeWidth];
                [path closePath];
                
                CGRect bounds = CGRectUnion(path.bounds, (CGRect){CGPointZero, size});
                bounds = CGRectInset(bounds, -2 * border.strokeWidth, -2 * border.strokeWidth);
                CGContextAddRect(context, bounds);
                CGContextAddPath(context, path.CGPath);
                CGContextEOClip(context);
            }
            [self updateLinePatternForStyle:border.lineStyle lineWidth:border.strokeWidth inContext:context phase:0];
            CGContextSetStrokeColorWithColor(context, border.strokeColor.CGColor);
            CGContextSetLineJoin(context, border.lineJoin);
            CGContextSetLineWidth(context, border.strokeWidth);
            inset = -border.strokeWidth * 2.5;
            radiusDelta = border.strokeWidth * 2;
            if (border.cornerRadius <= 0) {
                radiusDelta = 0;
            }
            for (NSValue *value in rects) {
                CGRect rect = [value CGRectValue];
                rect = UIEdgeInsetsInsetRect(rect, border.insets);
                rect = CGRectInset(rect, inset, inset);
                UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:rect cornerRadius:border.cornerRadius + border.strokeWidth];
                [path closePath];
                CGContextAddPath(context, path.CGPath);
            }
            CGContextStrokePath(context);
            CGContextRestoreGState(context);
        }
    }
    if (shadow.color) {
        CGContextEndTransparencyLayer(context);
        CGContextRestoreGState(context);
    }
}

- (void) updateLinePatternForStyle:(DHTextLineStyle)style
                         lineWidth:(CGFloat) lineWidth
                          inContext:(CGContextRef)context
                              phase:(CGFloat)phase
{
    CGContextSetLineWidth(context, lineWidth);
    CGContextSetLineCap(context, kCGLineCapButt);
    CGContextSetLineJoin(context, kCGLineJoinMiter);
    
    CGFloat dash = 12, dot = 5, space = 3;
    CGFloat width = lineWidth;
    NSUInteger pattern = (style & 0xF00);
    if (pattern == DHTextLineStylePatternSolid) {
        CGContextSetLineDash(context, phase, NULL, 0);
    } else if (pattern == DHTextLineStylePatternDot) {
        CGFloat lengths[2] = {width * dot, width * space};
        CGContextSetLineDash(context, phase, lengths, 2);
    } else if (pattern == DHTextLineStylePatternDash) {
        CGFloat lengths[2] = {width * dash, width * space};
        CGContextSetLineDash(context, phase, lengths, 2);
    } else if (pattern == DHTextLineStylePatternDashDot) {
        CGFloat lengths[4] = {width * dash, width * space, width * dot, width * space};
        CGContextSetLineDash(context, phase, lengths, 4);
    } else if (pattern == DHTextLineStylePatternDashDotDot) {
        CGFloat lengths[6] = {width * dash, width * space, width * dot, width * space, width * dot, width * space};
        CGContextSetLineDash(context, phase, lengths, 6);
    } else if (pattern == DHTextLineStylePatternCircleDot) {
        CGFloat lengths[2] = {width * 0, width * 3};
        CGContextSetLineDash(context, phase, lengths, 2);
        CGContextSetLineCap(context, kCGLineCapRound);
        CGContextSetLineJoin(context, kCGLineJoinRound);
    }
}

#pragma mark - Draw Shadow
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


#pragma mark - Draw Text
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

#pragma mark - Draw Attachment
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

#pragma mark - Draw Decoration
- (void) drawDecorationInContext:(CGContextRef)context
                            size:(CGSize)size
                        position:(CGPoint)position
                            type:(DHTextDecorationType)type
{
    if (type == DHTextDecorationTypeUnderLine && self.needToDrawUnderline == NO) {
        return ;
    }
    CGContextSaveGState(context);
    CFArrayRef runs = CTLineGetGlyphRuns(self.ctLine);
    CFIndex runCount = CFArrayGetCount(runs);
    
    CGFloat xHeight, underlinePosition, lineThickness;
    [self getXHeight:&xHeight underlinePosition:&underlinePosition lineThickness:&lineThickness forRuns:runs];
    
    for (CFIndex runNo = 0; runNo < runCount; runNo++) {
        CTRunRef run = CFArrayGetValueAtIndex(runs, runNo);
        CFIndex glyphCount = CTRunGetGlyphCount(run);
        if (glyphCount == 0) return;
        
        NSDictionary *attributes = (id)CTRunGetAttributes(run);
        DHTextDecoration *underline = attributes[DHTextUnderlineAttributeName];
        DHTextDecoration *strikeThrough = attributes[DHTextStrikeThroughAttributeName];
        if (type == DHTextDecorationTypeUnderLine && underline == nil) continue;
        if (type == DHTextDecorationTypeStrikeThrough && underline == nil) continue;
        CFRange runRange = CTRunGetStringRange(run);
        if (runRange.location == kCFNotFound || runRange.length == 0) continue;
        if (runRange.location + runRange.length > self.range.location + self.range.length) continue;
        
        CGPoint underlineStart, strikeThroughStart;
        CGFloat length;
        underlineStart.y = size.height - self.position.y + underlinePosition;
        strikeThroughStart.y = self.position.y + xHeight / 2;
        CGPoint runPosition = CGPointZero;
        CTRunGetPositions(run, CFRangeMake(0, 0), &runPosition);
        underlineStart.x = strikeThroughStart.x = runPosition.x + self.position.x;
        length = CTRunGetTypographicBounds(run, CFRangeMake(0, 0), NULL, NULL, NULL);
        
        if (type == DHTextDecorationTypeUnderLine) {
            CGColorRef color = underline.color.CGColor;
            if (color == NULL) {
                color = (__bridge CGColorRef)(attributes[(id)kCTForegroundColorAttributeName]);
                color = [DHTextUtils defaultColor].CGColor;
            }
            CGFloat thickness = underline.width ? [underline.width doubleValue] : lineThickness;
            DHTextShadow *shadow = underline.shadow;
            while (shadow) {
                if (!shadow.color) {
                    shadow = shadow.subShadow;
                    continue;
                }
                CGFloat offsetAlterX = size.width + 0xFFFF;
                CGContextSaveGState(context); {
                    CGSize offset = shadow.offset;
                    offset.width -= offsetAlterX;
                    CGContextSaveGState(context); {
                        CGContextSetShadowWithColor(context, offset, shadow.radius, [shadow.color CGColor]);
                        CGContextSetBlendMode(context, shadow.blendMode);
                        CGContextTranslateCTM(context, offsetAlterX, 0);
                        [self drawLineInContext:context length:length thickness:thickness lineStyle:underline.style start:underlineStart color:color];
                    }CGContextRestoreGState(context);
                } CGContextRestoreGState(context);
                shadow = shadow.subShadow;
            }
            [self drawLineInContext:context length:length thickness:thickness lineStyle:underline.style start:underlineStart color:color];
        }
    }
    CGContextRestoreGState(context);
}

- (void) drawLineInContext:(CGContextRef) context
                    length:(CGFloat) length
                 thickness:(CGFloat) thickness
                 lineStyle:(DHTextLineStyle)style
                     start:(CGPoint)startPoint
                     color:(CGColorRef)color
{
    NSUInteger baseStyle = style & 0xFF;
    if (baseStyle == 0) return;
    
    CGContextSaveGState(context); {
        CGFloat x1, x2, y, lineWidth;
        x1 = [DHTextUtils CGFloatPixelRound:startPoint.x];
        x2 = [DHTextUtils CGFloatPixelRound:startPoint.x + length];
        lineWidth = (baseStyle == DHTextLineStyleThick) ? thickness * 2 : thickness;
        
        CGFloat linePixel = [DHTextUtils CGFloatToPixel:lineWidth];
        if (fabs(linePixel - floor(linePixel)) < 0.1) {
            int iPixel = linePixel;
            if (iPixel == 0 || (iPixel % 2) != 0) {
                y = [DHTextUtils CGFloatPixelHalf:startPoint.y];
            } else {
                y = [DHTextUtils CGFloatPixelFloor:startPoint.y];
            }
        } else {
            y = startPoint.y;
        }
        CGContextSetStrokeColorWithColor(context, color);
        [self updateLinePatternForStyle:style lineWidth:thickness inContext:context phase:startPoint.x];
        CGContextSetLineWidth(context, lineWidth);
        if (baseStyle == DHTextLineStyleSingle || baseStyle == DHTextLineStyleThick) {
            CGContextMoveToPoint(context, x1, y);
            CGContextAddLineToPoint(context, x2, y);
            CGContextStrokePath(context);
        } else if (baseStyle == DHTextLineStyleDouble) {
            CGContextMoveToPoint(context, x1, y - lineWidth);
            CGContextAddLineToPoint(context, x2, y - lineWidth);
            CGContextStrokePath(context);
            CGContextMoveToPoint(context, x1, y + lineWidth);
            CGContextAddLineToPoint(context, x2, y + lineWidth);
            CGContextStrokePath(context);
        }
    }CGContextRestoreGState(context);
}

- (void) getXHeight:(CGFloat *)xHeight
  underlinePosition:(CGFloat *)underlinePosition
      lineThickness:(CGFloat *)lineThickness
            forRuns:(CFArrayRef)runs
{
    CGFloat maxXHeight = 0;
    CGFloat maxUnderlinePos = 0;
    CGFloat maxLineThickness = 0;
    CFIndex runCount = CFArrayGetCount(runs);
    for (CFIndex i = 0; i < runCount; i++) {
        CTRunRef run = CFArrayGetValueAtIndex(runs, i);
        CFDictionaryRef attributes = CTRunGetAttributes(run);
        if (attributes) {
            CTFontRef font = CFDictionaryGetValue(attributes, kCTFontAttributeName);
            if (font) {
                CGFloat xHeight = CTFontGetXHeight(font);
                maxXHeight = MAX(maxXHeight, xHeight);
                CGFloat underlinePos = CTFontGetUnderlinePosition(font);
                maxUnderlinePos = MIN(maxUnderlinePos, underlinePos);
                CGFloat lineThickness = CTFontGetUnderlineThickness(font);
                maxLineThickness = MAX(maxLineThickness, lineThickness);
            }
        }
    }
    if (xHeight) *xHeight = maxXHeight;
    if (underlinePosition) *underlinePosition = maxUnderlinePos;
    if (lineThickness) *lineThickness = maxLineThickness;
}
@end
