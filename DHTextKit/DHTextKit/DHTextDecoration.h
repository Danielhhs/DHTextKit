//
//  DHTextDecoration.h
//  DHTextKit
//
//  Created by Huang Hongsen on 17/6/5.
//  Copyright © 2017年 Huang Hongsen. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DHTextAttribute.h"
#import "DHTextShadow.h"
@interface DHTextDecoration : NSObject

+ (nullable DHTextDecoration *) decorationWithStyle:(DHTextLineStyle)style;
+ (nullable DHTextDecoration *) decorationWithStyle:(DHTextLineStyle)style width:(nullable NSNumber *)width color:(nullable UIColor *)color;

@property (nonatomic) DHTextLineStyle style;
@property (nonatomic, nullable, strong) NSNumber *width;
@property (nonatomic, nullable, strong) UIColor *color;
@property (nonatomic, nullable, strong) DHTextShadow *shadow;
@end
