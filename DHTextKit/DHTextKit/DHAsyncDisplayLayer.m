//
//  DHAsyncDisplayLayer.m
//  DHTextKit
//
//  Created by Huang Hongsen on 17/5/28.
//  Copyright © 2017年 Huang Hongsen. All rights reserved.
//

#import "DHAsyncDisplayLayer.h"
#import <UIKit/UIKit.h>
#import <libkern/OSAtomic.h>

#define MAX_QUEUE_COUNT 16

static dispatch_queue_t queues[MAX_QUEUE_COUNT];

@implementation DHAsyncDisplayLayer

- (void) setFrame:(CGRect)frame
{
    [super setFrame:frame];
}

- (void) setPosition:(CGPoint)position
{
    [super setPosition:position];
}

- (void) setBounds:(CGRect)bounds
{
    [super setBounds:bounds];
}

+ (id) defaultValueForKey:(NSString *)key
{
    if ([key isEqualToString:@"displayAsynchronously"]) {
        return @(YES);
    } else {
        return [super defaultValueForKey:key];
    }
}

- (void) display
{
    self.contents = super.contents;
    
    __strong id<DHAsyncDisplayLayerDelegate> delegate = (id)self.delegate;
    CGColorRef backgroundColor = (self.opaque && self.backgroundColor) ? CGColorRetain(self.backgroundColor) : NULL;    //Retain the color for async drawing
    DHAsyncDisplayTask *task = [delegate asyncDisplayTask];
    if (task.display == nil) {
        if (task.willDisplay) {
            task.willDisplay(self);
        }
        self.contents = nil;
        if (task.didDisplay) {
            task.didDisplay(self);
        }
    }
    if (self.displayAsynchronously) {
        if (task.willDisplay) {
            task.willDisplay(self);
        }
        if (self.bounds.size.width < 1 || self.bounds.size.height < 1) {    //If Size is small, relase the content
            CGImageRef image = (__bridge_retained CGImageRef)self.contents;
            if (image != NULL) {
                dispatch_async([DHAsyncDisplayLayer _getReleaseQueue], ^{     //TO-DO: Create release queue;
                    CGImageRelease(image);
                });
            }
            if (task.didDisplay) {
                task.didDisplay(self);
            }
            CGColorRelease(backgroundColor);
            return ;
        }
        //TO-DO: Handle canclled case
        dispatch_async([DHAsyncDisplayLayer _getDisplayQueue], ^{     //TO-DO: Create display Queue
            UIImage *image = [self contentImageWithTask:task];
            dispatch_async(dispatch_get_main_queue(), ^{
                self.contents = (__bridge id)image.CGImage;
                if (task.didDisplay) {
                    task.didDisplay(self);
                }
            });
        });
    } else {
        if (task.willDisplay) {
            task.willDisplay(self);
        }
        UIImage *image = [self contentImageWithTask:task];
        self.contents = (__bridge id)image.CGImage;
        if (task.didDisplay) {
            task.didDisplay(self);
        }
    }
    CGColorRelease(backgroundColor);
}

- (UIImage *) contentImageWithTask:(DHAsyncDisplayTask *)task
{
    CGSize size = self.bounds.size;
    CGFloat contentScale = self.contentsScale;
    CGColorRef backgroundColor = (self.opaque && self.backgroundColor) ? CGColorRetain(self.backgroundColor) : NULL;    //Retain the color for async drawing
    UIGraphicsBeginImageContextWithOptions(self.bounds.size, self.opaque, 0);
    CGContextRef context = UIGraphicsGetCurrentContext();
    if (self.opaque) {
        CGContextSaveGState(context); {
            if (!backgroundColor || CGColorGetAlpha(backgroundColor) < 1) {
                CGContextSetFillColorWithColor(context, [UIColor whiteColor].CGColor);
                CGContextAddRect(context, CGRectMake(0, 0, size.width * contentScale, size.height * contentScale));
                CGContextFillPath(context);
            }
            if (backgroundColor) {
                CGContextSetFillColorWithColor(context, backgroundColor);
                CGContextAddRect(context, CGRectMake(0, 0, size.width * contentScale, size.height * contentScale));
                CGContextFillPath(context);
            }
            CGColorRelease(backgroundColor);
        }
    }
    task.display(context, size);
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

+ (dispatch_queue_t) _getDisplayQueue
{
    static dispatch_once_t onceToken;
    static int queueCount;
    static int counter;
    dispatch_once(&onceToken, ^{
        queueCount = (int)[NSProcessInfo processInfo].activeProcessorCount;
        queueCount = queueCount < 1 ? 1 : queueCount > MAX_QUEUE_COUNT ? MAX_QUEUE_COUNT : queueCount;
        for (int i = 0; i < queueCount; i++) {
            dispatch_queue_attr_t attribtues = dispatch_queue_attr_make_with_qos_class(DISPATCH_QUEUE_SERIAL, QOS_CLASS_USER_INITIATED, 0);
            queues[i] = dispatch_queue_create("com.dhtextkit.display", attribtues);
        }
    });
    int32_t current = OSAtomicIncrement32(&counter);
    if (current < 0) current = -current;
    return queues[current % queueCount];
}

+ (dispatch_queue_t) _getReleaseQueue
{
    return dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0);
}
@end

@implementation DHAsyncDisplayTask



@end
