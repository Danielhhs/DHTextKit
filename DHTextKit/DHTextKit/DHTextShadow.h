//
//  DHTextShadow.h
//  DHTextKit
//
//  Created by Huang Hongsen on 17/5/25.
//  Copyright © 2017年 Huang Hongsen. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface DHTextShadow : NSObject<NSCopying>

+ (DHTextShadow *) shadowWithColor:(UIColor *)color offset:(CGSize)offset radius:(CGFloat)radius;
+ (DHTextShadow *) shadowWithNSShadow:(NSShadow *)nsShadow;

@property (nonatomic, strong) UIColor *color;
@property (nonatomic) CGSize offset;
@property (nonatomic) CGFloat radius;
@property (nonatomic) CGBlendMode blendMode;
@property (nonatomic, strong) DHTextShadow *subShadow;
@property (nonatomic, strong, readonly) NSShadow *nsShadow;

@end
