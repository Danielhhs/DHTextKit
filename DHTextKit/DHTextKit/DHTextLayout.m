//
//  DHTextLayout.m
//  DHTextKit
//
//  Created by Huang Hongsen on 17/5/24.
//  Copyright © 2017年 Huang Hongsen. All rights reserved.
//

#import "DHTextLayout.h"
#import "DHTextUtils.h"

typedef struct {
    CGFloat head;
    CGFloat foot;
} DHRowEdge;

@interface DHTextLayout ()
@property (nonatomic, strong, readwrite) NSArray <DHTextLine *> *lines;
@property (nonatomic, strong, readwrite) NSAttributedString *text;
@property (nonatomic, strong, readwrite) DHTextContainer *container;
@property (nonatomic, readwrite) NSRange range;
@property (nonatomic, readwrite) CTFramesetterRef frameSetter;
@property (nonatomic, readwrite) CTFrameRef frame;
@property (nonatomic, strong, readwrite) NSArray<DHTextAttachment *> *attachments;
@property (nonatomic, strong, readwrite) NSArray<NSValue *> *attachmentRanges;
@property (nonatomic, strong, readwrite) NSArray<NSValue *> *attachmentRects;
@property (nonatomic, readwrite) CGRect textBoundingRect;
@property (nonatomic, strong) DHTextLine *truncatedLine;
@end

@implementation DHTextLayout

+ (DHTextLayout *) layoutWithContainerSize:(CGSize)size text:(NSAttributedString *)text
{
    DHTextContainer *container = [DHTextContainer containerWithSize:size];
    return [DHTextLayout layoutWithContainer:container text:text];
}

+ (DHTextLayout *) layoutWithContainer:(DHTextContainer *)container
                                  text:(NSAttributedString *)text
{
    if (text == nil) {
        return nil;
    }
    return [DHTextLayout layoutWithContainer:container text:text range:NSMakeRange(0, [text length])];
}

+ (DHTextLayout *) layoutWithContainer:(DHTextContainer *)container text:(NSAttributedString *)text range:(NSRange)range
{
    DHTextLayout *layout = [[DHTextLayout alloc] init];
    layout.text = text;
    layout.container = container;
    layout.range = range;
    layout.maximumNumberOfRows = container.maximumNumberOfRows;
    [layout setup];
    return layout;
}

- (void) setup
{
    CGPathRef path = [self pathForRendering];
    CGRect pathBox = CGPathGetBoundingBox(path);
    self.frameSetter = CTFramesetterCreateWithAttributedString((CFAttributedStringRef)self.text);
    self.frame = CTFramesetterCreateFrame(self.frameSetter, CFRangeMake(self.range.location, self.range.length), path, NULL);
    
    CFArrayRef ctLines = CTFrameGetLines(self.frame);
    NSMutableArray *lines = [self setupLinesWithPathBox:pathBox ctLines:ctLines];
    [self truncateWithCTLines:ctLines lines:lines path:path];
    
    self.lines = lines;
    [self updateBounds];
}

- (CGPathRef) pathForRendering
{
    if (self.container.path) {
        return self.container.path.CGPath;
    } else {
        CGRect rect = CGRectMake(0, 0, self.container.size.width, self.container.size.height);
        rect = UIEdgeInsetsInsetRect(rect, self.container.insets);
        UIBezierPath *path = [UIBezierPath bezierPathWithRect:rect];
        return path.CGPath;
    }
}

- (NSMutableArray *) setupLinesWithPathBox:(CGRect)pathBox
                                   ctLines:(CFArrayRef)ctLines
{
    CFIndex numberOfLines = CFArrayGetCount(ctLines);
    NSMutableArray *lines = [NSMutableArray array];
    CGPoint *lineOrigins = malloc(sizeof(CGPoint) * numberOfLines);
    CTFrameGetLineOrigins(self.frame, CFRangeMake(0, numberOfLines), lineOrigins);
    for (NSUInteger lineNo = 0; lineNo < numberOfLines; lineNo++) {
        CTLineRef ctLine = CFArrayGetValueAtIndex(ctLines, lineNo);
        CGPoint lineOrigin = lineOrigins[lineNo];
        
        //Translate lineOrigin to UIKit Coordinate system
        CGPoint position;
        position.x = pathBox.origin.x + lineOrigin.x;
        position.y = pathBox.origin.y + pathBox.size.height - lineOrigin.y;
        DHTextLine *line = [DHTextLine lineWithCTLine:ctLine position:position];
        line.row = lineNo;
        line.index = lineNo;
        [lines addObject:line];
    }
    return lines;
}

- (void) truncateWithCTLines:(CFArrayRef)ctLines
                       lines:(NSMutableArray *)lines
                        path:(CGPathRef)path
{
    CFIndex numberOfLines = CFArrayGetCount(ctLines);
    BOOL needTruncation;
    DHTextLine *truncationLine;
    if (numberOfLines > 0) {
        if (self.maximumNumberOfRows > 0) {
            if (numberOfLines > self.maximumNumberOfRows) {
                needTruncation = YES;
                numberOfLines = self.maximumNumberOfRows;
                do {
                    DHTextLine *line = [lines lastObject];
                    if (!line) break;
                    if (line.row < numberOfLines) break;
                    [lines removeLastObject];
                } while(1);
            }
        }
        DHTextLine *lastLine = [lines lastObject];
        if (!needTruncation && lastLine.range.location + lastLine.range.length < [self.text length]) {
            needTruncation = YES;
        }
        NSRange visibleRange = [DHTextUtils NSRangeFromCFRange:CTFrameGetVisibleStringRange(self.frame)];
        if (needTruncation) {
            DHTextLine *lastLine = [lines lastObject];
            NSRange lastRange = lastLine.range;
            visibleRange.length = lastRange.location + lastRange.length - visibleRange.location;
            //Create truncate line
            NSAttributedString *truncationToken;
            if (self.container.truncationType != DHTextTruncationTypeNone) {
                CTLineRef truncationTokenLine = NULL;
                if (self.container.truncationToken) {
                    truncationToken = self.container.truncationToken;
                    truncationTokenLine = CTLineCreateWithAttributedString((CFAttributedStringRef)truncationToken);
                } else {
                    CFArrayRef runs = CTLineGetGlyphRuns(lastLine.ctLine);
                    NSUInteger runCount = CFArrayGetCount(runs);
                    NSMutableDictionary *attributes = nil;
                    if (runCount > 0) {
                        CTRunRef lastRun = CFArrayGetValueAtIndex(runs, runCount - 1);
                        attributes = (id)CTRunGetAttributes(lastRun);
                        attributes = attributes ? [attributes mutableCopy] : [NSMutableDictionary dictionary];
                        [attributes removeObjectsForKeys:@[DHTextAttachmentAttributeName, NSAttachmentAttributeName, (id)kCTRunDelegateAttributeName]];
                        CTFontRef font = (__bridge CFTypeRef)(attributes[(id)kCTFontAttributeName]);
                        CGFloat fontSize = font ? CTFontGetSize(font) : 12.f;
                        UIFont *uiFont = [UIFont systemFontOfSize:fontSize * 0.9];
                        font = CTFontCreateWithName((CFStringRef)uiFont.fontName, uiFont.pointSize, NULL);
                        if (font) {
                            attributes[(id)kCTFontAttributeName] = (__bridge id)font;
                            uiFont = nil;
                            CFRelease(font);
                        }
                        CGColorRef color = (__bridge CGColorRef)(attributes[(id)kCTForegroundColorAttributeName]);
                        if (color && CFGetTypeID(color) == CGColorGetTypeID() && CGColorGetAlpha(color) == 0) {     //If alpha is 0, remove color
                            [attributes removeObjectForKey:(id)kCTForegroundColorAttributeName];
                        }
                        if (attributes == nil) {
                            attributes = [NSMutableDictionary dictionary];
                        }
                    }
                    truncationToken = [[NSAttributedString alloc] initWithString:DHTextTruncationToken attributes:attributes];
                    truncationTokenLine = CTLineCreateWithAttributedString((CFAttributedStringRef)truncationToken);
                }
                if (truncationTokenLine) {
                    CTLineTruncationType type = [DHTextUtils ctLineTruncationTypeFromDHTurncationType:self.container.truncationType];
                    NSMutableAttributedString *lastLineText = [[self.text attributedSubstringFromRange:lastLine.range] mutableCopy];
                    [lastLineText appendAttributedString:truncationToken];
                    CTLineRef lastLineExtend = CTLineCreateWithAttributedString((CFAttributedStringRef)lastLineText);
                    if (lastLineExtend) {
                        CGFloat truncatedWidth = [lastLine width];
                        CGRect cgPathRect = CGRectZero;
                        if (CGPathIsRect(path, &cgPathRect)) {
                            truncatedWidth = cgPathRect.size.width;
                        }
                        CTLineRef ctTruncatedLine = CTLineCreateTruncatedLine(lastLineExtend, truncatedWidth, type, truncationTokenLine);
                        CFRelease(lastLineExtend);
                        if (ctTruncatedLine) {
                            truncationLine = [DHTextLine lineWithCTLine:ctTruncatedLine position:lastLine.position];
                            truncationLine.index = lastLine.index;
                            truncationLine.row = lastLine.index;
                            self.truncatedLine = truncationLine;
                            CFRelease(ctTruncatedLine);
                        }
                    }
                    CFRelease(truncationTokenLine);
                }
                
            }
        }
    }
}

- (void) updateBounds
{
    CGRect textBoundingRect = CGRectZero;
    for (int i = 0; i < [self.lines count]; i++) {
        DHTextLine *line = self.lines[i];
        textBoundingRect = CGRectUnion(textBoundingRect, line.bounds);
    }
    UIEdgeInsets insets = self.container.insets;
    UIEdgeInsets insetsInverse = UIEdgeInsetsMake(-insets.top, -insets.left, -insets.bottom, -insets.right);
    textBoundingRect = UIEdgeInsetsInsetRect(textBoundingRect, insetsInverse);
    self.textBoundingRect = textBoundingRect;
}

#pragma mark - Drawing
- (void) drawInContext:(CGContextRef)context
                  size:(CGSize)size
                 point:(CGPoint)point
                  view:(UIView *)view
                 layer:(CALayer *)layer
                cancel:(BOOL (^)(void))cancel
{
    CGContextSaveGState(context);
    CGContextTranslateCTM(context, point.x, point.y);
    CGContextTranslateCTM(context, 0, size.height);
    CGContextScaleCTM(context, 1, -1);
    for (int i = 0; i < [self.lines count]; i++) {
        DHTextLine *line = self.lines[i];
        if (self.truncatedLine && line.index == self.truncatedLine.index) {
            line = self.truncatedLine;
        }
        [line drawInContext:context size:size position:point inView:view orLayer:layer];
    }
}

@end
