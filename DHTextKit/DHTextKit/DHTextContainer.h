//
//  DHTextContainer.h
//  DHTextKit
//
//  Created by Huang Hongsen on 17/5/23.
//  Copyright © 2017年 Huang Hongsen. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface DHTextContainer : NSObject

+ (DHTextContainer *) containerWithSize:(CGSize)size;
+ (DHTextContainer *) containerWithSize:(CGSize)size
                          contentInsets:(UIEdgeInsets)contentInsets;
+ (DHTextContainer *) containerWithPath:(UIBezierPath *)path;

@property (nonatomic) CGSize size;
@property (nonatomic) UIEdgeInsets contentInsets;
@property (nonatomic, strong) UIBezierPath *path;
@property (nonatomic, strong, readonly) NSArray <UIBezierPath *>* exclusionPaths;

@end
