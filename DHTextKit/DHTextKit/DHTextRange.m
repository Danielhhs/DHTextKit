//
//  DHTextRange.m
//  DHTextKit
//
//  Created by Huang Hongsen on 17/6/8.
//  Copyright © 2017年 Huang Hongsen. All rights reserved.
//

#import "DHTextRange.h"

@implementation DHTextPosition

+ (DHTextPosition *) positionWithOffset:(NSInteger)offset
{
    return [DHTextPosition positionWithOffset:offset affinity:DHTextAffinityForward];
}

+ (DHTextPosition *) positionWithOffset:(NSInteger)offset affinity:(DHTextAffinity)affinity
{
    DHTextPosition *position = [[DHTextPosition alloc] init];
    position->_offset = offset;
    position->_affinity = affinity;
    return position;
}

- (instancetype) copyWithZone:(NSZone *)zone
{
    return [DHTextPosition positionWithOffset:self.offset affinity:self.affinity];
}

- (NSString *) description
{
    return [NSString stringWithFormat:@"<%@: %p> (%@%@)", self.class, self, @(_offset), _affinity == DHTextAffinityForward ? @"F":@"B"];
}

- (NSUInteger)hash {
    return _offset * 2 + (_affinity == DHTextAffinityForward ? 1 : 0);
}

- (BOOL) isEqual:(DHTextPosition *)object
{
    if (!object) return NO;
    return _offset == object.offset && _affinity == object.affinity;
}

- (NSComparisonResult) compare:(DHTextPosition *)anotherPosition
{
    if (anotherPosition == nil) return NSOrderedAscending;
    if (_offset < anotherPosition.offset) return NSOrderedAscending;
    if (_offset > anotherPosition.offset) return NSOrderedDescending;
    if (_affinity == DHTextAffinityBackward && anotherPosition.affinity == DHTextAffinityForward) return NSOrderedAscending;
    if (_affinity == DHTextAffinityForward && anotherPosition.affinity == DHTextAffinityBackward) return NSOrderedDescending;
    return NSOrderedSame;
}

@end

@implementation DHTextRange {
    DHTextPosition *_start;
    DHTextPosition *_end;
}

@synthesize start = _start;
@synthesize end = _end;

#pragma mark - Initializers
- (instancetype) init
{
    self = [super init];
    if (self) {
        _start = [DHTextPosition positionWithOffset:0];
        _end = [DHTextPosition positionWithOffset:0];
    }
    return self;
}

+ (DHTextRange *) rangeWithNSRange:(NSRange)range
{
    return [DHTextRange rangeWithNSRange:range affinity:DHTextAffinityForward];
}

+ (DHTextRange *) rangeWithNSRange:(NSRange)range affinity:(DHTextAffinity)affinity
{
    DHTextPosition *start = [DHTextPosition positionWithOffset:range.location affinity:affinity];
    DHTextPosition *end = [DHTextPosition positionWithOffset:range.location + range.length affinity:affinity];
    return [DHTextRange rangeWithStart:start end:end];
}

+ (DHTextRange *) rangeWithStart:(DHTextPosition *)start end:(DHTextPosition *)end
{
    if (!start || !end) return nil;
    if ([start compare:end] == NSOrderedDescending)  {
        DHTextPosition *tmp = end;
        end = start;
        start = tmp;
    }
    DHTextRange *range = [[DHTextRange alloc] init];
    range->_start = start;
    range->_end = end;
    return range;
}

+ (DHTextRange *) defaultRange
{
    return [[DHTextRange alloc] init];
}

- (instancetype) copyWithZone:(NSZone *)zone
{
    return [DHTextRange rangeWithStart:_start end:_end];
}

#pragma mark - Getters
- (DHTextPosition *) start
{
    return _start;
}

- (DHTextPosition *) end
{
    return _end;
}

- (BOOL) isEmpty
{
    return _start.offset == _end.offset;
}

- (NSRange) nsRange
{
    return NSMakeRange(_start.offset, _end.offset - _start.offset);
}

#pragma mark - Override
- (NSString *)description {
    return [NSString stringWithFormat:@"<%@: %p> (%@, %@)%@", self.class, self, @(_start.offset), @(_end.offset - _start.offset), _end.affinity == DHTextAffinityForward ? @"F":@"B"];
}

- (NSUInteger)hash {
    return (sizeof(NSUInteger) == 8 ? OSSwapInt64(_start.hash) : OSSwapInt32(_start.hash)) + _end.hash;
}

- (BOOL)isEqual:(DHTextRange *)object {
    if (!object) return NO;
    return [_start isEqual:object.start] && [_end isEqual:object.end];
}

@end

@implementation DHTextSelectionRect

@synthesize rect = _rect;
@synthesize writingDirection = _writingDirection;
@synthesize containsStart = _containsStart;
@synthesize containsEnd = _containsEnd;
@synthesize isVertical = _isVertical;

- (instancetype) copyWithZone:(NSZone *)zone
{
    DHTextSelectionRect *rect = [self.class new];
    rect.rect = _rect;
    rect.writingDirection = _writingDirection;
    rect.containsStart = _containsStart;
    rect.containsEnd = _containsEnd;
    rect.isVertical = _isVertical;
    return rect;
}

@end
