//
//  LHSlideTableBackgroundView.h
//  LHCollectionView
//
//  Created by 浩  林 on 2019/2/23.
//  Copyright © 2019 linhao. All rights reserved.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

// 一个简单的NSCollectionView的背景视图，使用NSGradient绘制，或者使用一个图片作为背景
@interface LHSlideTableBackgroundView : NSView
{
    NSGradient *gradient;
    NSImage *image;
}
@property(strong) NSImage *image;
@end

NS_ASSUME_NONNULL_END
