//
//  DHLabel.m
//  DHTextKit
//
//  Created by Huang Hongsen on 17/5/22.
//  Copyright © 2017年 Huang Hongsen. All rights reserved.
//

#import "DHLabel.h"
#import <CoreText/CoreText.h>
#import "DHTextLayout.h"
@interface DHLabel ()
@property (nonatomic, strong) DHTextLayout *layout;
@end

@implementation DHLabel

- (void)drawRect:(CGRect)rect {
    [self.layout drawInContext:UIGraphicsGetCurrentContext()
                          size:self.bounds.size
                         point:CGPointZero
                          view:self
                         layer:nil
                        cancel:nil];
}

- (NSAttributedString *) attributedStringToDraw
{
    if (self.attribtuedText) {
        return self.attribtuedText;
    } else {
        NSDictionary *attributes = [self textAttributes];
        if (self.text == nil) {
            return nil;
        }
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

- (void) setAttribtuedText:(NSAttributedString *)attribtuedText
{
    _attribtuedText = attribtuedText;
    self.layout = [DHTextLayout layoutWithContainerSize:self.bounds.size text:attribtuedText];
    [self setNeedsDisplay];
}

- (void) setBounds:(CGRect)bounds
{
    [super setBounds:bounds];
    self.layout = [DHTextLayout layoutWithContainerSize:self.bounds.size text:[self attributedStringToDraw]];
    [self setNeedsDisplay];
}

- (void) setFrame:(CGRect)frame
{
    [super setFrame:frame];
    self.layout = [DHTextLayout layoutWithContainerSize:self.bounds.size text:[self attributedStringToDraw]];
    [self setNeedsDisplay];
}

@end
