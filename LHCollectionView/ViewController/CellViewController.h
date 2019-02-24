//
//  CellViewController.h
//  LHCollectionView
//
//  Created by 浩  林 on 2019/2/24.
//  Copyright © 2019 linhao. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class LHSlideCarrierView;
@interface CellViewController : NSViewController
{
}
@property(nonatomic,assign) IBOutlet NSImageView *imageView;
@property(nonatomic,assign) IBOutlet LHSlideCarrierView *carrierView;

- (void)setImageFileTitle:(NSString *)title;
- (void)setImageFileKind:(NSString *)kind;
- (void)setImageFileDimensions:(NSString *)Dimensions;
@end
