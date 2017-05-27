//
//  DHTextLayout.m
//  DHTextKit
//
//  Created by Huang Hongsen on 17/5/24.
//  Copyright © 2017年 Huang Hongsen. All rights reserved.
//

#import "DHTextLayout.h"

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
    CFIndex numberOfLines = CFArrayGetCount(ctLines);
    NSMutableArray *lines = [NSMutableArray array];
    CGPoint *lineOrigins = malloc(sizeof(CGPoint) * numberOfLines);
    CTFrameGetLineOrigins(self.frame, CFRangeMake(0, numberOfLines), lineOrigins);
    CGRect boundingRect = CGRectZero;
    for (CFIndex lineNo = 0; lineNo < numberOfLines; lineNo++) {
        CTLineRef ctLine = CFArrayGetValueAtIndex(ctLines, lineNo);
        CGPoint lineOrigin = lineOrigins[lineNo];
        
        //Translate lineOrigin to UIKit Coordinate system
        CGPoint position;
        position.x = pathBox.origin.x + lineOrigin.x;
        position.y = pathBox.origin.y + pathBox.size.height - lineOrigin.y;
        DHTextLine *line = [DHTextLine lineWithCTLine:ctLine position:position];
        [lines addObject:line];
        boundingRect = CGRectUnion(boundingRect, line.bounds);
    }
    self.textBoundingRect = boundingRect;
    self.lines = [lines copy];
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
        [line drawInContext:context size:size position:point inView:view orLayer:layer];
    }
}

@end
