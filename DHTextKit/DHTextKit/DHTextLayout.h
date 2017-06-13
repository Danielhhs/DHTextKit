//
//  DHTextLayout.h
//  DHTextKit
//
//  Created by Huang Hongsen on 17/5/24.
//  Copyright © 2017年 Huang Hongsen. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreText/CoreText.h>
#import <UIKit/UIKit.h>
#import "DHTextLine.h"
#import "DHTextContainer.h"
#import "DHTextAttachment.h"
#import "DHTextRange.h"

static const CGSize DHTextContainerMaxSize = (CGSize){0x100000, 0x100000};

@interface DHTextLayout : NSObject

@property (nonatomic, strong, readonly, nullable) NSArray <DHTextLine *> *lines;
@property (nonatomic, readonly) CGRect textBoundingRect;
@property (nonatomic, strong, readonly, nullable) DHTextContainer *container;
@property (nonatomic) NSInteger maximumNumberOfRows;
@property (nonatomic, readonly) CGSize textBoundingSize;
@property (nonatomic, readonly, nullable) DHTextLine *truncatedLine;
@property (nonatomic, readonly) NSUInteger rowCount;

#pragma mark - Initializers
+ (nullable DHTextLayout *) layoutWithContainerSize:(CGSize) size
                                      text:(nonnull NSAttributedString *) text;

+ (nullable DHTextLayout *) layoutWithContainer:(nonnull DHTextContainer *)container
                                  text:(nonnull NSAttributedString *) text;

+ (nullable DHTextLayout *) layoutWithContainer:(nonnull DHTextContainer *)container
                                  text:(nonnull NSAttributedString *)text
                                 range:(NSRange)range;

#pragma mark - Query Infomration
- (NSUInteger) lineIndexForPoint:(CGPoint) point;
- (NSUInteger) closestLineIndexForPoint:(CGPoint)point;
- (NSUInteger) textPositionForPoint:(CGPoint)point lineIndex:(NSUInteger)lineIndex;
- (nullable DHTextPosition *) closestPositionToPoint:(CGPoint)point;
- (nullable DHTextPosition *) positionForPoint:(CGPoint)point
                              previousPosition:(nullable DHTextPosition *)previousPosition
                              theOtherPosition:(nullable DHTextPosition *)theOtherPosition;
- (nullable DHTextRange *) textRangeAtPoint:(CGPoint)point;
- (nullable DHTextRange *) closestTextRangeAtPoint:(CGPoint) point;
- (nullable DHTextRange *) textRangeByExtendingPosition:(nullable DHTextPosition *)position;

- (nullable DHTextRange *) textRangeByExtendingPosition:(nullable DHTextPosition *)position
                                            inDirection:(UITextLayoutDirection)direction
                                                 offset:(NSInteger)offset;

- (NSUInteger) lineIndexForPosition:(nullable DHTextPosition *)position;
- (CGPoint) linePositionForPosition:(nullable DHTextPosition *)position;

- (CGRect) caretRectForPosition:(nullable DHTextPosition *)position;
- (CGRect) firstRectForRange:(nullable DHTextRange *)range;
- (CGRect) rectForRange:(nullable DHTextRange *)range;

- (nullable NSArray<DHTextSelectionRect *> *) selectionRectsForRange:(nullable DHTextRange *)range;
- (nullable NSArray<DHTextSelectionRect *> *) selectionRectsWithoutStartAndEndForRange:(nullable DHTextRange *)range;
- (nullable NSArray<DHTextSelectionRect *> *) selectionRectsWithOnlyStartAndEndForRange:(nullable DHTextRange *)range;

- (CGFloat) offsetForPosition:(NSUInteger)position lineIndex:(NSUInteger)lineIndex;

#pragma mark - Drawing
- (void) drawInContext:(nullable CGContextRef)context
                  size:(CGSize)size
                 point:(CGPoint)point
                  view:(nullable UIView *)view
                 layer:(nullable CALayer *)layer
                cancel:(nullable BOOL (^)(void))cancel;

@end
