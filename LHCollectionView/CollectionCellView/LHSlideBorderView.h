//
//  LHSlideBorderView.h
//  LHCollectionView
//
//  Created by 浩  林 on 2019/2/24.
//  Copyright © 2019 linhao. All rights reserved.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

// 作为LHSlideCarrierView的子视图，用于突出表现选中状态或者高亮
@interface  LHSlideBorderView: NSView
{
    NSColor *borderColor;
}

@property(copy) NSColor *borderColor;

@end

NS_ASSUME_NONNULL_END
