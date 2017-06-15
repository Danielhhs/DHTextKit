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
#import "DHTextHighlight.h"

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
    
    
    DHTextLayout *_innerLayout;
    DHTextHighlight *_highlight;
    DHTextLayout *_highlightLayout;
    
    DHTextLayout *_shrinkInnerLayout;
    DHTextLayout *_shrinkHighlightLayout;
}
@property (nonatomic, strong) DHTextContainer *textContainer;
@property (nonatomic) NSRange highlightRange;

@property (nonatomic, strong) NSTimer *longPressTimer;

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
    self.fadeOnHighlight = YES;
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
        _innerLayout = [DHTextLayout layoutWithContainer:self.textContainer
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
        DHTextLayout *layout = self.innerLayout;
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
    DHTextContainer *container = [self.innerLayout.container copy];
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
    BOOL contentNeedsFade = _state.contentsNeedFade;
    NSAttributedString *text = self.attribtuedText;
    DHTextContainer *container = [self.innerLayout container];
    DHTextVerticalAlignment verticalAlignment = _textVerticalAlignment;
    DHAsyncDisplayTask *task = [[DHAsyncDisplayTask alloc] init];
    __block DHTextLayout *layout = (_state.showingHighlight && _highlightLayout) ? _highlightLayout : self.innerLayout;
    
    task.willDisplay = ^(CALayer *layer) {
        
    };
    
    task.display = ^(CGContextRef context, CGSize size) {
        [self _updateLayoutIfNeeds];
        [layout drawInContext:context size:size point:CGPointZero view:self layer:self.layer cancel:nil];
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
    
    _highlight = [self _getHighlightAtPoint:point range:&_highlightRange];
    _highlightLayout = nil;
    _shrinkHighlightLayout = nil;
    _state.hasTapAction = (_tapAction != nil);
    _state.hasLongPressAction = (_longPressAction != nil);
    
    if (_highlight || _tapAction || _longPressAction) {
        _touchBeginPoint = point;
        _state.trackingTouch = YES;
        _state.swallowTouch = YES;
        _state.touchMoved = NO;
        [self _startLongPressTimer];
        if (_highlight) [self _showHighlightAnimated:NO];
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
        if (_state.touchMoved && _highlight) {
            DHTextHighlight *highlight = [self _getHighlightAtPoint:point range:NULL];
            if (highlight == _highlight) {
                [self _showHighlightAnimated:_fadeOnHighlight];
            } else {
                [self _hideHightlightAnimated:_fadeOnHighlight];
            }
        }
    }
    if (!_state.swallowTouch) {
        [super touchesMoved:touches withEvent:event];
    }
}

- (void) touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    UITouch *touch = [touches anyObject];
    CGPoint point = [touch locationInView:self];
    
    if (_state.trackingTouch) {
        [self _endLongpressTimer];
        if (!_state.touchMoved && _tapAction) {
            NSRange range = NSMakeRange(NSNotFound, 0);
            CGRect rect = CGRectNull;
            CGPoint point = [self _convertPointToLayout:_touchBeginPoint];
            DHTextRange *textRange = [self.innerLayout textRangeAtPoint:point];
            CGRect textRect = [self.innerLayout rectForRange:textRange];
            textRect = [self _convertRectFromLayout:textRect];
            if (textRange) {
                range = [textRange nsRange];
                rect = textRect;
            }
            _tapAction(self, self.attribtuedText, range, rect);
        }
        if (_highlight) {
            if (!_state.touchMoved || [self _getHighlightAtPoint:point range:NULL]) {
                DHTextAction tapAction = _highlight.tapAction ? _highlight.tapAction : _highlightTapAction;
                if (tapAction) {
                    DHTextPosition *start = [DHTextPosition positionWithOffset:_highlightRange.location];
                    DHTextPosition *end = [DHTextPosition positionWithOffset:_highlightRange.location + _highlightRange.length affinity:DHTextAffinityBackward];
                    DHTextRange *range = [DHTextRange rangeWithStart:start end:end];
                    CGRect rect = [self.innerLayout rectForRange:range];
                    rect = [self _convertRectFromLayout:rect];
                    tapAction(self, _attribtuedText, _highlightRange, rect);
                }
            }
            [self _removeHighlightAnimated:_fadeOnHighlight];
        }
    }
}

- (void) touchesCancelled:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    [self _endTouch];
    if (!_state.swallowTouch) [super touchesCancelled:touches withEvent:event];
}

- (void) _startLongPressTimer
{
    [_longPressTimer invalidate];
    _longPressTimer = [NSTimer timerWithTimeInterval:kLongPressMinimumDuration target:self selector:@selector(_trackDidLongPress) userInfo:nil repeats:NO];
    [[NSRunLoop currentRunLoop] addTimer:_longPressTimer forMode:NSRunLoopCommonModes];
}

- (void) _endLongpressTimer
{
    [_longPressTimer invalidate];
    _longPressTimer = nil;
}

- (void) _trackDidLongPress
{
    [self _endLongpressTimer];
    if (_state.hasLongPressAction && _longPressAction) {
        NSRange range = NSMakeRange(NSNotFound, 0);
        CGRect rect = CGRectNull;
        CGPoint point = [self _convertPointToLayout:_touchBeginPoint];
        DHTextRange *textRange = [self.innerLayout textRangeAtPoint:point];
        CGRect textRect = [self.innerLayout rectForRange:textRange];
        textRect = [self _convertRectFromLayout:textRect];
        if (textRange) {
            range = textRange.nsRange;
            rect = textRect;
        }
        _longPressAction(self, self.attribtuedText, range, rect);
    }
    if (_highlight) {
        DHTextAction longPressAction = _highlight.longPressAction ? _highlight.longPressAction : _highlightLongPressAction;
        if (longPressAction) {
            DHTextPosition *start = [DHTextPosition positionWithOffset:_highlightRange.location];
            DHTextPosition *end = [DHTextPosition positionWithOffset:_highlightRange.location + _highlightRange.length affinity:DHTextAffinityBackward];
            DHTextRange *range = [DHTextRange rangeWithStart:start end:end];
            CGRect rect = [self.innerLayout rectForRange:range];
            rect = [self _convertRectFromLayout:rect];
            longPressAction(self, self.attribtuedText, _highlightRange,  rect);
            [self _removeHighlightAnimated:YES];
            _state.trackingTouch = NO;
        }
    }
}

#pragma mark - Highlights
- (DHTextHighlight *) _getHighlightAtPoint:(CGPoint)point range:(NSRangePointer)range
{
    if (!self.innerLayout.containsHighlight) return nil;
    point = [self _convertPointToLayout:point];
    DHTextRange *textRange = [self.innerLayout textRangeAtPoint:point];
    NSLog(@"==============Range = (%lu, %lu)", textRange.nsRange.location, textRange.nsRange.location + textRange.nsRange.length);
    if (!textRange) return nil;
    NSUInteger startIndex = textRange.start.offset;
    if (startIndex == [self.attribtuedText length]) {
        if (startIndex > 0) {
            startIndex--;
        }
    }
    NSRange highlightRange = NSMakeRange(0, 0);
    DHTextHighlight *highlight = [self.attribtuedText attribute:DHTextHighlightAttributeName atIndex:startIndex longestEffectiveRange:&highlightRange inRange:NSMakeRange(0, [self.attribtuedText length])];
    if (!highlight) return nil;
    if (range) *range = highlightRange;
    return highlight;
}

- (void) _showHighlightAnimated:(BOOL) animated
{
    if (!_highlight) return ;
    if (!_highlightLayout) {
        NSMutableAttributedString *hiText = [self.attribtuedText mutableCopy];
        NSDictionary *newAttributes = _highlight.attributes;
        [newAttributes enumerateKeysAndObjectsUsingBlock:^(NSString *  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
            [hiText setAttribute:key value:obj range:_highlightRange];
        }];
        _highlightLayout = [DHTextLayout layoutWithContainer:_innerLayout.container text:hiText];
        _shrinkHighlightLayout = [DHLabel _shrinkLayoutWithLayout:_highlightLayout];
        if (!_highlightLayout) _highlight = nil;
    }
    if (_highlightLayout && !_state.showingHighlight) {
        _state.showingHighlight = YES;
        _state.contentsNeedFade = animated;
        [self _setLayoutNeedsRedraw];
    }
}

- (void) _hideHightlightAnimated:(BOOL) animated
{
    if (_state.showingHighlight) {
        _state.showingHighlight = NO;
        _state.contentsNeedFade = animated;
        [self _setLayoutNeedsRedraw];
    }
}

- (void) _removeHighlightAnimated:(BOOL)animate
{
    [self _hideHightlightAnimated:animate];
    _highlight = nil;
    _highlightLayout = nil;
    _shrinkHighlightLayout = nil;
}

- (void) _endTouch
{
    [self _endLongpressTimer];
    [self _removeHighlightAnimated:YES];
    _state.trackingTouch = NO;
}

#pragma mark - Layouts
- (DHTextLayout *) innerLayout
{
    return _shrinkInnerLayout ? _shrinkInnerLayout : _innerLayout;
}

- (DHTextLayout *) highlightLayout
{
    return _shrinkHighlightLayout ? _shrinkHighlightLayout : _highlightLayout;
}

+ (DHTextLayout *) _shrinkLayoutWithLayout:(DHTextLayout *) layout
{
    if ([layout.text length] && [layout.lines count] == 0) {
        DHTextContainer *container = [layout.container copy];
        container.maximumNumberOfRows = 1;
        CGSize containerSize = container.size;
        containerSize.width = DHTextContainerMaxSize.width;
        container.size = containerSize;
        return [DHTextLayout layoutWithContainer:container text:layout.text];
    }
    return nil;
}

#pragma mark - Private Helpers
- (CGPoint) _convertPointToLayout:(CGPoint)point
{
    CGSize boundingSize = self.innerLayout.textBoundingRect.size;
    if (_textVerticalAlignment == DHTextVerticalAlignmentCenter) {
        point.y -= (self.bounds.size.height - boundingSize.height) * 0.5;
    } else if (_textVerticalAlignment == DHTextVerticalAlignmentBottom) {
        point.y -= (self.bounds.size.height - boundingSize.height);
    }
    return point;
}

- (CGPoint) _convertPointFromLayout:(CGPoint) point
{
    CGSize boundingSize = self.innerLayout.textBoundingRect.size;
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

- (void) _setLayoutNeedsRedraw
{
    [self.layer setNeedsDisplay];
}

@end
