//
//  DHTextAttribute.m
//  DHTextKit
//
//  Created by Huang Hongsen on 17/5/25.
//  Copyright © 2017年 Huang Hongsen. All rights reserved.
//

#import "DHTextAttribute.h"

NSString *const DHTextInnerShadowAttributeName = @"DHTextInnerShadowAttribute";
NSString *const DHTextShadowAttributeName = @"DHTextShadowAttribute";
NSString *const DHTextAttachmentAttributeName = @"DHTextAttachmentAttribute";
NSString *const DHTextGlyphTransformAttributeName = @"DHTextGlyphTransformAttributeName";
NSString *const DHTextBorderAttributeName = @"DHTextGlyphTransformAttributeName";
NSString *const DHTextBackgroundBorderAttributeName = @"DHTextBackgroundBorderAttributeName";
NSString *const DHTextUnderlineAttributeName = @"DHTextUnderlineAttributeName";
NSString *const DHTextStrikeThroughAttributeName = @"DHTextStrikeThroughAttributeName";
NSString *const DHTextHighlightAttributeName = @"DHTextHighlightAttributeName";

NSString *const DHTextAttachmentToken = @"\uFFFC";
NSString *const DHTextTruncationToken = @"\u2026";

@implementation DHTextAttribute

@end

@implementation DHTextBinding

+ (DHTextBinding *)bindingWithDeleteConfirm:(BOOL)deleteConfirm
{
    DHTextBinding *binding = [DHTextBinding new];
    binding.deleteConfirm = deleteConfirm;
    return binding;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:@(self.deleteConfirm) forKey:@"deleteConfirm"];
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super init];
    _deleteConfirm = ((NSNumber *)[aDecoder decodeObjectForKey:@"deleteConfirm"]).boolValue;
    return self;
}

- (id)copyWithZone:(NSZone *)zone {
    typeof(self) one = [self.class new];
    one.deleteConfirm = self.deleteConfirm;
    return one;
}
@end
