//
//  DHTextDebugOption.h
//  DHTextKit
//
//  Created by Huang Hongsen on 17/6/15.
//  Copyright © 2017年 Huang Hongsen. All rights reserved.
//

#import <UIKit/UIKit.h>

@class DHTextDebugOption;

@protocol DHTextDebugTarget <NSObject>

- (void) setDebugOption:(nullable DHTextDebugOption *)option;

@end

@interface DHTextDebugOption : NSObject<NSCopying>

@property (nonatomic, nullable, strong) UIColor *baselineColor;
@property (nonatomic, nullable, strong) UIColor *CTFrameBorderColor;
@property (nonatomic, nullable, strong) UIColor *CTFrameFillColor;
@property (nonatomic, nullable, strong) UIColor *CTLineBorderColor;
@property (nonatomic, nullable, strong) UIColor *CTLineFillColor;
@property (nonatomic, nullable, strong) UIColor *CTLineNumberColor;
@property (nonatomic, nullable, strong) UIColor *CTRunBorderColor;
@property (nonatomic, nullable, strong) UIColor *CTRunFillColor;
@property (nonatomic, nullable, strong) UIColor *CTRunNumberColor;
@property (nonatomic, nullable, strong) UIColor *CGGlyphBorderColor;
@property (nonatomic, nullable, strong) UIColor *CGGlyphFillColor;

- (void) needToDrawDebug;
- (void) clear;

- (void) addDebugTarget:(nullable id<DHTextDebugTarget>)target;
- (void) removeDebugTarget:(nullable id<DHTextDebugTarget>)target;
+ (nullable DHTextDebugOption *) sharedDebugOption;
+ (void) setSharedDebugOption:(nullable DHTextDebugOption *)option;
@end
