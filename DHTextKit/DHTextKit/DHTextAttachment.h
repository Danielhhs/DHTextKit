//
//  DHTextAttachment.h
//  DHTextKit
//
//  Created by Huang Hongsen on 17/5/23.
//  Copyright © 2017年 Huang Hongsen. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface DHTextAttachment : NSObject

@property (nonatomic, strong) id content;   //Could be instance of UIImage, UIView or CALayer;
@property (nonatomic) UIEdgeInsets contentInsets;
@property (nonatomic) UIViewContentMode contentMode;

@end
