//
//  DHTextAttribute.h
//  DHTextKit
//
//  Created by Huang Hongsen on 17/5/25.
//  Copyright © 2017年 Huang Hongsen. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "DHTextAttribute.h"
@interface DHTextAttribute : NSObject

typedef NS_ENUM(NSInteger, DHTextTruncateType) {
    DHTextTruncateTypeNone = 0,
    DHTextTruncateTypeStart = 1,    //show the end
    DHTextTruncateTypeEnd = 2,      //show the start
    DHTextTruncateTypeMiddle = 3,   //show the middle
};

typedef NS_ENUM(NSInteger, DHTextVerticalAlignment) {
    DHTextVerticalAlignmentTop = 0,
    DHTextVerticalAlignmentCenter = 1,
    DHTextVerticalAlignmentBottom = 2,
};

UIKIT_EXTERN NSString *const DHTextShadowAttributeName;     //Value should be instance of DHTextShadow
UIKIT_EXTERN NSString *const DHTextAttachmentAttributeName; //Value should be instance of DHTextAttachment

UIKIT_EXTERN NSString *const DHTextAttachmentToken; ///U+FFFC, used for text attachment.
UIKIT_EXTERN NSString *const DHTextTruncationToken; ///U+2026, used for text truncation  "…"

@end
