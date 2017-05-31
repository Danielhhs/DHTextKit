//
//  DHAsyncDisplayLayer.h
//  DHTextKit
//
//  Created by Huang Hongsen on 17/5/28.
//  Copyright © 2017年 Huang Hongsen. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
@class DHAsyncDisplayTask;
@protocol DHAsyncDisplayLayerDelegate <NSObject>
- (DHAsyncDisplayTask * _Nonnull) asyncDisplayTask;
@end

@interface DHAsyncDisplayTask : NSObject

@property (nonatomic, strong, nullable) void (^willDisplay)( CALayer * _Nonnull layer);
@property (nonatomic, strong, nullable) void (^display)(CGContextRef _Nonnull context, CGSize size);
@property (nonatomic, strong, nullable) void (^didDisplay)(CALayer * _Nonnull layer);
@end

@interface DHAsyncDisplayLayer : CALayer

@property (nonatomic) BOOL displayAsynchronously;

@property (nonatomic, weak, nullable) id<DHAsyncDisplayLayerDelegate> displayDelegate;

@end
