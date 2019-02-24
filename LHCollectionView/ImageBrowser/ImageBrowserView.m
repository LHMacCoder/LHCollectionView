//
//  ImageBrowserView.m
//  LHCollectionView
//
//  Created by 浩  林 on 2019/2/23.
//  Copyright © 2019 linhao. All rights reserved.
//

#import "ImageBrowserView.h"

@implementation ImageBrowserView


- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    
    // Drawing code here.
    
}

- (void)setLayerContentImage:(NSImage *)image
{
    if (self.layer == nil)
    {
        self.layer = [[CALayer alloc] init];
        self.layer.contentsGravity = kCAGravityResizeAspect;
    }
    self.layer.contents = image;
}

@end
