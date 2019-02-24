//
//  Controller.m
//  LHCollectionView
//
//  Created by 浩  林 on 2019/2/24.
//  Copyright © 2019 linhao. All rights reserved.
//

#import "Controller.h"
#import "CellViewController.h"
#import "GroupViewController.h"
#import "BCCollectionViewGroup.h"


#import "LHImageCollection.h"
#import "LHSlideCarrierView.h"
#import "LHImageFile.h"
#import "LHTag.h"
#import "CellViewController.h"


#import "JMModalOverlay.h"
#import "LHImageBrowser.h"

@interface Controller ()
{
    JMModalOverlay *_modalOverlay;
}

@end

@implementation Controller
@synthesize collectionView;
@synthesize imageContent;
@synthesize imageCollection;

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    imageContent = [[NSMutableArray alloc] init];
    
    _modalOverlay = [[JMModalOverlay alloc] init];
    
    self.imageCollection = [[LHImageCollection alloc] initWithRootURL:[NSURL fileURLWithPath:@"/Library/Desktop Pictures"]];
    [self.imageCollection startOrRestartFileTreeScan];
    
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.collectionView reloadDataWithItemsEmptyCaches:YES];
        
    });
}

- (IBAction)reloadImage:(id)sender {
    //    TSImageCollection *collection = [[TSImageCollection alloc] initWithRootURL:[NSURL fileURLWithPath:@"/Users/tenorshare/Downloads"]];
    //    [collection startOrRestartFileTreeScan];
    //
    //    //    [self.collectionView reloadDataWithItems:self.imageCollection emptyCaches:YES];
    //
    //    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
    //        [self.collectionView reloadDataWithItems:collection emptyCaches:NO];
    //
    //    });
    
    //    self.imageCollection = nil;
    
    self.imageCollection = [[LHImageCollection alloc] initWithRootURL:[NSURL fileURLWithPath:@"/Library/Desktop Pictures"]];
    [self.imageCollection startOrRestartFileTreeScan];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.collectionView reloadDataWithItemsEmptyCaches:YES];
        
    });
}


#pragma mark -
#pragma mark BCCollectionViewDelegate

//CollectionView assumes all cells are the same size and will resize its subviews to this size.
- (NSSize)cellSizeForCollectionView:(BCCollectionView *)collectionView
{
    return NSMakeSize(140, 140);
}

//Return an empty ViewController, this might not be visible to the user immediately
- (NSViewController *)reusableViewControllerForCollectionView:(BCCollectionView *)collectionView
{
    return [[CellViewController alloc] init];
}

- (NSArray *)groupViewFromDataSource:(NSMutableArray *)totalItemArray
{
    NSMutableArray *tagArray = [NSMutableArray new];
    NSInteger i = 0;
    
    for (LHTag *tag in imageCollection.tags)
    {
        BCCollectionViewGroup *group = [BCCollectionViewGroup groupWithTitle:tag.name range:NSMakeRange(i, tag.imageFiles.count) itemArray:tag.imageFiles];
        
        [totalItemArray addObjectsFromArray:tag.imageFiles];
        group.isCollapsed = NO;
        [tagArray addObject:group];
        i += tag.imageFiles.count;
    }
    if (imageCollection.untaggedImageFiles.count > 0)
    {
        [totalItemArray addObjectsFromArray:imageCollection.untaggedImageFiles];
        
        BCCollectionViewGroup *group = [BCCollectionViewGroup groupWithTitle:@"Untagged" range:NSMakeRange(i, imageCollection.untaggedImageFiles.count) itemArray:imageCollection.untaggedImageFiles];
        group.isCollapsed = NO;
        [tagArray addObject:group];
    }
    return tagArray;
}

//The CollectionView is about to display the ViewController. Use this method to populate the ViewController with data
- (void)collectionView:(BCCollectionView *)collectionView willShowViewController:(NSViewController *)viewController forItem:(id)anItem
{
    LHImageFile *imageFile = (LHImageFile *)anItem;
    CellViewController *cell = (CellViewController*)viewController;
    [cell.imageView setImage:imageFile.previewImage];
    [cell setImageFileTitle:imageFile.filename];
    [cell setImageFileKind:imageFile.localizedTypeDescription];
    [cell setImageFileDimensions:imageFile.dimensionsDescription];
    
}


- (NSUInteger)groupHeaderHeightForCollectionView:(BCCollectionView *)collectionView
{
    return 40;
}

- (NSViewController *)collectionView:(BCCollectionView *)collectionView headerForGroup:(BCCollectionViewGroup *)group
{
    GroupViewController *controller = [[GroupViewController alloc] initWithNibName:@"GroupViewController" bundle:nil];
    [controller view];
    controller.groupTitle.stringValue = group.title;
    controller.countString.stringValue = [NSString stringWithFormat:@"%li image files",group.itemArray.count];
    return controller;
}

- (void)collectionView:(BCCollectionView *)collectionView updateViewControllerAsSelected:(NSViewController *)viewController forItem:(id)item
{
    CellViewController *view = (CellViewController *)viewController;
    [view.carrierView setSelected:YES];
}

- (void)collectionView:(BCCollectionView *)collectionView didSelectItem:(id)anItem withViewController:(NSViewController *)viewController
{
    CellViewController *ctrl = (CellViewController *)viewController;
    [ctrl.carrierView setSelected:YES];
}

- (void)collectionView:(BCCollectionView *)collectionView didDeselectItem:(id)anItem withViewController:(NSViewController *)viewController
{
    CellViewController *ctrl = (CellViewController *)viewController;
    [ctrl.carrierView setSelected:NO];
}

- (BOOL)collectionView:(BCCollectionView *)collectionView canDragItemsAtIndexes:(NSIndexSet *)indexSet
{
    NSLog(@"%s",__func__);
    
    return YES;
}

- (void)collectionView:(BCCollectionView *)collectionView writeItemsAtIndexes:(NSIndexSet *)indexSet toPasteboard:(NSPasteboard *)pboard{
    NSLog(@"%s",__func__);
    [indexSet enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
        LHImageFile *file = collectionView.totalGroupsArray[idx];
        [pboard clearContents];
        [pboard declareTypes:[NSArray arrayWithObject:NSURLPboardType] owner:nil];
        if([pboard writeObjects:[NSArray arrayWithObject:file.url]])
        {
        }
    }];
    
}
- (BOOL)collectionView:(BCCollectionView *)collectionView validateDrop:(id <NSDraggingInfo>)draggingInfo onItemAtIndex:(NSInteger)index{
    NSLog(@"%s",__func__);
    return YES;
    
}
- (void)collectionView:(BCCollectionView *)collectionView dragEnteredViewController:(NSViewController *)viewController{
    NSLog(@"%s",__func__);
    
}
- (void)collectionView:(BCCollectionView *)collectionView dragExitedViewController:(NSViewController *)viewController{
    NSLog(@"%s",__func__);
    
}
- (BOOL)collectionView:(BCCollectionView *)collectionView
  performDragOperation:(id <NSDraggingInfo>)draggingInfo
      onViewController:(NSViewController *)viewController
               forItem:(id)item{
    NSLog(@"%s",__func__);
    return YES;
}
- (NSDragOperation)collectionView:(BCCollectionView *)collectionView draggingEntered:(id <NSDraggingInfo>)draggingInfo{
    NSLog(@"%s",__func__);
    return NSDragOperationCopy;
}
- (void)collectionView:(BCCollectionView *)collectionView draggingEnded:(id <NSDraggingInfo>)draggingInfo{
    NSLog(@"%s",__func__);
    
}
- (void)collectionView:(BCCollectionView *)collectionView draggingExited:(id <NSDraggingInfo>)draggingInfo{
    NSLog(@"%s",__func__);
    
}

- (NSMenu *)collectionView:(BCCollectionView *)collectionView menuForItemsAtIndexes:(NSIndexSet *)indexSet
{
    //创建Menu
    NSMenu *theMenu = [[NSMenu alloc] initWithTitle:@"ItemMenu"];
    
    //自定义的NSMenuItem
    NSMenuItem *item = [[NSMenuItem alloc]init];
    
    item.title = @"Set as Background";
    item.target = self;
    item.action = @selector(setCollectionViewBackgroud:);
    item.representedObject = collectionView.totalGroupsArray[indexSet.lastIndex];
    [theMenu insertItem:item atIndex:0];
    return theMenu;
}

- (void)collectionView:(BCCollectionView *)collectionView didDoubleClickViewControllerAtIndex:(NSUInteger)index
{
    NSLog(@"%li double clicked",index);
    LHImageBrowser *imageViewController = [[LHImageBrowser alloc] initWithNibName:@"TSImageBrowser" bundle:[NSBundle mainBundle]];
    imageViewController.imageArray = self.collectionView.totalGroupsArray;
    imageViewController.currentIndex = index;
    _modalOverlay.contentViewController = imageViewController;
    _modalOverlay.animates = YES;
    _modalOverlay.animationDirection = JMModalOverlayDirectionBottom;
    _modalOverlay.shouldOverlayTitleBar = YES;
    _modalOverlay.shouldCloseWhenClickOnBackground = YES;
    //        _modalOverlay.appearance = [NSAppearance appearanceNamed:NSAppearanceNameVibrantDark];
    //        _modalOverlay.backgroundColor = [NSColor colorWithCalibratedWhite:1.0 alpha:0.0];
    
    [_modalOverlay showInWindow:[NSApp mainWindow]];
    
}

- (void)setCollectionViewBackgroud:(NSMenuItem *)sender{
    LHImageFile *imageFile = sender.representedObject;
    NSImage *image = [[NSImage alloc] initByReferencingURL:imageFile.url];
    NSColor *bgColor = [NSColor colorWithPatternImage:image];
    [self.collectionView setBackgroundColor:bgColor];
}

- (IBAction)closeGroup:(id)sender {
    for (BCCollectionViewGroup *group in self.collectionView.groups)
    {
        group.isCollapsed = YES;
    }
}
- (IBAction)openGroup:(id)sender {
    for (BCCollectionViewGroup *group in self.collectionView.groups)
    {
        group.isCollapsed = NO;
    }
}
@end

