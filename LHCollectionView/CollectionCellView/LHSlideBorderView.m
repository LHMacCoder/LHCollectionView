//
//  LHSlideBorderView.m
//  LHCollectionView
//
//  Created by 浩  林 on 2019/2/24.
//  Copyright © 2019 linhao. All rights reserved.
//

#import "LHSlideBorderView.h"
#import "LHSlideCarrierView.h"


@implementation LHSlideBorderView

#pragma mark Property Accessors

- (NSColor *)borderColor {
    return borderColor;
}

- (void)setBorderColor:(NSColor *)newBorderColor {
    if (borderColor != newBorderColor) {
        borderColor = [newBorderColor copy];
        [self setNeedsDisplay:YES];
    }
}

#pragma mark Visual State

// A AAPLSlideCarrierView wants to receive -updateLayer so it can set its backing layer's contents property, instead of being sent -drawRect: to draw its content procedurally.
- (BOOL)wantsUpdateLayer {
    return YES;
}

- (void)updateLayer {
    CALayer *layer = self.layer;
    layer.borderColor = borderColor.CGColor;
    layer.borderWidth = (borderColor ? SLIDE_BORDER_WIDTH : 0.0);
    layer.cornerRadius = SLIDE_CORNER_RADIUS;
}

@end
