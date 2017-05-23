//
//  DHLabel.m
//  DHTextKit
//
//  Created by Huang Hongsen on 17/5/22.
//  Copyright © 2017年 Huang Hongsen. All rights reserved.
//

#import "DHLabel.h"
#import <CoreText/CoreText.h>

@interface DHLabel ()

@end

@implementation DHLabel

- (void)drawRect:(CGRect)rect {
    NSAttributedString *attrString = [self attributedStringToDraw];
    CGPathRef path = [UIBezierPath bezierPathWithRect:self.bounds].CGPath;
    CTFramesetterRef frameSetter = CTFramesetterCreateWithAttributedString((CFAttributedStringRef)attrString);
    CTFrameRef frame = CTFramesetterCreateFrame(frameSetter, CFRangeMake(0, [attrString length]), path, NULL);
    CFArrayRef lines = CTFrameGetLines(frame);
    CFIndex numberOfLines = CFArrayGetCount(lines);
    for (CFIndex i = 0; i < numberOfLines; i++) {
        CTLineRef line = CFArrayGetValueAtIndex(lines, i);
    
    }
}

- (NSAttributedString *) attributedStringToDraw
{
    if (self.attribtuedText) {
        return self.attribtuedText;
    } else {
        NSDictionary *attributes = [self textAttributes];
        NSAttributedString *attrStr = [[NSAttributedString alloc] initWithString:self.text
                                                                      attributes:attributes];
        return attrStr;
    }
}

- (NSDictionary *) textAttributes
{
    UIFont *font = (self.font != nil) ? self.font : [UIFont systemFontOfSize:16];
    UIColor *textColor = (self.textColor != nil) ? self.textColor : [UIColor blackColor];
    return @{NSFontAttributeName : font,
             NSForegroundColorAttributeName : textColor};
}

@end
