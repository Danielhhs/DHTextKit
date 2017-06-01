//
//  DHTextContainer.h
//  DHTextKit
//
//  Created by Huang Hongsen on 17/5/24.
//  Copyright © 2017年 Huang Hongsen. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "DHTextAttribute.h"

@interface DHTextContainer : NSObject

+ (nullable DHTextContainer *) containerWithSize:(CGSize)size;

+ (nullable DHTextContainer *) containerWithSize:(CGSize)size
                                          insets:(UIEdgeInsets)insets;

+ (nullable DHTextContainer *) containerWithPath:(nonnull UIBezierPath *)path;

@property (nonatomic) CGSize size;
@property (nonatomic) UIEdgeInsets insets;
@property (nonatomic, strong, nullable) UIBezierPath *path;
@property (nonatomic) DHTextTruncationType truncationType;
@property (nonatomic) NSInteger maximumNumberOfRows;
@property (nonatomic, strong, nullable) NSAttributedString *truncationToken;    //Truncation place holder, if nil, use "..."

@end
