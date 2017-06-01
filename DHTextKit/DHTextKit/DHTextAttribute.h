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

typedef NS_ENUM(NSInteger, DHTextLineStyle) {
    DHTextLineStyleNone     = 0x00,     ///< (        ) Do not draw a line (Default).
    DHTextLineStyleSingle   = 0x01,     ///< (──────) Draw a single line.
    DHTextLineStyleThick    = 0x02,     ///< (━━━━━━━) Draw a thick line.
    DHTextLineStyleDouble   = 0x09,     ///< (══════) Draw a double line.
    
    DHTextLineStylePatternSolid         = 0x000,    ///< (────────) Draw a solid line (Default).
    DHTextLineStylePatternDot           = 0x100,    ///< (‑ ‑ ‑ ‑ ‑ ‑) Draw a line of dots.
    DHTextLineStylePatternDash          = 0x200,    ///< (— — — —) Draw a line of dashes.
    DHTextLineStylePatternDashDot       = 0x300,    ///< (— ‑ — ‑ — ‑) Draw a line of alternating dashes and dots.
    DHTextLineStylePatternDashDotDot    = 0x400,    ///< (— ‑ ‑ — ‑ ‑) Draw a line of alternating dashes and two dots.
    DHTextLineStylePatternCircleDot     = 0x500,    ///< (••••••••••••) Draw a line of small circle dots.
};

typedef NS_ENUM(NSInteger, DHTextBorderType) {
    DHTextBorderTypeBackground = 1 << 0,
    DHTextBorderTypeNormal = 1 << 1,
};

UIKIT_EXTERN NSString *const DHTextShadowAttributeName;     //Value should be instance of DHTextShadow or NSShadow
UIKIT_EXTERN NSString *const DHTextAttachmentAttributeName; //Value should be instance of DHTextAttachment
UIKIT_EXTERN NSString *const DHTextInnerShadowAttributeName;    //Value should be instance of DHTextShadow
UIKIT_EXTERN NSString *const DHTextGlyphTransformAttributeName; //Value should be instance of NSValue wrapping CGAffineTransform
UIKIT_EXTERN NSString *const DHTextBorderAttributeName;     //Value should be instance of DHTextBorder
UIKIT_EXTERN NSString *const DHTextBackgroundBorderAttributeName;     //Value should be instance of DHTextBorder

UIKIT_EXTERN NSString *const DHTextAttachmentToken; ///U+FFFC, used for text attachment.
UIKIT_EXTERN NSString *const DHTextTruncationToken; ///U+2026, used for text truncation  "…"

@end
