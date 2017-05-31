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

typedef NS_ENUM(NSInteger, DHTextTruncationType) {
    DHTextTruncationTypeNone = 0,
    DHTextTruncationTypeStart = 1,    //show the end
    DHTextTruncationTypeEnd = 2,      //show the start
    DHTextTruncationTypeMiddle = 3,   //show the middle
};

typedef NS_ENUM(NSInteger, DHTextVerticalAlignment) {
    DHTextVerticalAlignmentTop = 0,
    DHTextVerticalAlignmentCenter = 1,
    DHTextVerticalAlignmentBottom = 2,
};

UIKIT_EXTERN NSString *const DHTextShadowAttributeName;     //Value should be instance of DHTextShadow or NSShadow
UIKIT_EXTERN NSString *const DHTextAttachmentAttributeName; //Value should be instance of DHTextAttachment
UIKIT_EXTERN NSString *const DHTextInnerShadowAttributeName;    //Value should be instance of DHTextShadow
UIKIT_EXTERN NSString *const DHTextGlyphTransformAttributeName; //Value should be instance of NSValue wrapping CGAffineTransform

UIKIT_EXTERN NSString *const DHTextAttachmentToken; ///U+FFFC, used for text attachment.
UIKIT_EXTERN NSString *const DHTextTruncationToken; ///U+2026, used for text truncation  "…"

@end
