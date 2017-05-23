//
//  DHTextLayout.h
//  DHTextKit
//
//  Created by Huang Hongsen on 17/5/23.
//  Copyright © 2017年 Huang Hongsen. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DHTextLine.h"
#import "DHTextContainer.h"

@interface DHTextLayout : NSObject

+ (DHTextLayout *) textLayoutWithContainerSize:(CGSize)size
                                          text:(NSAttributedString *)attributedText;

+ (DHTextLayout *) textLayoutWithContainer:(DHTextContainer *)container
                                      text:(NSAttributedString *)attributedText;

@property (nonatomic, strong) NSAttributedString *attributedText;
@property (nonatomic) CGSize size;
@property (nonatomic) UIEdgeInsets insets;
@property (nonatomic, strong) UIBezierPath *path;

@property (nonatomic, strong) NSArray<DHTextLine *> *lines;

@end
