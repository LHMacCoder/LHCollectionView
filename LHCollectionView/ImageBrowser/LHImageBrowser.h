//
//  LHImageBrowser.h
//  LHCollectionView
//
//  Created by 浩  林 on 2019/2/23.
//  Copyright © 2019 linhao. All rights reserved.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface LHImageBrowser : NSViewController

@property (weak) IBOutlet NSImageView *imageView;
@property (strong) NSArray *imageArray;
@property (assign) NSUInteger currentIndex;
@property (assign) NSUInteger imageCount;


@end

NS_ASSUME_NONNULL_END
