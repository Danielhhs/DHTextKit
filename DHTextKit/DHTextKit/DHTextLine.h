//
//  DHTextLine.h
//  DHTextKit
//
//  Created by Huang Hongsen on 17/5/24.
//  Copyright © 2017年 Huang Hongsen. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreText/CoreText.h>
#import <UIKit/UIKit.h>
@interface DHTextLine : NSObject

+ (DHTextLine *) lineWithCTLine:(CTLineRef)ctLine position:(CGPoint)position;

- (void) drawInContext:(CGContextRef)context
                  size:(CGSize)size
              position:(CGPoint)position;

@end
