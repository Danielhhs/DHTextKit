//
//  DHTextRunDelegate.m
//  DHTextKit
//
//  Created by Huang Hongsen on 17/5/25.
//  Copyright © 2017年 Huang Hongsen. All rights reserved.
//

#import "DHTextRunDelegate.h"
#import <CoreText/CoreText.h>

static void DeallocCallback(void *delegate) {
    DHTextRunDelegate *self = (__bridge_transfer DHTextRunDelegate *)delegate;
    self = nil;
}

static CGFloat GetAscentCallback(void *delegate) {
    DHTextRunDelegate *self = (__bridge DHTextRunDelegate *)delegate;
    return self.ascent;
}

static CGFloat GetDescentCallback(void *delegate) {
    DHTextRunDelegate *self = (__bridge DHTextRunDelegate *)delegate;
    return self.descent;
}

static CGFloat GetWidthCallback(void *delegate) {
    DHTextRunDelegate *self = (__bridge DHTextRunDelegate *)delegate;
    return self.width;
}

@implementation DHTextRunDelegate

- (CTRunDelegateRef) CTRunDelegate
{
    CTRunDelegateCallbacks callbacks;
    callbacks.version = kCTRunDelegateCurrentVersion;
    callbacks.dealloc = DeallocCallback;
    callbacks.getAscent = GetAscentCallback;
    callbacks.getDescent = GetDescentCallback;
    callbacks.getWidth = GetWidthCallback;
    return CTRunDelegateCreate(&callbacks, (__bridge_retained void *)[self copy]);
}

- (id)copyWithZone:(NSZone *)zone {
    typeof(self) one = [self.class new];
    one.ascent = self.ascent;
    one.descent = self.descent;
    one.width = self.width;
    one.userInfo = self.userInfo;
    return one;
}
@end
