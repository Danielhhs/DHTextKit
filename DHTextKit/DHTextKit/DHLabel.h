//
//  DHLabel.h
//  DHTextKit
//
//  Created by Huang Hongsen on 17/5/22.
//  Copyright © 2017年 Huang Hongsen. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DHLabel : UIView

@property (nonatomic, strong) NSString *text;
@property (nonatomic, strong) NSAttributedString *attribtuedText;

@property (nonatomic, strong) UIFont *font;
@property (nonatomic, strong) UIColor *textColor;
@property (nonatomic, strong) UIColor *strokeColor;
@property (nonatomic, strong) UIColor *fillColor;
@property (nonatomic, strong) UIColor *shadowColor;
@property (nonatomic) CGFloat shadowOffset;
@property (nonatomic) NSInteger maximumNumberOfRows;

+ (CGRect) textBoundingRectForAttributedString:(NSAttributedString *)attributedString
                                      maxWidth:(CGFloat)width;

+ (CGRect) textBoundingRectForAttributedString:(NSAttributedString *)attributedString
                                       maxSize:(CGSize)size;

@end
