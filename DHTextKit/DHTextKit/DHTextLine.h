//
//  DHTextLine.h
//  DHTextKit
//
//  Created by Huang Hongsen on 17/5/24.
//  Copyright © 2017年 Huang Hongsen. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreText/CoreText.h>
#import <UIKit/UIKit.h>
#import "DHTextAttachment.h"
@interface DHTextLine : NSObject

+ (DHTextLine *) lineWithCTLine:(CTLineRef)ctLine
                       position:(CGPoint)position;

- (void) drawInContext:(CGContextRef)context
                  size:(CGSize)size
              position:(CGPoint)position
                inView:(UIView *)view
               orLayer:(CALayer *)layer;

@property (nonatomic) CGPoint position;     //BaseLine position

@property (nonatomic, readonly) CTLineRef ctLine;
@property (nonatomic, readonly) NSRange range;
@property (nonatomic, readonly) NSUInteger index;
@property (nonatomic, readonly) NSUInteger row;
@property (nonatomic, readonly) CGRect bounds;
@property (nonatomic, readonly) CGSize size;
@property (nonatomic, readonly) CGFloat width;
@property (nonatomic, readonly) CGFloat height;
@property (nonatomic, readonly) CGFloat left;
@property (nonatomic, readonly) CGFloat right;
@property (nonatomic, readonly) CGFloat top;
@property (nonatomic, readonly) CGFloat bottom;

@property (nonatomic, readonly) CGFloat ascent;
@property (nonatomic, readonly) CGFloat descent;
@property (nonatomic, readonly) CGFloat leading;
@property (nonatomic, readonly) CGFloat lineWidth;
@property (nonatomic, readonly) CGFloat trailingWhiteSpaceWidth;

@property (nonatomic, strong, readonly) NSArray <DHTextAttachment *> *attachments;
@property (nonatomic, strong, readonly) NSArray <NSValue *> *attachmentRanges;  //NSValue wrapping NSRange
@property (nonatomic, strong, readonly) NSArray <NSValue *> *attachmentRects;   //NSValue wrapping CGRect
@end
