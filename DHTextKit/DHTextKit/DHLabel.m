//
//  DHLabel.m
//  DHTextKit
//
//  Created by Huang Hongsen on 17/5/22.
//  Copyright © 2017年 Huang Hongsen. All rights reserved.
//

#import "DHLabel.h"
#import <CoreText/CoreText.h>
#import "DHTextLayout.h"
#import "DHAsyncDisplayLayer.h"
#import "NSAttributedString+DHText.h"
#import "DHTextRange.h"

static const CGFloat kMaxLabelHeight = 1000000;

@interface DHLabel ()<DHAsyncDisplayLayerDelegate> {
    struct {
        unsigned int layoutNeedUpdate : 1;
        unsigned int showingHighlight : 1;
        
        unsigned int trackingTouch : 1;
        unsigned int swallowTouch : 1;
        unsigned int touchMoved : 1;
        
        unsigned int hasTapAction : 1;
        unsigned int hasLongPressAction : 1;
        
        unsigned int contentsNeedFade : 1;
    } _state;
}
@property (nonatomic, strong) DHTextLayout *layout;
@property (nonatomic, strong) DHTextContainer *textContainer;
@property (nonatomic) BOOL needsToUpdateLayout;
@property (nonatomic) CGPoint touchBeginPoint;
@end

#define kLongPressMinimumDuration 0.5
#define kLongPressMovementThreshold 9.0

@implementation DHLabel

#pragma mark - Initialization
- (instancetype) initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setup];
    }
    return self;
}

- (void) awakeFromNib
{
    [super awakeFromNib];
    [self setup];
}

- (void) setup
{
    DHAsyncDisplayLayer *layer = (DHAsyncDisplayLayer *)self.layer;
    layer.displayDelegate = self;
    self.backgroundColor = [UIColor clearColor];
    self.shadowColor = [UIColor blackColor];
    self.textColor = [UIColor blackColor];
    self.shadowOffset = 5;
}

+ (Class) layerClass
{
    return [DHAsyncDisplayLayer class];
}
#pragma mark - Update Properties
- (NSAttributedString *) _attributedStringToDraw
{
    if (self.attribtuedText) {
        return self.attribtuedText;
    } else {
        if (self.text == nil) {
            return nil;
        }
        NSMutableAttributedString *attrStr = [[NSMutableAttributedString alloc] initWithString:self.text];
        [attrStr setLineBreakMode:self.lineBreakMode];
        [attrStr setFont:self.font];
        [attrStr setColor:self.textColor];
        return attrStr;
    }
}

- (void) setAttribtuedText:(NSAttributedString *)attribtuedText
{
    _attribtuedText = attribtuedText;
    [self _setNeedsToUpdateLayout];
}

- (void) setBounds:(CGRect)bounds
{
    [super setBounds:bounds];
    [self _setNeedsToUpdateLayout];
}

- (void) setFrame:(CGRect)frame
{
    [super setFrame:frame];
    [self _setNeedsToUpdateLayout];
}

- (void) _setNeedsToUpdateLayout
{
    self.needsToUpdateLayout = YES;
    [self setNeedsDisplay];
}

- (void) _updateLayoutIfNeeds
{
    if (self.needsToUpdateLayout) {
        self.needsToUpdateLayout = NO;
        self.textContainer = [DHTextContainer containerWithSize:self.bounds.size];
        self.textContainer.maximumNumberOfRows = self.maximumNumberOfRows;
        self.textContainer.truncationType = self.truncationType;
        self.textContainer.truncationToken = self.truncationToken;
        self.textContainer.insets = self.textContainerInsets;
        self.layout = [DHTextLayout layoutWithContainer:self.textContainer
                                                   text:[self _attributedStringToDraw]];
        [self setNeedsDisplay];
    }
}

- (void) setNeedsDisplay
{
    [super setNeedsDisplay];
    [self.layer setNeedsDisplay];
}

- (CGSize) sizeThatFits:(CGSize)size
{
    if (size.height <= 0) size.height = DHTextContainerMaxSize.height;
    if (self.bounds.size.width == size.width) {
        [self _updateLayoutIfNeeds];
        DHTextLayout *layout = self.layout;
        BOOL contains = NO;
        if (layout.container.maximumNumberOfRows == 0) {
            if (layout.truncatedLine == nil) {
                contains = YES;
            }
        } else {
            if (layout.rowCount <= layout.container.maximumNumberOfRows) {
                contains = YES;
            }
        }
        if (contains) {
            return layout.textBoundingSize;
        }
    }
    size.width = DHTextContainerMaxSize.width;
    DHTextContainer *container = [self.layout.container copy];
    container.size = size;
    DHTextLayout *layout = [DHTextLayout layoutWithContainer:container text:self.attribtuedText];
    return layout.textBoundingSize;
}

+ (CGRect) textBoundingRectForAttributedString:(NSAttributedString *)attributedString
                                      maxWidth:(CGFloat)width;
{
    return [DHLabel textBoundingRectForAttributedString:attributedString
                                                maxSize:CGSizeMake(width, kMaxLabelHeight)];
}

+ (CGRect) textBoundingRectForAttributedString:(NSAttributedString *)attributedString maxSize:(CGSize)size
{
    DHTextLayout *layout = [DHTextLayout layoutWithContainerSize:size
                                                         text:attributedString];
    return layout.textBoundingRect;
}

#pragma mark - DHAsyncDisplayLayerDelegate
- (DHAsyncDisplayTask *) asyncDisplayTask
{
    DHAsyncDisplayTask *task = [[DHAsyncDisplayTask alloc] init];
    task.willDisplay = ^(CALayer *layer) {
        
    };
    
    task.display = ^(CGContextRef context, CGSize size) {
        [self _updateLayoutIfNeeds];
        [self.layout drawInContext:context size:size point:CGPointZero view:self layer:self.layer cancel:nil];
    };
    
    task.didDisplay = nil;
    return task;
}

#pragma mark - Event Handling
- (void) touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    [self _updateLayoutIfNeeds];
    UITouch *touch = [touches anyObject];
    CGPoint point = [touch locationInView:self];
    if (_tapAction || _longPressAction) {
        _touchBeginPoint = point;
        _state.trackingTouch = YES;
        _state.swallowTouch = YES;
        _state.touchMoved = NO;
        [self _startLongPressTimer];
    } else {
        _state.trackingTouch = NO;
        _state.swallowTouch = NO;
        _state.touchMoved = NO;
    }
    if (!_state.swallowTouch) {
        [super touchesBegan:touches withEvent:event];
    }
}

- (void) touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    [self _updateLayoutIfNeeds];
    UITouch *touch = [touches anyObject];
    CGPoint point = [touch locationInView:self];
    
    if (_state.trackingTouch) {
        if (!_state.touchMoved) {
            CGFloat moveX = point.x - _touchBeginPoint.x;
            CGFloat moveY = point.y - _touchBeginPoint.y;
            if (MAX(fabs(moveX), fabs(moveY)) > kLongPressMovementThreshold) {
                _state.touchMoved = YES;
            }
            if (_state.touchMoved) {
                [self _endLongpressTimer];
            }
        }
    }
    if (!_state.swallowTouch) {
        [super touchesMoved:touches withEvent:event];
    }
}

- (void) touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
//    UITouch *touch = [touches anyObject];
//    CGPoint point = [touch locationInView:self];
    
    if (_state.trackingTouch) {
        [self _endLongpressTimer];
        if (!_state.touchMoved && _tapAction) {
            NSRange range = NSMakeRange(NSNotFound, 0);
            CGRect rect = CGRectNull;
            CGPoint point = [self _convertPointToLayout:_touchBeginPoint];
            DHTextRange *textRange = [self.layout textRangeAtPoint:point];
            CGRect textRect = [self.layout rectForRange:textRange];
            textRect = [self _convertRectFromLayout:textRect];
            if (textRange) {
                range = [textRange nsRange];
                rect = textRect;
            }
            _tapAction(self, self.attribtuedText, range, rect);
        }
    }
}

- (void) _startLongPressTimer
{
    
}

- (void) _endLongpressTimer
{
    
}

#pragma mark - Private Helpers
- (CGPoint) _convertPointToLayout:(CGPoint)point
{
    CGSize boundingSize = self.layout.textBoundingRect.size;
    if (_textVerticalAlignment == DHTextVerticalAlignmentCenter) {
        point.y -= (self.bounds.size.height - boundingSize.height) * 0.5;
    } else if (_textVerticalAlignment == DHTextVerticalAlignmentBottom) {
        point.y -= (self.bounds.size.height - boundingSize.height);
    }
    return point;
}

- (CGPoint) _convertPointFromLayout:(CGPoint) point
{
    CGSize boundingSize = self.layout.textBoundingRect.size;
    if (boundingSize.height < self.bounds.size.height) {
        if (_textVerticalAlignment == DHTextVerticalAlignmentCenter) {
            point.y += (self.bounds.size.height - boundingSize.height) * 0.5;
        } else if (_textVerticalAlignment == DHTextVerticalAlignmentBottom) {
            point.y += (self.bounds.size.height - boundingSize.height);
        }
    }
    return point;
}

- (CGRect) _convertRectFromLayout:(CGRect)rect
{
    rect.origin = [self _convertPointFromLayout:rect.origin];
    return rect;
}

- (CGRect) _convertRectToLayout:(CGRect)rect
{
    rect.origin = [self _convertPointToLayout:rect.origin];
    return rect;
}
@end
