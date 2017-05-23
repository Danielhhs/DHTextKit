//
//  DHTextContainer.m
//  DHTextKit
//
//  Created by Huang Hongsen on 17/5/23.
//  Copyright © 2017年 Huang Hongsen. All rights reserved.
//

#import "DHTextContainer.h"

@interface DHTextContainer ()
@end

@implementation DHTextContainer

+ (DHTextContainer *) containerWithSize:(CGSize)size
{
    DHTextContainer *container = [[DHTextContainer alloc] init];
    container.size = size;
    return container;
}

+ (DHTextContainer *) containerWithPath:(UIBezierPath *)path
{
    DHTextContainer *container = [[DHTextContainer alloc] init];
    container.path = path;
    return container;
}

+ (DHTextContainer *) containerWithSize:(CGSize)size contentInsets:(UIEdgeInsets)contentInsets
{
    DHTextContainer *container = [[DHTextContainer alloc] init];
    container.size = size;
    container.contentInsets = contentInsets;
    return container;
}

@end
