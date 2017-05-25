//
//  DHTextContainer.h
//  DHTextKit
//
//  Created by Huang Hongsen on 17/5/24.
//  Copyright © 2017年 Huang Hongsen. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface DHTextContainer : NSObject

+ (nullable DHTextContainer *) containerWithSize:(CGSize)size;

+ (nullable DHTextContainer *) containerWithSize:(CGSize)size
                                          insets:(UIEdgeInsets)insets;

+ (nullable DHTextContainer *) containerWithPath:(nonnull UIBezierPath *)path;

@property (nonatomic, readonly) CGSize size;
@property (nonatomic, readonly) UIEdgeInsets insets;
@property (nonatomic, strong, readonly, nullable) UIBezierPath *path;

@end
