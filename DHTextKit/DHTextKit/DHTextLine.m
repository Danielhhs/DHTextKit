//
//  DHTextLine.m
//  DHTextKit
//
//  Created by Huang Hongsen on 17/5/24.
//  Copyright © 2017年 Huang Hongsen. All rights reserved.
//

#import "DHTextLine.h"

@interface DHTextLine ()
@property (nonatomic, readwrite) CTLineRef line;
@property (nonatomic, readwrite) CGPoint position;
@end

@implementation DHTextLine

+ (DHTextLine *) lineWithCTLine:(CTLineRef)ctLine position:(CGPoint)position
{
    DHTextLine *line = [[DHTextLine alloc] init];
    line.line = ctLine;
    line.position = position;
    return line;
}

- (void) drawInContext:(CGContextRef)context
                  size:(CGSize)size
              position:(CGPoint)position
{
    CGPoint lineOrigin;
    lineOrigin.x = self.position.x;
    lineOrigin.y = self.position.y;
    CFArrayRef runs = CTLineGetGlyphRuns(self.line);
    CFIndex numberOfRuns = CFArrayGetCount(runs);
    for (CFIndex runNo = 0; runNo < numberOfRuns; runNo++) {
        CTRunRef run = CFArrayGetValueAtIndex(runs, runNo);
        CGContextSetTextMatrix(NULL, CGAffineTransformIdentity);
        CGContextSetTextPosition(context, lineOrigin.x, lineOrigin.y);
        CTRunDraw(run, context, CFRangeMake(0, 0));
    }
}

@end
