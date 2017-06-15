//
//  DHTextLayout.m
//  DHTextKit
//
//  Created by Huang Hongsen on 17/5/24.
//  Copyright © 2017年 Huang Hongsen. All rights reserved.
//

#import "DHTextLayout.h"
#import "DHTextUtils.h"

typedef struct {
    CGFloat head;
    CGFloat foot;
} DHRowEdge;

@interface DHTextLayout ()
@property (nonatomic, strong, readwrite) NSArray <DHTextLine *> *lines;
@property (nonatomic, strong, readwrite) NSAttributedString *text;
@property (nonatomic, strong, readwrite) DHTextContainer *container;
@property (nonatomic, readwrite) NSRange range;
@property (nonatomic, readwrite) CTFramesetterRef frameSetter;
@property (nonatomic, readwrite) CTFrameRef frame;
@property (nonatomic, strong, readwrite) NSArray<DHTextAttachment *> *attachments;
@property (nonatomic, strong, readwrite) NSArray<NSValue *> *attachmentRanges;
@property (nonatomic, strong, readwrite) NSArray<NSValue *> *attachmentRects;
@property (nonatomic, readwrite) CGRect textBoundingRect;
@property (nonatomic, strong, readwrite) DHTextLine *truncatedLine;
@property (nonatomic, readwrite) NSRange visibleRange;
@property (nonatomic, readwrite) CGSize textBoundingSize;
@property (nonatomic, readwrite) NSUInteger rowCount;
@property (nonatomic, readwrite) BOOL containsHighlight;

@property (nonatomic, assign) NSUInteger *lineRowsIndex;
@property (nonatomic, assign) DHRowEdge *lineRowsEdge;  //Top left origins for each row;
@property (nonatomic) BOOL rowMightSeperate;
@end

@implementation DHTextLayout
#pragma mark - Initializer
+ (DHTextLayout *) layoutWithContainerSize:(CGSize)size text:(NSAttributedString *)text
{
    DHTextContainer *container = [DHTextContainer containerWithSize:size];
    return [DHTextLayout layoutWithContainer:container text:text];
}

+ (DHTextLayout *) layoutWithContainer:(DHTextContainer *)container
                                  text:(NSAttributedString *)text
{
    if (text == nil) {
        return nil;
    }
    return [DHTextLayout layoutWithContainer:container text:text range:NSMakeRange(0, [text length])];
}

+ (DHTextLayout *) layoutWithContainer:(DHTextContainer *)container text:(NSAttributedString *)text range:(NSRange)range
{
    DHTextLayout *layout = [[DHTextLayout alloc] init];
    layout.text = text;
    layout.container = container;
    layout.range = range;
    layout.maximumNumberOfRows = container.maximumNumberOfRows;
    [layout setup];
    return layout;
}

#pragma mark - Set up
- (void) setup
{
    CGPathRef path = NULL;
    CGRect pathBox = CGRectZero;
    if (self.container.path) {
        path = self.container.path.CGPath;
        pathBox = CGPathGetBoundingBox(path);
    } else {
        CGRect rect = CGRectMake(0, 0, self.container.size.width, self.container.size.height);
        rect = UIEdgeInsetsInsetRect(rect, self.container.insets);
        pathBox = rect;
        UIBezierPath *bezierPath = [UIBezierPath bezierPathWithRect:rect];
        path = bezierPath.CGPath;
    }
    self.frameSetter = CTFramesetterCreateWithAttributedString((CFAttributedStringRef)self.text);
    self.frame = CTFramesetterCreateFrame(self.frameSetter, CFRangeMake(self.range.location, self.range.length), path, NULL);
    
    CFArrayRef ctLines = CTFrameGetLines(self.frame);
    self.visibleRange = [DHTextUtils NSRangeFromCFRange:CTFrameGetVisibleStringRange(self.frame)];
    NSMutableArray *lines = [self setupLinesWithPathBox:pathBox ctLines:ctLines];
    [self truncateWithCTLines:ctLines lines:lines path:path];
    
    self.lines = lines;
    [self updateRowsGeometry];
    [self updateBounds];
    [self updateTextBoundingSize];
}

- (NSMutableArray *) setupLinesWithPathBox:(CGRect)pathBox
                                   ctLines:(CFArrayRef)ctLines
{
    CFIndex numberOfLines = CFArrayGetCount(ctLines);
    NSMutableArray *lines = [NSMutableArray array];
    CGPoint *lineOrigins = malloc(sizeof(CGPoint) * numberOfLines);
    CTFrameGetLineOrigins(self.frame, CFRangeMake(0, numberOfLines), lineOrigins);
    NSUInteger rowIndex = -1;
    NSUInteger rowCount = 0;
    CGRect lastRect = CGRectMake(0, -FLT_MAX, 0, 0);
    CGPoint lastPosition = CGPointMake(0, -FLT_MAX);
    NSUInteger lineCurrentIndex = 0;
    for (NSUInteger lineNo = 0; lineNo < numberOfLines; lineNo++) {
        CTLineRef ctLine = CFArrayGetValueAtIndex(ctLines, lineNo);
        CGPoint lineOrigin = lineOrigins[lineNo];
        
        //Translate lineOrigin to UIKit Coordinate system
        CGPoint position;
        position.x = pathBox.origin.x + lineOrigin.x;
        position.y = pathBox.origin.y + pathBox.size.height - lineOrigin.y;
        DHTextLine *line = [DHTextLine lineWithCTLine:ctLine position:position];
        
        CGRect rect = line.bounds;
        BOOL newRow = YES;
        //Determine whether the line is in a new row;
        //If there's a exclusion path, multiple lines could be in the same row;
        if (self.rowMightSeperate && position.x != lastPosition.x) {
            if (rect.size.height > lastRect.size.height) {
                if (rect.origin.y < lastPosition.y && lastPosition.y < rect.origin.y + rect.size.height) newRow = NO;
            } else {
                if (lastRect.origin.y < position.y && position.y < lastRect.origin.y + lastRect.size.height) newRow = NO;
            }
        }
        if (newRow) rowIndex++;
        lastRect = rect;
        lastPosition = position;
        line.index = lineCurrentIndex;
        line.row = rowIndex;
        [lines addObject:line];
        rowCount = rowIndex + 1;
        lineCurrentIndex++;
        
        if (line.containsHighlight) {
            self.containsHighlight = YES;
        }
    }
    self.rowCount = rowCount;
    return lines;
}

- (void) truncateWithCTLines:(CFArrayRef)ctLines
                       lines:(NSMutableArray *)lines
                        path:(CGPathRef)path
{
    BOOL needTruncation;
    DHTextLine *truncationLine;
    if (self.rowCount > 0) {
        if (self.maximumNumberOfRows > 0) {
            if (self.rowCount > self.maximumNumberOfRows) {
                needTruncation = YES;
                self.rowCount = self.maximumNumberOfRows;
                do {
                    DHTextLine *line = [lines lastObject];
                    if (!line) break;
                    if (line.row < self.rowCount) break;
                    [lines removeLastObject];
                } while(1);
            }
        }
        DHTextLine *lastLine = [lines lastObject];
        if (!needTruncation && lastLine.range.location + lastLine.range.length < [self.text length]) {
            needTruncation = YES;
        }
        NSRange visibleRange = [DHTextUtils NSRangeFromCFRange:CTFrameGetVisibleStringRange(self.frame)];
        if (needTruncation) {
            DHTextLine *lastLine = [lines lastObject];
            NSRange lastRange = lastLine.range;
            visibleRange.length = lastRange.location + lastRange.length - visibleRange.location;
            //Create truncate line
            NSAttributedString *truncationToken;
            if (self.container.truncationType != DHTextTruncationTypeNone) {
                CTLineRef truncationTokenLine = NULL;
                if (self.container.truncationToken) {
                    truncationToken = self.container.truncationToken;
                    truncationTokenLine = CTLineCreateWithAttributedString((CFAttributedStringRef)truncationToken);
                } else {
                    CFArrayRef runs = CTLineGetGlyphRuns(lastLine.ctLine);
                    NSUInteger runCount = CFArrayGetCount(runs);
                    NSMutableDictionary *attributes = nil;
                    if (runCount > 0) {
                        CTRunRef lastRun = CFArrayGetValueAtIndex(runs, runCount - 1);
                        attributes = (id)CTRunGetAttributes(lastRun);
                        attributes = attributes ? [attributes mutableCopy] : [NSMutableDictionary dictionary];
                        [attributes removeObjectsForKeys:@[DHTextAttachmentAttributeName, NSAttachmentAttributeName, (id)kCTRunDelegateAttributeName]];
                        CTFontRef font = (__bridge CFTypeRef)(attributes[(id)kCTFontAttributeName]);
                        CGFloat fontSize = font ? CTFontGetSize(font) : 12.f;
                        UIFont *uiFont = [UIFont systemFontOfSize:fontSize * 0.9];
                        font = CTFontCreateWithName((CFStringRef)uiFont.fontName, uiFont.pointSize, NULL);
                        if (font) {
                            attributes[(id)kCTFontAttributeName] = (__bridge id)font;
                            uiFont = nil;
                            CFRelease(font);
                        }
                        CGColorRef color = (__bridge CGColorRef)(attributes[(id)kCTForegroundColorAttributeName]);
                        if (color && CFGetTypeID(color) == CGColorGetTypeID() && CGColorGetAlpha(color) == 0) {     //If alpha is 0, remove color
                            [attributes removeObjectForKey:(id)kCTForegroundColorAttributeName];
                        }
                        if (attributes == nil) {
                            attributes = [NSMutableDictionary dictionary];
                        }
                    }
                    truncationToken = [[NSAttributedString alloc] initWithString:DHTextTruncationToken attributes:attributes];
                    truncationTokenLine = CTLineCreateWithAttributedString((CFAttributedStringRef)truncationToken);
                }
                if (truncationTokenLine) {
                    CTLineTruncationType type = [DHTextUtils ctLineTruncationTypeFromDHTurncationType:self.container.truncationType];
                    NSMutableAttributedString *lastLineText = [[self.text attributedSubstringFromRange:lastLine.range] mutableCopy];
                    [lastLineText appendAttributedString:truncationToken];
                    CTLineRef lastLineExtend = CTLineCreateWithAttributedString((CFAttributedStringRef)lastLineText);
                    if (lastLineExtend) {
                        CGFloat truncatedWidth = [lastLine width];
                        CGRect cgPathRect = CGRectZero;
                        if (CGPathIsRect(path, &cgPathRect)) {
                            truncatedWidth = cgPathRect.size.width;
                        }
                        CTLineRef ctTruncatedLine = CTLineCreateTruncatedLine(lastLineExtend, truncatedWidth, type, truncationTokenLine);
                        CFRelease(lastLineExtend);
                        if (ctTruncatedLine) {
                            truncationLine = [DHTextLine lineWithCTLine:ctTruncatedLine position:lastLine.position];
                            truncationLine.index = lastLine.index;
                            truncationLine.row = lastLine.index;
                            self.truncatedLine = truncationLine;
                            CFRelease(ctTruncatedLine);
                        }
                    }
                    CFRelease(truncationTokenLine);
                }
                
            }
        }
    }
}

- (void) updateBounds
{
    CGRect textBoundingRect = CGRectZero;
    for (int i = 0; i < [self.lines count]; i++) {
        DHTextLine *line = self.lines[i];
        if (i == 0) textBoundingRect = line.bounds;
        else textBoundingRect = CGRectUnion(textBoundingRect, line.bounds);
    }
    UIEdgeInsets insets = self.container.insets;
    UIEdgeInsets insetsInverse = UIEdgeInsetsMake(-insets.top, -insets.left, -insets.bottom, -insets.right);
    textBoundingRect = UIEdgeInsetsInsetRect(textBoundingRect, insetsInverse);
    self.textBoundingRect = textBoundingRect;
}

- (void) updateTextBoundingSize
{
    CGRect rect = self.textBoundingRect;
    DHTextContainer *container = self.container;
    if (container.path) {
        if (container.pathLineWidth > 0) {
            CGFloat inset = container.pathLineWidth / 2;
            rect = CGRectInset(rect, -inset, -inset);
        }
    } else {
        UIEdgeInsets insets = self.container.insets;
        insets = UIEdgeInsetsMake(-insets.top, -insets.left, -insets.bottom, -insets.right);
        rect = UIEdgeInsetsInsetRect(rect, insets);
    }
    rect = CGRectStandardize(rect);
    CGSize size = rect.size;
    size.width += rect.origin.x;
    size.height += rect.origin.y;
    if (size.width < 0) size.width = 0;
    if (size.height < 0) size.height = 0;
    size.width = ceil(size.width);
    size.height = ceil(size.height);
    self.textBoundingSize = size;
}

- (void) updateRowsGeometry
{
    if (self.rowCount > 0) {
        self.lineRowsEdge = calloc(_rowCount, sizeof(DHRowEdge));
        self.lineRowsIndex = calloc(_rowCount, sizeof(NSUInteger));
        NSInteger lastRowIdx = -1;
        CGFloat lastHead = 0;
        CGFloat lastFoot = 0;
        for (NSUInteger i = 0; i < [self.lines count]; i++) {
            DHTextLine *line = self.lines[i];
            CGRect rect = line.bounds;
            if ((NSInteger)line.row != lastRowIdx) {
                if (lastRowIdx >= 0) {
                    _lineRowsEdge[lastRowIdx] = (DHRowEdge) {.head = lastHead, .foot = lastFoot};
                }
                lastRowIdx = line.row;
                _lineRowsIndex[lastRowIdx] = i;
                lastHead = rect.origin.y;
                lastFoot = lastHead + rect.size.height;
            } else {
                lastHead = MAX(lastHead, rect.origin.y);
                lastFoot = MAX(lastFoot, rect.origin.y + rect.size.height);
            }
        }
        _lineRowsEdge[lastRowIdx] = (DHRowEdge){.head = lastHead, .foot = lastFoot};
        
        for (NSUInteger i = 1; i < _rowCount; i++) {
            DHRowEdge v0 = _lineRowsEdge[i - 1];
            DHRowEdge v1 = _lineRowsEdge[i];
            _lineRowsEdge[i - 1].foot = _lineRowsEdge[i - 1].head = (v0.foot + v1.head) * 0.5;
        }
    }
    
}

#pragma mark - Drawing
- (void) drawInContext:(CGContextRef)context
                  size:(CGSize)size
                 point:(CGPoint)point
                  view:(UIView *)view
                 layer:(CALayer *)layer
                cancel:(BOOL (^)(void))cancel
{
    CGContextSaveGState(context);
    CGContextTranslateCTM(context, point.x, point.y);
    CGContextTranslateCTM(context, 0, size.height);
    CGContextScaleCTM(context, 1, -1);
    for (int i = 0; i < [self.lines count]; i++) {
        DHTextLine *line = self.lines[i];
        if (self.truncatedLine && line.index == self.truncatedLine.index) {
            line = self.truncatedLine;
        }
        [line drawInContext:context size:size position:point inView:view orLayer:layer];
    }
    CGContextRestoreGState(context);
}

#pragma mark - Get Information
- (NSUInteger) lineIndexForPoint:(CGPoint)point
{
    if ([self.lines count] == 0) return NSNotFound;
    
    for (int i = 0; i < [self.lines count]; i++) {
        CGRect bounds = self.lines[i].bounds;
        if (CGRectContainsPoint(bounds, point)) return i;
    }
    return NSNotFound;
}

- (NSUInteger) closestLineIndexForPoint:(CGPoint)point
{
    if ([self.lines count] == 0) return NSNotFound;
    
    NSUInteger rowIdx = [self _closestRowIndexForEdge:point.y];
    if (rowIdx == NSNotFound) return NSNotFound;
    
    NSUInteger lineIdx0 = _lineRowsIndex[rowIdx];
    NSUInteger lineIdx1 = rowIdx = _rowCount - 1 ? [self.lines count] - 1 : _lineRowsIndex[rowIdx + 1] - 1;
    if (lineIdx0 == lineIdx1) return lineIdx0;
        
    CGFloat minDistance = CGFLOAT_MAX;
    NSUInteger minIndex = lineIdx0;
    for (NSUInteger i = lineIdx0; i < lineIdx1; i++) {
        CGRect bounds = self.lines[i].bounds;
        if (bounds.origin.x <= point.x && point.x <= bounds.origin.x + bounds.size.width) return i;
        CGFloat distance;
        if (point.x < bounds.origin.x) {
            distance = bounds.origin.x - point.x;
        } else {
            distance = point.x - (bounds.origin.x + bounds.size.width);
        }
        if (distance < minDistance) {
            minDistance = distance;
            minIndex =i;
        }
    }
    return minIndex;
}

- (NSUInteger) textPositionForPoint:(CGPoint)point lineIndex:(NSUInteger)lineIndex
{
    if (lineIndex > [self.lines count]) return NSNotFound;
    DHTextLine *line = self.lines[lineIndex];
    point.x -= line.position.x;
    point.y = 0;
    CFIndex idx = CTLineGetStringIndexForPosition(line.ctLine, point);
    if (idx == kCFNotFound) return NSNotFound;
    
    //TO-DO: Handle Emoji case;
    return idx;
}

- (DHTextPosition *) closestPositionToPoint:(CGPoint)point
{
    point.x += 0.001234;    //Avoid ligature problem from core text;
    NSUInteger lineIndex = [self closestLineIndexForPoint:point];
    if (lineIndex == NSNotFound) return nil;
    DHTextLine *line = self.lines[lineIndex];
    __block NSUInteger position = [self textPositionForPoint:point lineIndex:lineIndex];
    if (position < self.visibleRange.location) {
        return [DHTextPosition positionWithOffset:_visibleRange.location affinity:DHTextAffinityForward];
    } else if (position > self.visibleRange.location + self.visibleRange.length) {
        return [DHTextPosition positionWithOffset:_visibleRange.location + _visibleRange.length affinity:DHTextAffinityForward];
    }
    
    DHTextAffinity affinity = DHTextAffinityForward;
    
    //empty line
    if (line.range.length == 0) {
        BOOL behind = ([self.lines count] > 1 && lineIndex == [self.lines count] - 1);  //Last line
        return [DHTextPosition positionWithOffset:line.range.location affinity:behind ? DHTextAffinityBackward : DHTextAffinityForward];
    }
    
    //the line is just a line break
    if (line.range.length <= 2) {
        NSString *str = [self.text.string substringWithRange:line.range];
        if ([DHTextUtils isLineBreakString:str]) {
            return [DHTextPosition positionWithOffset:line.range.location];
        }
    }
    
    // There must be at least one non-linebreak char,
    // ignore the linebreak characters at line end if exists.
    if (position >= line.range.location + line.range.length - 1) {
        if (position > line.range.location) {
            unichar c1 = [self.text.string characterAtIndex:position - 1];
            if ([DHTextUtils isLineBreakChar:c1]) {
                position--;
                if (position > line.range.location) {
                    unichar c0 = [self.text.string characterAtIndex:position - 1];
                    if ([DHTextUtils isLineBreakChar:c0]) {
                        position--;
                    }
                }
            }
        }
    }
    if (position == line.range.location) {
        return [DHTextPosition positionWithOffset:position];
    }
    if (position == line.range.location + line.range.length) {
        return [DHTextPosition positionWithOffset:position affinity:DHTextAffinityBackward];
    }
    
    if (position < self.visibleRange.location) position = self.visibleRange.location;
    else if (position > self.visibleRange.location + self.visibleRange.length) position = self.visibleRange.location + self.visibleRange.length;
    
    return [DHTextPosition positionWithOffset:position affinity:affinity];
}

- (DHTextPosition *) positionForPoint:(CGPoint)point
                     previousPosition:(DHTextPosition *)previousPosition
                     theOtherPosition:(DHTextPosition *)theOtherPosition
{
    if (!previousPosition || !theOtherPosition) {
        return previousPosition;
    }
    DHTextPosition *newPos = [self closestPositionToPoint:point];
    if (!newPos) return previousPosition;
    //New pos and previous pos are on the same side of the other position; and they are not the same one
    if ([newPos compare:theOtherPosition] == [previousPosition compare:theOtherPosition] && newPos.offset != theOtherPosition.offset) {
        return newPos;
    }
    
    NSUInteger lineIndex = [self lineIndexForPoint:point];
    if (lineIndex == NSNotFound) return previousPosition;
    
    newPos = [self closestPositionToPoint:point];
    if ([newPos compare:theOtherPosition] == [previousPosition compare:theOtherPosition] && newPos.offset != theOtherPosition.offset) {
        return newPos;
    }
    //TO-DO: Not yet done
    
    if ([previousPosition compare:theOtherPosition] == NSOrderedAscending) {
        DHTextRange *range = [self textRangeByExtendingPosition:theOtherPosition inDirection:UITextLayoutDirectionLeft offset:1];
        if (range) return range.start;
    } else {
        DHTextRange *range = [self textRangeByExtendingPosition:theOtherPosition inDirection:UITextLayoutDirectionRight offset:1];
        if (range) return range.end;
    }
    return previousPosition;
}

- (DHTextRange *) textRangeAtPoint:(CGPoint)point
{
    NSUInteger lineIndex = [self lineIndexForPoint:point];
    if (lineIndex == NSNotFound) return nil;
    NSUInteger textPosition = [self textPositionForPoint:point lineIndex:lineIndex];
    if (textPosition == NSNotFound) return nil;
    DHTextPosition *pos = [self closestPositionToPoint:point];
    if (!pos) return nil;
    
    BOOL rightToLeft = [self _isRightToLeftInLine:self.lines[lineIndex] atPoint:point];
    CGRect rect = [self caretRectForPosition:pos];
    if (CGRectIsNull(rect)) return nil;
    
    DHTextRange*range = [self textRangeByExtendingPosition:pos inDirection:(rect.origin.x > point.x && !rightToLeft) ? UITextLayoutDirectionLeft : UITextLayoutDirectionRight offset:1];
    return range;
}

- (DHTextRange *) closestTextRangeAtPoint:(CGPoint)point
{
    DHTextPosition *pos = [self closestPositionToPoint:point];
    if (!pos) return nil;
    NSUInteger lineIndex = [self lineIndexForPosition:pos];
    if (lineIndex == NSNotFound) return nil;
    DHTextLine *line = self.lines[lineIndex];
    BOOL RTL = [self _isRightToLeftInLine:line atPoint:point];
    CGRect rect = [self caretRectForPosition:pos];
    if (CGRectIsNull(rect)) return nil;
    
    UITextLayoutDirection direction = UITextLayoutDirectionRight;
    if (pos.offset >= line.range.location + line.range.length) {
        if (direction != RTL) {
            direction = UITextLayoutDirectionLeft;
        } else {
            direction = UITextLayoutDirectionRight;
        }
    } else if (pos.offset <= line.range.location) {
        if (direction != RTL) {
            direction = UITextLayoutDirectionRight;
        } else {
            direction = UITextLayoutDirectionLeft;
        }
    } else {
        direction = (rect.origin.x >= point.x && !RTL) ? UITextLayoutDirectionLeft : UITextLayoutDirectionRight;
    }
    DHTextRange *range = [self textRangeByExtendingPosition:pos inDirection:direction offset:1];
    return range;
}

- (DHTextRange *) textRangeByExtendingPosition:(DHTextPosition *)position
{
    NSUInteger visibleStart = self.visibleRange.location;
    NSUInteger visibleEnd = self.visibleRange.location + self.visibleRange.length;
    if (!position) return nil;
    
    if (position.offset < visibleStart || position.offset > visibleEnd) return nil;
    
    //For position at the beginning or the end;
    if (position.offset == visibleStart) {
        return [DHTextRange rangeWithNSRange:NSMakeRange(position.offset, 0)];
    } else  if (position.offset == visibleEnd) {
        return [DHTextRange rangeWithNSRange:NSMakeRange(position.offset, 0) affinity:DHTextAffinityBackward];
    }
    
    //Handle line break
    if (position.offset > visibleStart && position.offset < visibleEnd) {
        unichar c0 = [self.text.string characterAtIndex:position.offset - 1];
        if ((c0 == '\r') && position.offset < visibleEnd) {
            unichar c1 = [self.text.string characterAtIndex:position.offset];
            if (c1 == '\n') {
                return [DHTextRange rangeWithStart:[DHTextPosition positionWithOffset:position.offset - 1] end:[DHTextPosition positionWithOffset:position.offset + 1]];
            }
        }
        if ([DHTextUtils isLineBreakChar:c0] && position.affinity == DHTextAffinityBackward) {
            NSString *str = [self.text.string substringToIndex:position.offset];
            NSUInteger len = [DHTextUtils lineBreakTailLength:str];
            return [DHTextRange rangeWithStart:[DHTextPosition positionWithOffset:position.offset - len] end:[DHTextPosition positionWithOffset:position.offset]];
        }
    }
    return [DHTextRange rangeWithNSRange:NSMakeRange(position.offset, 0) affinity:position.affinity];
}

- (DHTextRange *) textRangeByExtendingPosition:(DHTextPosition *)position inDirection:(UITextLayoutDirection)direction offset:(NSInteger)offset
{
    NSUInteger visibleStart = self.visibleRange.location;
    NSUInteger visibleEnd = self.visibleRange.location + self.visibleRange.length;
    if (!position) return nil;
    
    if (position.offset < visibleStart || position.offset > visibleEnd) return nil;
    if (offset == 0) return [self textRangeByExtendingPosition:position];
    
    BOOL verticalMove, forwardMove;
    verticalMove = (direction == UITextLayoutDirectionUp || direction == UITextLayoutDirectionDown);
    forwardMove = (direction == UITextLayoutDirectionDown || direction == UITextLayoutDirectionRight);
    
    if (offset < 0) {
        forwardMove = !forwardMove;
        offset = -offset;
    }
    
    //At beginning or at end
    if (!forwardMove && position.offset == visibleStart) {
        return [DHTextRange rangeWithNSRange:NSMakeRange(visibleStart, 0)];
    } else if (forwardMove && position.offset == visibleEnd) {
        return [DHTextRange rangeWithNSRange:NSMakeRange(position.offset, 0) affinity:DHTextAffinityBackward];
    }
    
    DHTextRange *fromRange = [self textRangeByExtendingPosition:position];
    if (!fromRange) return nil;
    DHTextRange *allForward = [DHTextRange rangeWithStart:fromRange.start end:[DHTextPosition positionWithOffset:visibleEnd]];
    DHTextRange *allBackward = [DHTextRange rangeWithStart:[DHTextPosition positionWithOffset:visibleStart] end:fromRange.end];
    
    DHTextPosition *toPosition = [DHTextPosition positionWithOffset:position.offset + (forwardMove ? offset : -offset)];
    if (toPosition.offset < visibleStart) return allBackward;
    else if (toPosition.offset > visibleEnd) return allForward;
    
    DHTextRange *toRange = [self textRangeByExtendingPosition:toPosition];
    if (!toRange)  return nil;
    NSInteger start = MIN(fromRange.start.offset, toRange.start.offset);
    NSInteger end = MAX(fromRange.end.offset, toRange.end.offset);
    return [DHTextRange rangeWithNSRange:NSMakeRange(start, end - start)];
}

- (NSUInteger) lineIndexForPosition:(DHTextPosition *)position
{
    if (!position) return NSNotFound;
    if ([self.lines count] == 0) return NSNotFound;
    NSUInteger location = position.offset;
    NSInteger lo = 0, hi = [self.lines count] - 1, mid = 0;
    if (position.affinity == DHTextAffinityBackward) {
        while (lo < hi) {
            mid = (lo + hi) / 2;
            DHTextLine *line = self.lines[mid];
            NSRange range = line.range;
            if (range.location < location && location <= range.location + range.length) {
                return mid;
            }
            if (location <= range.location) {
                hi = mid - 1;
            } else {
                lo = mid + 1;
            }
        }
    } else {
        while (lo <= hi) {
            mid = (lo + hi) / 2;
            DHTextLine *line = self.lines[mid];
            NSRange range = line.range;
            if (range.location <= location && location < range.location + range.length) {
                return mid;
            }
            if (location < range.location) {
                hi = mid - 1;
            } else {
                lo = mid + 1;
            }
        }
    }
    return NSNotFound;
}

- (CGPoint) linePositionForPosition:(DHTextPosition *)position
{
    NSUInteger lineIndex = [self lineIndexForPosition:position];
    if (lineIndex == NSNotFound) return CGPointZero;
    DHTextLine *line = self.lines[lineIndex];
    CGFloat offset = [self offsetForPosition:position.offset lineIndex:lineIndex];
    if (offset == CGFLOAT_MAX) return CGPointZero;
    return CGPointMake(offset, line.position.y);
}

- (CGRect) caretRectForPosition:(DHTextPosition *)position
{
    NSUInteger lineIndex = [self lineIndexForPosition:position];
    if (lineIndex == NSNotFound) return CGRectNull;
    DHTextLine *line = self.lines[lineIndex];
    CGFloat offset = [self offsetForPosition:position.offset lineIndex:lineIndex];
    if (offset == CGFLOAT_MAX) return CGRectNull;
    return CGRectMake(offset, line.bounds.origin.x, 0, line.bounds.size.height);
}

- (CGRect) firstRectForRange:(DHTextRange *)range
{
    range = [self _correctedRangeWithEdge:range];
    NSUInteger startLineIndex = [self lineIndexForPosition:range.start];
    NSUInteger endLineIndex = [self lineIndexForPosition:range.end];
    if (startLineIndex == NSNotFound || endLineIndex == NSNotFound) return CGRectNull;
    if (startLineIndex > endLineIndex) return CGRectNull;
    
    DHTextLine *startLine = self.lines[startLineIndex];
    DHTextLine *endLine = self.lines[endLineIndex];
    NSMutableArray *lines = [NSMutableArray array];
    for (NSUInteger i = startLineIndex; i <= endLineIndex; i++) {
        DHTextLine *line = self.lines[i];
        if (line.row != startLine.row) break;
        [lines addObject:line];
    }
    if ([lines count] == 1) {
        CGFloat left = [self offsetForPosition:range.start.offset lineIndex:startLineIndex];
        CGFloat right;
        if (startLine == endLine) {
            right = [self offsetForPosition:range.end.offset lineIndex:startLineIndex];
        } else {
            right = startLine.right;
        }
        if (left == CGFLOAT_MAX || right == CGFLOAT_MAX) return CGRectNull;
        if (left > right) DH_SWAP(left, right);
        return CGRectMake(left, startLine.top, right - left, startLine.height);
    } else {
        CGFloat left = [self offsetForPosition:range.start.offset lineIndex:startLineIndex];
        CGFloat right = startLine.right;
        if (left == CGFLOAT_MAX || right == CGFLOAT_MAX) return CGRectNull;
        if (left > right) DH_SWAP(left, right);
        CGRect rect  = CGRectMake(left, startLine.top, right - left, startLine.height);
        for (NSUInteger i = 1; i < [lines count]; i++) {
            DHTextLine *line = lines[i];
            rect = CGRectUnion(rect, line.bounds);
        }
        return rect;
    }
}

- (CGRect) rectForRange:(DHTextRange *)range
{
    NSArray *rects = [self selectionRectsForRange:range];
    if ([rects count] == 0) return CGRectNull;
    CGRect rectUnion = ((DHTextSelectionRect *)[rects firstObject]).rect;
    for (NSUInteger i = 1; i < [rects count]; i++) {
        DHTextSelectionRect *rect = rects[i];
        rectUnion = CGRectUnion(rectUnion, rect.rect);
    }
    return rectUnion;
}

- (NSArray<DHTextSelectionRect *> *) selectionRectsForRange:(DHTextRange *)range
{
    range = [self _correctedRangeWithEdge:range];
    NSMutableArray *rects = [NSMutableArray array];
    if (!range) return rects;
    
    NSUInteger startLineIndex = [self lineIndexForPosition:range.start];
    NSUInteger endLineIndex = [self lineIndexForPosition:range.end];
    if (startLineIndex == NSNotFound || endLineIndex == NSNotFound) return rects;
    if (startLineIndex > endLineIndex) DH_SWAP(startLineIndex, endLineIndex);
    
    DHTextLine *startLine = self.lines[startLineIndex];
    DHTextLine *endLine = self.lines[endLineIndex];
    
    CGFloat offsetStart = [self offsetForPosition:range.start.offset lineIndex:startLineIndex];
    CGFloat offsetEnd = [self offsetForPosition:range.start.offset lineIndex:endLineIndex];
    
    DHTextSelectionRect *startRect = [DHTextSelectionRect new];
    startRect.rect = CGRectMake(offsetStart, startLine.top, 0, startLine.height);
    startRect.containsStart = YES;
    [rects addObject:startRect];
    
    DHTextSelectionRect *endRect = [DHTextSelectionRect new];
    endRect.rect = CGRectMake(offsetEnd, endLine.top, 0, endLine.height);
    endRect.containsEnd = YES;
    [rects addObject:endRect];
    
    if (startLine.row == endLine.row) {
        //More than one row case; If there are exclusion paths, there might be more than one ctLine in one 'row';
        //Currently, we did not put exclusion path into consideration;
        if (offsetStart > offsetEnd) DH_SWAP(offsetStart, offsetEnd);
        DHTextSelectionRect *rect = [DHTextSelectionRect new];
        rect.rect = CGRectMake(offsetStart, startLine.bounds.origin.y, offsetEnd - offsetStart, endLine.height);
        [rects addObject:rect];
    } else {
        DHTextSelectionRect *topRect = [DHTextSelectionRect new];
        CGFloat topOffset = [self offsetForPosition:range.start.offset lineIndex:startLineIndex];
        CTRunRef topRun = [startLine runAtPosition:range.start];
        if (topRun && (CTRunGetStatus(topRun) & kCTRunStatusRightToLeft)) {
            topRect.rect = CGRectMake(_container.path ? startLine.left : _container.insets.left, startLine.top, startLine.width, startLine.height);
            topRect.writingDirection = UITextWritingDirectionRightToLeft;
        } else {
            topRect.rect = CGRectMake(topOffset, startLine.top, (_container.path ? startLine.right : _container.size.width - _container.insets.right) - topOffset, startLine.height);
        }
        [rects addObject:topRect];
        
        DHTextSelectionRect *bottomRect = [DHTextSelectionRect new];
        CGFloat bottomOffset = [self offsetForPosition:range.end.offset lineIndex:endLineIndex];
        CTRunRef bottomRun = [endLine runAtPosition:range.end];
        if (bottomRun && (CTRunGetStatus(bottomRun) & kCTRunStatusRightToLeft)) {
            bottomRect.rect = CGRectMake(bottomOffset, endLine.top, (_container.path ? endLine.right : _container.size.width - _container.insets.right) - bottomOffset, endLine.height);
            bottomRect.writingDirection = UITextWritingDirectionRightToLeft;
        } else {
            CGFloat left = _container.path ? endLine.left : _container.insets.left;
            bottomRect.rect = CGRectMake(left, endLine.top, bottomOffset - left, endLine.height);
        }
        [rects addObject:bottomRect];
        
        if (endLineIndex - startLineIndex >= 2) {
            CGRect r = CGRectZero;
            BOOL startLineDetected = NO;
            for (NSUInteger l = startLineIndex + 1; l < endLineIndex; l++) {
                DHTextLine *line = self.lines[l];
                if (line.row == startLine.row || line.row == endLine.row) continue;
                if (!startLineDetected) {
                    r = line.bounds;
                    startLineDetected = YES;
                }else {
                    r = CGRectUnion(r, line.bounds);
                }
            }
            if (startLineDetected) {
                if (!_container.path) {
                    r.origin.x = _container.insets.left;
                    r.size.width = _container.size.width - _container.insets.right - _container.insets.left;
                }
                r.origin.y = CGRectGetMaxY(topRect.rect);
                r.size.height = bottomRect.rect.origin.y - r.origin.y;
                
                DHTextSelectionRect *rect = [DHTextSelectionRect new];
                rect.rect = r;
                [rects addObject:rect];
            }
        } else {
            CGRect r0 = topRect.rect;
            CGRect r1 = bottomRect.rect;
            CGFloat mid = (CGRectGetMaxY(r0) + CGRectGetMinY(r1)) * 0.5;
            r0.size.height = mid - r0.origin.y;
            CGFloat r1offset = r1.origin.y - mid;
            r1.origin.y -= r1offset;
            r1.size.height += r1offset;
            topRect.rect = r0;
            bottomRect.rect = r1;
        }
    }
    return rects;
}

- (NSArray <DHTextSelectionRect *> *) selectionRectsWithoutStartAndEndForRange:(DHTextRange *)range
{
    NSMutableArray *rects = [[self selectionRectsForRange:range] mutableCopy];
    NSMutableArray *rectsToRemove = [NSMutableArray array];
    for (NSInteger i = 0; i < [rects count]; i++) {
        DHTextSelectionRect *rect = rects[i];
        if (rect.containsStart || rect.containsEnd) {
            [rectsToRemove addObject:rect];
        }
    }
    [rects removeObjectsInArray:rectsToRemove];
    return rects;
}

- (NSArray <DHTextSelectionRect *> *) selectionRectsWithOnlyStartAndEndForRange:(DHTextRange *)range
{
    NSMutableArray *rects = [[self selectionRectsForRange:range] mutableCopy];
    NSMutableArray *rectsToRemove = [NSMutableArray array];
    for (NSInteger i = 0; i < [rects count]; i++) {
        DHTextSelectionRect *rect = rects[i];
        if (!rect.containsStart && !rect.containsEnd) {
            [rectsToRemove addObject:rect];
        }
    }
    [rects removeObjectsInArray:rectsToRemove];
    return rects;
}

- (CGFloat) offsetForPosition:(NSUInteger)position lineIndex:(NSUInteger)lineIndex
{
    if (lineIndex > [self.lines count]) return CGFLOAT_MAX;
    DHTextLine *line = self.lines[lineIndex];
    CFRange range = CTLineGetStringRange(line.ctLine);
    if (position < range.location || position > range.location + range.length) return CGFLOAT_MAX;
    
    CGFloat offset = CTLineGetOffsetForStringIndex(line.ctLine, position, NULL);
    return offset + line.position.x;
}

#pragma mark - Private helpers
- (BOOL) _isRightToLeftInLine:(DHTextLine *)line atPoint:(CGPoint)point
{
    if (!line) return NO;
    BOOL RTL = NO;
    CFArrayRef runs = CTLineGetGlyphRuns(line.ctLine);
    for (NSUInteger r = 0, max = CFArrayGetCount(runs); r < max; r++) {
        CTRunRef run = CFArrayGetValueAtIndex(runs, r);
        CGPoint glyphPosition;
        CTRunGetPositions(run, CFRangeMake(0, 1), &glyphPosition);
        CGFloat runX = glyphPosition.x;
        runX += line.position.x;
        CGFloat runWidth = CTRunGetTypographicBounds(run, CFRangeMake(0, 0), NULL, NULL, NULL);
        if (runX <= point.x && point.x < runX + runWidth) {
            if (CTRunGetStatus(run) & kCTRunStatusRightToLeft) RTL = YES;
            break;
        }
    }
    return RTL;
}

- (DHTextRange *)_correctedRangeWithEdge:(DHTextRange *)range {
    NSRange visibleRange = self.visibleRange;
    DHTextPosition *start = range.start;
    DHTextPosition *end = range.end;
    
    if (start.offset == visibleRange.location && start.affinity == DHTextAffinityBackward) {
        start = [DHTextPosition positionWithOffset:start.offset affinity:DHTextAffinityForward];
    }
    if (end.offset == visibleRange.location + visibleRange.length && start.affinity == DHTextAffinityForward) {
        end = [DHTextPosition positionWithOffset:end.offset affinity:DHTextAffinityBackward];
    }
    if (start != range.start || end != range.end) {
        range = [DHTextRange rangeWithStart:start end:end];
    }
    return range;
}

- (NSUInteger) _closestRowIndexForEdge:(CGFloat) edge
{
    if ([self.lines count] == 0) return NSNotFound;
    NSUInteger rowIdx = [self _rowIndexForEdge:edge];
    if (rowIdx == NSNotFound) {
        if (edge < _lineRowsEdge[0].head) {
            rowIdx = 0;
        } else if (edge > _lineRowsEdge[_rowCount - 1].foot) {
            rowIdx = _rowCount - 1;
        }
    }
    return rowIdx;
}

- (NSUInteger) _rowIndexForEdge:(CGFloat) edge
{
    if ([self.lines count] == 0) return NSNotFound;
    NSInteger lo = 0, hi = [self.lines count] - 1, mid = 0;
    NSUInteger rowIdx = NSNotFound;
    while (lo <= hi) {
        mid = (lo + hi) / 2;
        DHRowEdge oneEdge = _lineRowsEdge[mid];
        if (oneEdge.head <= edge && edge <= oneEdge.foot) {
            rowIdx = mid;
            break;
        }
        if (edge < oneEdge.head) {
            if (mid == 0) break;
            hi = mid - 1;
        } else {
            lo = mid + 1;
        }
    }
    return rowIdx;
}

@end
