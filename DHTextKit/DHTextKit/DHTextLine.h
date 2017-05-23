//
//  DHTextLine.h
//  DHTextKit
//
//  Created by Huang Hongsen on 17/5/23.
//  Copyright © 2017年 Huang Hongsen. All rights reserved.
//

#import <CoreText/CoreText.h>
#import <Foundation/Foundation.h>
#import "DHTextAttachment.h"

@interface DHTextLine : NSObject

+ (DHTextLine *) lineWithCTLine:(CTLineRef)line
                       position:(CGPoint)position;

@property (nonatomic, readonly) NSInteger row;
@property (nonatomic, readonly) NSInteger index;

@property (nonatomic, readonly) CTLineRef line;

@property (nonatomic, strong, readonly) NSArray<DHTextAttachment *> *attachments;
@property (nonatomic, strong, readonly) NSArray<NSValue *> *attachmentRanges;   //value of NSRange objects
@property (nonatomic, strong, readonly) NSArray<NSValue *> *attachmentFrames;   //value of CGRect objects

@end
