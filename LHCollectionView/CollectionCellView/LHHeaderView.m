//
//  LHHeaderView.m
//  LHCollectionView
//
//  Created by 浩  林 on 2019/2/23.
//  Copyright © 2019 linhao. All rights reserved.
//

#import "LHHeaderView.h"

@implementation LHHeaderView

// 返回一个headerview的标题
- (NSTextField *)titleTextField {
    for (NSView *view in self.subviews) {
        if ([view isKindOfClass:[NSTextField class]]) {
            return (NSTextField *)view;
        }
    }
    return nil;
}


// 绘制背景
- (void)drawRect:(NSRect)dirtyRect {
    // Fill with semitransparent white.
    [[NSColor colorWithCalibratedWhite:0.95 alpha:0.8] set];
    NSRectFillUsingOperation(dirtyRect, NSCompositeSourceOver);
    
    // Fill bottom and top edges with semitransparent gray.
    [[NSColor colorWithCalibratedWhite:0.75 alpha:0.8] set];
    NSRect bounds = self.bounds;
    NSRect bottomEdgeRect = bounds;
    bottomEdgeRect.size.height = 1.0;
    NSRectFillUsingOperation(bottomEdgeRect, NSCompositeSourceOver);
    
    NSRect topEdgeRect = bottomEdgeRect;
    topEdgeRect.origin.y = NSMaxY(bounds) - 1.0;
    NSRectFillUsingOperation(topEdgeRect, NSCompositeSourceOver);
}

@end
