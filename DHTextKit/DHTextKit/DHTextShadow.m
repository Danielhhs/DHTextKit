//
//  DHTextShadow.m
//  DHTextKit
//
//  Created by Huang Hongsen on 17/5/25.
//  Copyright © 2017年 Huang Hongsen. All rights reserved.
//

#import "DHTextShadow.h"

@interface DHTextShadow ()
@property (nonatomic, strong, readwrite) NSShadow *nsShadow;
@end

@implementation DHTextShadow
+ (DHTextShadow *) shadowWithNSShadow:(NSShadow *)nsShadow
{
    DHTextShadow *shadow = [[DHTextShadow alloc] init];
    shadow.offset = nsShadow.shadowOffset;
    shadow.radius = nsShadow.shadowBlurRadius;
    id color = nsShadow.shadowColor;
    if (color) {
        if (CGColorGetTypeID() == CFGetTypeID((__bridge CFTypeRef)(color))) {
            color = [UIColor colorWithCGColor:(__bridge CGColorRef)(color)];
        }
        if ([color isKindOfClass:[UIColor class]]) {
            shadow.color = color;
        }
    }
    return shadow;
}

+ (DHTextShadow *) shadowWithColor:(UIColor *)color offset:(CGSize)offset radius:(CGFloat)radius
{
    DHTextShadow *shadow = [[DHTextShadow alloc] init];
    shadow.offset = offset;
    shadow.color = color;
    shadow.radius = radius;
    return shadow;
}


- (id) copyWithZone:(NSZone *)zone
{
    DHTextShadow *copy = [[DHTextShadow alloc] init];
    copy.offset = self.offset;
    copy.color = self.color;
    copy.radius = self.radius;
    copy.blendMode = self.blendMode;
    copy.subShadow = self.subShadow;
    copy.nsShadow = self.nsShadow;
    return copy;
}
@end
