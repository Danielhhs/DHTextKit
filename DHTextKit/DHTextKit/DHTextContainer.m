//
//  DHTextContainer.m
//  DHTextKit
//
//  Created by Huang Hongsen on 17/5/24.
//  Copyright © 2017年 Huang Hongsen. All rights reserved.
//

#import "DHTextContainer.h"

@interface DHTextContainer ()
@property (nonatomic, readwrite) CGSize size;
@property (nonatomic, readwrite) UIEdgeInsets insets;
@property (nonatomic, readwrite, strong) UIBezierPath *path;
@end

@implementation DHTextContainer

+ (DHTextContainer *) containerWithPath:(UIBezierPath *)path
{
    DHTextContainer *container = [[DHTextContainer alloc] init];
    container.path = path;
    return container;
}

+ (DHTextContainer *) containerWithSize:(CGSize)size
{
    DHTextContainer *container = [[DHTextContainer alloc] init];
    container.size = size;
    container.insets = UIEdgeInsetsZero;
    return container;
}

+ (DHTextContainer *) containerWithSize:(CGSize)size insets:(UIEdgeInsets)insets
{
    DHTextContainer *container = [[DHTextContainer alloc] init];
    container.size = size;
    container.insets = insets;
    return container;
}

@end
