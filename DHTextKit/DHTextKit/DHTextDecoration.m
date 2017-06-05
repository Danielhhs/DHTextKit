//
//  DHTextDecoration.m
//  DHTextKit
//
//  Created by Huang Hongsen on 17/6/5.
//  Copyright © 2017年 Huang Hongsen. All rights reserved.
//

#import "DHTextDecoration.h"

@implementation DHTextDecoration

+ (DHTextDecoration *) decorationWithStyle:(DHTextLineStyle)style
{
    DHTextDecoration *decoration = [[DHTextDecoration alloc] init];
    decoration.style = style;
    return decoration;
}

+ (DHTextDecoration *) decorationWithStyle:(DHTextLineStyle)style width:(NSNumber *)width color:(UIColor *)color
{
    DHTextDecoration *decoration = [[DHTextDecoration alloc] init];
    decoration.style = style;
    decoration.width = width;
    decoration.color = color;
    return decoration;
}

@end
