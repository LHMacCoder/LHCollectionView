//
//  CellViewController.m
//  LHCollectionView
//
//  Created by 浩  林 on 2019/2/24.
//  Copyright © 2019 linhao. All rights reserved.
//

#import "CellViewController.h"

@interface CellViewController()

@property (weak) IBOutlet NSTextField *imageTitle;
@property (weak) IBOutlet NSTextField *imageKind;
@property (weak) IBOutlet NSTextField *imageDimensions;


@end

@implementation CellViewController

- (id)init
{
	if ((self = [super initWithNibName:@"CellViewController" bundle:nil]))
	{
		//
	}
	return self;
}

- (void)setImageFileTitle:(NSString *)title{
    self.imageTitle.stringValue = title;
}
- (void)setImageFileKind:(NSString *)kind{
    self.imageKind.stringValue = kind;

}
- (void)setImageFileDimensions:(NSString *)Dimensions{
    self.imageDimensions.stringValue = Dimensions;

}
- (IBAction)closeGroup:(id)sender {
    
}
- (IBAction)openGroup:(id)sender {
    
}

@end
