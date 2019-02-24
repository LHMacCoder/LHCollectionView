//
//  LHImageBrowser.m
//  LHCollectionView
//
//  Created by 浩  林 on 2019/2/23.
//  Copyright © 2019 linhao. All rights reserved.//

#import "LHImageBrowser.h"
#import "LHImageFile.h"
#import "ImageBrowserView.h"

@interface LHImageBrowser ()

@property (weak) IBOutlet NSTextField *indexText;

@end

@implementation LHImageBrowser

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
    
    LHImageFile *imageFile = [self.imageArray objectAtIndex: _currentIndex];
    NSImage *image = [[NSImage alloc] initWithContentsOfURL:imageFile.url];
    ImageBrowserView *view = (ImageBrowserView *)self.view;
    [view setLayerContentImage:image];
    
    self.imageCount = _imageArray.count;

    self.indexText.stringValue = [NSString stringWithFormat:@"%li/%li",_currentIndex + 1,_imageCount];
}

- (void)updateViewImage:(NSUInteger)index
{

    LHImageFile *imageFile = [self.imageArray objectAtIndex: index];
    NSImage *image = [[NSImage alloc] initWithContentsOfURL:imageFile.url];
    ImageBrowserView *view = (ImageBrowserView *)self.view;
    [view setLayerContentImage:image];
}

- (IBAction)preViewImage:(id)sender {
    if (_currentIndex == 0)
    {
        self.currentIndex = _imageCount;
        self.indexText.stringValue = [NSString stringWithFormat:@"%li/%li",_currentIndex,_imageCount];
        [self updateViewImage:_currentIndex - 1];
    }
    else
    {
        self.indexText.stringValue = [NSString stringWithFormat:@"%li/%li",_currentIndex,_imageCount];
        self.currentIndex --;
        [self updateViewImage:_currentIndex];
    }
}

- (IBAction)nextImage:(id)sender {
    if (_currentIndex == _imageCount - 1)
    {
        self.currentIndex = 0;
        self.indexText.stringValue = [NSString stringWithFormat:@"%li/%li",_currentIndex + 1,_imageCount];
        [self updateViewImage:_currentIndex];
    }
    else
    {
        self.currentIndex ++;
        self.indexText.stringValue = [NSString stringWithFormat:@"%li/%li",_currentIndex + 1,_imageCount];
        [self updateViewImage:_currentIndex];

    }

}

- (void)dealloc
{
    NSLog(@"%s",__func__);
}

@end
