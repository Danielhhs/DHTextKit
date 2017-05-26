//
//  DHTextRunDelegate.h
//  DHTextKit
//
//  Created by Huang Hongsen on 17/5/25.
//  Copyright © 2017年 Huang Hongsen. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <CoreText/CoreText.h>

@interface DHTextRunDelegate : NSObject
@property (nonatomic) CGFloat width;
@property (nonatomic) CGFloat ascent;
@property (nonatomic) CGFloat descent;
@property (nonatomic, strong, nullable) NSDictionary *userInfo;

- (nullable CTRunDelegateRef) CTRunDelegate;

@end
