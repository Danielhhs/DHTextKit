//
//  DHTextBorder.h
//  DHTextKit
//
//  Created by Huang Hongsen on 17/5/31.
//  Copyright © 2017年 Huang Hongsen. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "DHTextAttribute.h"
#import "DHTextShadow.h"
@interface DHTextBorder : NSObject
@property (nonatomic) DHTextLineStyle lineStyle;
@property (nonatomic) CGFloat strokeWidth;
@property (nullable, nonatomic, strong) UIColor *strokeColor;
@property (nonatomic) CGLineJoin lineJoin;
@property (nonatomic) UIEdgeInsets insets;
@property (nonatomic) CGFloat cornerRadius;
@property (nullable, nonatomic, strong) DHTextShadow *shadow;
@property (nullable, nonatomic, strong) UIColor *fillColor;

+ (nullable DHTextBorder *) borderWithLineStyle:(DHTextLineStyle)lineStyle
                                    strokeWidth:(CGFloat)strokeWidth
                                    strokeColor:(nullable UIColor *)strokeColor;
@end
