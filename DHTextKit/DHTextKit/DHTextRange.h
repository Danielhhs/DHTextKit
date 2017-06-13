//
//  DHTextRange.h
//  DHTextKit
//
//  Created by Huang Hongsen on 17/6/8.
//  Copyright © 2017年 Huang Hongsen. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
typedef NS_ENUM(NSInteger, DHTextAffinity) {
    DHTextAffinityForward = 0,  //Offset appears before the character
    DHTextAffinityBackward = 1, //Offset appears after the character
};

@interface DHTextPosition : UITextPosition<NSCopying>
@property (nonatomic, readonly) NSInteger offset;
@property (nonatomic, readonly) DHTextAffinity affinity;

+ (DHTextPosition *) positionWithOffset:(NSInteger)offset;
+ (DHTextPosition *) positionWithOffset:(NSInteger)offset affinity:(DHTextAffinity)affinity;

- (NSComparisonResult) compare:(DHTextPosition *)anotherPosition;
@end

@interface DHTextRange : UITextRange<NSCopying>

@property (nonatomic, strong, readonly) DHTextPosition *start;
@property (nonatomic, strong, readonly) DHTextPosition *end;

+ (DHTextRange *) rangeWithNSRange:(NSRange)range;
+ (DHTextRange *) rangeWithNSRange:(NSRange)range affinity:(DHTextAffinity)affinity;
+ (DHTextRange *) rangeWithStart:(DHTextPosition *)start end:(DHTextPosition *)end;
+ (DHTextRange *) defaultRange;

- (NSRange) nsRange;

@end

@interface DHTextSelectionRect : UITextSelectionRect<NSCopying>

@property (nonatomic, readwrite) CGRect rect;
@property (nonatomic, readwrite) UITextWritingDirection writingDirection;
@property (nonatomic, readwrite) BOOL containsStart;
@property (nonatomic, readwrite) BOOL containsEnd;
@property (nonatomic, readwrite) BOOL isVertical;

@end
