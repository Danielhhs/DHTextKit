//
//  DHTextBorder.m
//  DHTextKit
//
//  Created by Huang Hongsen on 17/5/31.
//  Copyright © 2017年 Huang Hongsen. All rights reserved.
//

#import "DHTextBorder.h"

@implementation DHTextBorder

+ (DHTextBorder *) borderWithLineStyle:(DHTextLineStyle)lineStyle
                           strokeWidth:(CGFloat)strokeWidth
                           strokeColor:(UIColor *)strokeColor
{
    DHTextBorder *border = [[DHTextBorder alloc] init];
    border.lineStyle = lineStyle;
    border.strokeWidth = strokeWidth;
    border.strokeColor = strokeColor;
    return border;
}

- (instancetype) init
{
    self = [super init];
    if (self) {
        _lineStyle = DHTextLineStyleSingle;
    }
    return self;
}

@end
