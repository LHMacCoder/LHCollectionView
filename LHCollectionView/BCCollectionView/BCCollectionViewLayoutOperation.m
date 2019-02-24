//  Created by Pieter Omvlee on 02/03/2011.
//  Copyright 2011 Bohemian Coding. All rights reserved.

#import "BCCollectionViewLayoutOperation.h"
#import "BCCollectionView.h"
#import "BCCollectionViewLayoutItem.h"
#import "BCCollectionViewGroup.h"
#import "BCCollectionViewLayoutManager.h"

@implementation BCCollectionViewLayoutOperation

/****** tenorshare modify *********/
- (void)main
{
    if ([self isCancelled])
        return;
    
    NSInteger numberOfRows = 0;    // 行数
    NSInteger startingX = 0;    // x开始位置
    NSInteger x = 0;            // X坐标
    NSInteger y = 0;            // Y坐标
    NSUInteger colIndex   = 0;  //
    __block NSRect visibleRect;     //可视区域
    dispatch_sync(dispatch_get_main_queue(), ^{
        visibleRect = [self.collectionView visibleRect];
    });
    NSSize cellSize       = [_collectionView cellSize];    //每个单元的大小
    NSSize inset          = NSZeroSize;
    __block NSInteger maxColumns;   // 最大列数
    __block NSUInteger gap;     // 间隙，间隔
    dispatch_sync(dispatch_get_main_queue(), ^{
        maxColumns = [[self.collectionView layoutManager] maximumNumberOfItemsPerRow];
        gap  = (NSWidth([self.collectionView frame]) - maxColumns*cellSize.width)/(maxColumns-1);
    });
    
    if (maxColumns < 4) {
        dispatch_sync(dispatch_get_main_queue(), ^{
            gap = (NSWidth([_collectionView frame]) - maxColumns*cellSize.width)/(maxColumns+1);
        });
        startingX = gap;
        x = gap;
    }
    
    if ([[_collectionView delegate] respondsToSelector:@selector(insetMarginForSelectingItemsInCollectionView:)])
        inset = [[_collectionView delegate] insetMarginForSelectingItemsInCollectionView:_collectionView];
    
    NSMutableArray *newLayouts   = [NSMutableArray array];

    
    NSInteger index = 0;
    for (BCCollectionViewGroup *group in [_collectionView groups])
    {
        NSInteger count = group.itemArray.count;
        
        if (![group isCollapsed] && [[_collectionView delegate] respondsToSelector:@selector(topOffsetForItemsInCollectionView:)])
            y += [[_collectionView delegate] topOffsetForItemsInCollectionView:_collectionView];
        
        if (x != startingX)
        {
            numberOfRows++;
            colIndex = 0;
            y += cellSize.height;
        }
        y += [_collectionView groupHeaderHeight];
        x = startingX;
        
        for (NSInteger i = 0;i < count; i++)
        {
            if ([self isCancelled])
                return;
            
            BCCollectionViewLayoutItem *item = [BCCollectionViewLayoutItem layoutItem];
            [item setItemIndex:index];
            index ++;
            if (![group isCollapsed])
            {
                if (x + cellSize.width > NSMaxX(visibleRect))
                {
                    numberOfRows++;
                    colIndex = 0;
                    y += cellSize.height;
                    x  = startingX;
                }
                [item setColumnIndex:colIndex];
                [item setItemRect:NSMakeRect(x, y, cellSize.width, cellSize.height)];
                x += cellSize.width + gap;
                colIndex++;
            }
            else
            {
                [item setItemRect:NSMakeRect(-cellSize.width*2, y, cellSize.width, cellSize.height)];
            }
            [item setItemContentRect:NSInsetRect([item itemRect], inset.width, inset.height)];
            [item setRowIndex:numberOfRows];
            [newLayouts addObject:item];
            
            if (_layoutCallBack != nil)
            {
                dispatch_async(dispatch_get_main_queue(), ^{
                    _layoutCallBack(item);
                });
            }
            
        }
    }
    
    if (_collectionView.groups.count == 0)    // 如果没有对图片进行分组，则显示全部的图片
    {
        NSUInteger count = [[_collectionView contentArray] count];
        for (NSInteger i=0; i<count; i++) {
            if ([self isCancelled])
                return;

            BCCollectionViewLayoutItem *item = [BCCollectionViewLayoutItem layoutItem];
            [item setItemIndex:i];
            if (x + cellSize.width > NSMaxX(visibleRect)) {
                numberOfRows++;
                colIndex = 0;
                y += cellSize.height;
                x  = startingX;
            }
            [item setColumnIndex:colIndex];
            [item setItemRect:NSMakeRect(x, y, cellSize.width, cellSize.height)];
            x += cellSize.width + gap;
            colIndex++;
            [item setItemContentRect:NSInsetRect([item itemRect], inset.width, inset.height)];
            [item setRowIndex:numberOfRows];
            [newLayouts addObject:item];
            
            if (_layoutCallBack != nil) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    _layoutCallBack(item);
                });
            }
        }
    }
    
    numberOfRows = MAX(numberOfRows, [[_collectionView groups] count]);
    if ([[_collectionView contentArray] count] > 0 && numberOfRows == -1)
        numberOfRows = 1;
    
    if (![self isCancelled]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [[_collectionView layoutManager] setItemLayouts:newLayouts];
            _layoutCompletionBlock();
        });
    }
}

@end

