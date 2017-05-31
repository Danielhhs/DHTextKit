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
#import "DHAsyncDisplayLayer.h"

static const CGFloat kMaxLabelHeight = 1000000;

@interface DHLabel ()<DHAsyncDisplayLayerDelegate>
@property (nonatomic, strong) DHTextLayout *layout;
@property (nonatomic) BOOL needsToUpdateLayout;
@end

@implementation DHLabel

#pragma mark - Initialization
- (instancetype) initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setup];
    }
    return self;
}

- (void) awakeFromNib
{
    [super awakeFromNib];
    [self setup];
}

- (void) setup
{
    DHAsyncDisplayLayer *layer = (DHAsyncDisplayLayer *)self.layer;
    layer.displayDelegate = self;
    self.backgroundColor = [UIColor clearColor];
    self.shadowColor = [UIColor blackColor];
    self.textColor = [UIColor blackColor];
    self.shadowOffset = 5;
}

+ (Class) layerClass
{
    return [DHAsyncDisplayLayer class];
}
#pragma mark - Update Properties
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
    [self setNeedsToUpdateLayout];
}

- (void) setFrame:(CGRect)frame
{
    [super setFrame:frame];
    [self setNeedsToUpdateLayout];
}

- (void) setNeedsToUpdateLayout
{
    self.needsToUpdateLayout = YES;
    [self setNeedsDisplay];
}

- (void) updateLayoutIfNeeds
{
    if (self.needsToUpdateLayout) {
        self.needsToUpdateLayout = NO;
        self.layout = [DHTextLayout layoutWithContainerSize:self.bounds.size text:[self attributedStringToDraw]];
        [self setNeedsDisplay];
    }
}

- (void) setNeedsDisplay
{
    [super setNeedsDisplay];
    [self.layer setNeedsDisplay];
}

- (void) sizeToFit
{
    self.bounds = self.layout.textBoundingRect;
}

+ (CGRect) textBoundingRectForAttributedString:(NSAttributedString *)attributedString
                                      maxWidth:(CGFloat)width;
{
    return [DHLabel textBoundingRectForAttributedString:attributedString
                                                maxSize:CGSizeMake(width, kMaxLabelHeight)];
}

+ (CGRect) textBoundingRectForAttributedString:(NSAttributedString *)attributedString maxSize:(CGSize)size
{
    DHTextLayout *layout = [DHTextLayout layoutWithContainerSize:size
                                                         text:attributedString];
    return layout.textBoundingRect;
}

#pragma mark - Drawing
//- (void)drawRect:(CGRect)rect {
//    [self.layout drawInContext:UIGraphicsGetCurrentContext()
//                          size:self.bounds.size
//                         point:CGPointZero
//                          view:self
//                         layer:nil
//                        cancel:nil];
//}

#pragma mark - DHAsyncDisplayLayerDelegate
- (DHAsyncDisplayTask *) asyncDisplayTask
{
    DHAsyncDisplayTask *task = [[DHAsyncDisplayTask alloc] init];
    task.willDisplay = ^(CALayer *layer) {
        
    };
    
    task.display = ^(CGContextRef context, CGSize size) {
        [self updateLayoutIfNeeds];
        [self.layout drawInContext:context size:size point:CGPointZero view:self layer:self.layer cancel:nil];
    };
    
    task.didDisplay = nil;
    return task;
}
@end
