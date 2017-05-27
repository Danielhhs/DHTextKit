//
//  DHTextLayout.h
//  DHTextKit
//
//  Created by Huang Hongsen on 17/5/24.
//  Copyright © 2017年 Huang Hongsen. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreText/CoreText.h>
#import <UIKit/UIKit.h>
#import "DHTextLine.h"
#import "DHTextContainer.h"
#import "DHTextAttachment.h"

@interface DHTextLayout : NSObject

+ (nullable DHTextLayout *) layoutWithContainerSize:(CGSize) size
                                      text:(nonnull NSAttributedString *) text;

+ (nullable DHTextLayout *) layoutWithContainer:(nonnull DHTextContainer *)container
                                  text:(nonnull NSAttributedString *) text;

+ (nullable DHTextLayout *) layoutWithContainer:(nonnull DHTextContainer *)container
                                  text:(nonnull NSAttributedString *)text
                                 range:(NSRange)range;

@property (nonatomic, strong, readonly, nullable) NSArray <DHTextLine *> *lines;
@property (nonatomic, readonly) CGRect textBoundingRect;

- (void) drawInContext:(nullable CGContextRef)context
                  size:(CGSize)size
                 point:(CGPoint)point
                  view:(nullable UIView *)view
                 layer:(nullable CALayer *)layer
                cancel:(nullable BOOL (^)(void))cancel;

@end
