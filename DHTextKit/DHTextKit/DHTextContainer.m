//
//  DHTextContainer.m
//  DHTextKit
//
//  Created by Huang Hongsen on 17/5/24.
//  Copyright © 2017年 Huang Hongsen. All rights reserved.
//

#import "DHTextContainer.h"

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

- (void) setSize:(CGSize)size
{
    _size = size;
}

- (id) copyWithZone:(NSZone *)zone
{
    DHTextContainer *container = [DHTextContainer new];
    container.size = self.size;
    container.insets = self.insets;
    container.path = self.path;
    container.truncationType = self.truncationType;
    container.maximumNumberOfRows = self.maximumNumberOfRows;
    container.truncationToken = [self.truncationToken copyWithZone:zone];
    return container;
}
@end
