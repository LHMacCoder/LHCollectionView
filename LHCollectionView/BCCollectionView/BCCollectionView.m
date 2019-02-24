//  Created by Pieter Omvlee on 24/11/2010.
//  Copyright 2010 Bohemian Coding. All rights reserved.

#import "BCCollectionView.h"
#import "BCGeometryExtensions.h"
#import "BCCollectionViewLayoutManager.h"
#import "BCCollectionViewLayoutItem.h"
#import "BCCollectionViewGroup.h"


@interface BCCollectionView ()
{
    NSUInteger _totalItemOfGroups;
}
- (void)configureView;
@end


@implementation BCCollectionView

@dynamic visibleViewControllerArray;

- (id)initWithFrame:(NSRect)frameRect
{
    self = [super initWithFrame:frameRect];
    if (self) {
        [self configureView];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self configureView];
    }
    return self;
}

- (void)configureView
{
    reusableViewControllers     = [[NSMutableArray alloc] init];
    visibleViewControllers      = [[NSMutableDictionary alloc] init];
    _contentArray                = [[NSArray alloc] init];
    selectionIndexes            = [[NSMutableIndexSet alloc] init];
    dragHoverIndex              = NSNotFound;
    _accumulatedKeyStrokes       = [[NSString alloc] init];
    _numberOfPreRenderedRows     = 3;
    _layoutManager               = [[BCCollectionViewLayoutManager alloc] initWithCollectionView:self];
    visibleGroupViewControllers = [[NSMutableDictionary alloc] init];
    _totalGroupsArray           = [NSMutableArray new];
    
    [self addObserver:self forKeyPath:@"backgroundColor" options:0 context:NULL];
    
    NSClipView *enclosingClipView = [[self enclosingScrollView] contentView];
    [enclosingClipView setPostsBoundsChangedNotifications:YES];
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    [center addObserver:self selector:@selector(scrollViewDidScroll:) name:NSViewBoundsDidChangeNotification object:enclosingClipView];
    [center addObserver:self selector:@selector(viewDidResize) name:NSViewFrameDidChangeNotification object:self];
    
    // 注册可以拖拽的文件类型
    [self registerForDraggedTypes:[NSArray arrayWithObjects:
                                   NSTIFFPboardType, NSFilenamesPboardType, nil]];
    
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"backgroundColor"])
        [self setNeedsDisplay:YES];
    else if ([keyPath isEqual:_zoomValueObserverKey]) {
        if ([self respondsToSelector:@selector(zoomValueDidChange)])
            [self performSelector:@selector(zoomValueDidChange)];
    } else if ([keyPath isEqualToString:@"isCollapsed"]) {
        [self softReloadDataWithCompletionBlock:^{
            [self performSelector:@selector(scrollViewDidScroll:)];
        }];
    } else
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
}

- (void)dealloc
{
    [self removeObserver:self forKeyPath:@"backgroundColor"];
    [[NSUserDefaults standardUserDefaults] removeObserver:self forKeyPath:_zoomValueObserverKey];
    
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    [center removeObserver:self name:NSViewBoundsDidChangeNotification object:[[self enclosingScrollView] contentView]];
    [center removeObserver:self name:NSViewFrameDidChangeNotification object:self];
    
    for (BCCollectionViewGroup *group in _groups)
        [group removeObserver:self forKeyPath:@"isCollapsed"];
    
}

- (BOOL)isFlipped
{
    return YES;
}

#pragma mark Drawing Selections

- (BOOL)shoulDrawSelections
{
    if ([_delegate respondsToSelector:@selector(collectionViewShouldDrawSelections:)])
        return [_delegate collectionViewShouldDrawSelections:self];
    else
        return YES;
}

- (BOOL)shoulDrawHover
{
    if ([_delegate respondsToSelector:@selector(collectionViewShouldDrawHover:)])
        return [_delegate collectionViewShouldDrawHover:self];
    else
        return YES;
}

- (void)drawItemSelectionForInRect:(NSRect)aRect
{
//    NSRect insetRect = NSInsetRect(aRect, 10, 10);
//    if ([self needsToDrawRect:insetRect]) {
//        [[NSColor lightGrayColor] set];
//        [[NSBezierPath bezierPathWithRoundedRect:insetRect xRadius:10 yRadius:10] fill];
//    }
}

- (void)drawRect:(NSRect)dirtyRect
{
//    [_backgroundColor ? _backgroundColor : [NSColor colorNamed:@"customControlColor"] set];
//    [_backgroundColor ? _backgroundColor : [NSColor colorWithCatalogName:@"Assets" colorName:@"customControlColor"] set];

    _backgroundColor = [NSColor whiteColor];
    [_backgroundColor set];
    NSRectFill(dirtyRect);
    
    // 拖拽框的边框颜色和背景颜色设置
    [[NSColor grayColor] set];
    NSFrameRect(BCRectFromTwoPoints(mouseDownLocation, mouseDraggedLocation));
    NSRectFill(BCRectFromTwoPoints(mouseDownLocation, mouseDraggedLocation));
    
    if ([selectionIndexes count] > 0 && [self shoulDrawSelections]) {
        for (NSNumber *number in visibleViewControllers)
            if ([selectionIndexes containsIndex:[number integerValue]])
            {
//                [self drawItemSelectionForInRect:[[[visibleViewControllers objectForKey:number] view] frame]];
            }
    }
    
    if (dragHoverIndex != NSNotFound && [self shoulDrawHover])
    {
//        [self drawItemSelectionForInRect:[[[visibleViewControllers objectForKey:[NSNumber numberWithInteger:dragHoverIndex]] view] frame]];
    }
}

#pragma mark _delegate Call Wrappers

- (void)delegateUpdateSelectionForItemAtIndex:(NSUInteger)index
{
    if (_groups.count > 0)
    {
        if ([_delegate respondsToSelector:@selector(collectionView:updateViewControllerAsSelected:forItem:)])
            [_delegate collectionView:self updateViewControllerAsSelected:[self viewControllerForItemAtIndex:index]
                              forItem:[self itemOfGroupAtViewIndex:index]];
    }
    else
    {
        if ([_delegate respondsToSelector:@selector(collectionView:updateViewControllerAsSelected:forItem:)])
            [_delegate collectionView:self updateViewControllerAsSelected:[self viewControllerForItemAtIndex:index]
                              forItem:[_contentArray objectAtIndex:index]];
    }

}

- (void)delegateUpdateDeselectionForItemAtIndex:(NSUInteger)index
{
    if (_groups.count > 0)
    {
        if ([_delegate respondsToSelector:@selector(collectionView:updateViewControllerAsDeselected:forItem:)])
            [_delegate collectionView:self updateViewControllerAsDeselected:[self viewControllerForItemAtIndex:index]
                              forItem:[self itemOfGroupAtViewIndex:index]];
    }
    else
    {
        if ([_delegate respondsToSelector:@selector(collectionView:updateViewControllerAsDeselected:forItem:)])
            [_delegate collectionView:self updateViewControllerAsDeselected:[self viewControllerForItemAtIndex:index]
                              forItem:[_contentArray objectAtIndex:index]];
    }

}

- (void)delegateCollectionViewSelectionDidChange
{
    if (!selectionChangedDisabled && [_delegate respondsToSelector:@selector(collectionViewSelectionDidChange:)]) {
        [[NSRunLoop currentRunLoop] cancelPerformSelector:@selector(collectionViewSelectionDidChange:) target:_delegate argument:self];
        [(id)_delegate performSelector:@selector(collectionViewSelectionDidChange:) withObject:self afterDelay:0.0];
    }
}

- (void)delegateDidSelectItemAtIndex:(NSUInteger)index
{
    if (_groups.count > 0)
    {
        if ([_delegate respondsToSelector:@selector(collectionView:didSelectItem:withViewController:)])
            [_delegate collectionView:self
                        didSelectItem:[self itemOfGroupAtViewIndex:index]
                   withViewController:[self viewControllerForItemAtIndex:index]];
    }
    else
    {
        if ([_delegate respondsToSelector:@selector(collectionView:didSelectItem:withViewController:)])
            [_delegate collectionView:self
                        didSelectItem:[_contentArray objectAtIndex:index]
                   withViewController:[self viewControllerForItemAtIndex:index]];
    }

}

- (void)delegateDidDeselectItemAtIndex:(NSUInteger)index
{
    if (_groups.count > 0)
    {
        if ([_delegate respondsToSelector:@selector(collectionView:didDeselectItem:withViewController:)])
            [_delegate collectionView:self
                      didDeselectItem:[self itemOfGroupAtViewIndex:index]
                   withViewController:[self viewControllerForItemAtIndex:index]];
    }
    else
    {
        if ([_delegate respondsToSelector:@selector(collectionView:didDeselectItem:withViewController:)])
            [_delegate collectionView:self
                      didDeselectItem:[_contentArray objectAtIndex:index]
                   withViewController:[self viewControllerForItemAtIndex:index]];
    }
    
    [self delegateCollectionViewSelectionDidChange];
}

- (void)delegateViewControllerBecameInvisibleAtIndex:(NSUInteger)index
{
    if ([_delegate respondsToSelector:@selector(collectionView:viewControllerBecameInvisible:)])
        [_delegate collectionView:self viewControllerBecameInvisible:[self viewControllerForItemAtIndex:index]];
}

- (NSSize)cellSize
{
    return [_delegate cellSizeForCollectionView:self];
}

- (NSUInteger)groupHeaderHeight
{
    return [_delegate groupHeaderHeightForCollectionView:self];
}

// 某个rect的items下标
- (NSIndexSet *)indexesOfItemsInRect:(NSRect)aRect
{
    NSArray *itemLayouts = [_layoutManager itemLayouts];
    NSIndexSet *visibleIndexes = [itemLayouts indexesOfObjectsWithOptions:NSEnumerationConcurrent passingTest:^BOOL(id itemLayout, NSUInteger idx, BOOL *stop) {
        return NSIntersectsRect([itemLayout itemRect], aRect);
    }];
    return visibleIndexes;
}

- (NSIndexSet *)indexesOfItemContentRectsInRect:(NSRect)aRect
{
    NSArray *itemLayouts = [_layoutManager itemLayouts];
    NSIndexSet *visibleIndexes = [itemLayouts indexesOfObjectsWithOptions:NSEnumerationConcurrent passingTest:^BOOL(id itemLayout, NSUInteger idx, BOOL *stop) {
        return NSIntersectsRect([itemLayout itemRect], aRect);
    }];
    return visibleIndexes;
}

// 可视范围内items的range
- (NSRange)rangeOfVisibleItems
{
    NSIndexSet *visibleIndexes = [self indexesOfItemsInRect:[self visibleRect]];
    return NSMakeRange([visibleIndexes firstIndex], [visibleIndexes lastIndex]-[visibleIndexes firstIndex]);
}

// 可视范围内items的溢出range
- (NSRange)rangeOfVisibleItemsWithOverflow
{
    NSRange range = [self rangeOfVisibleItems];
    NSInteger extraItems = [_layoutManager maximumNumberOfItemsPerRow] * _numberOfPreRenderedRows;
    NSInteger min = range.location;
    NSInteger max = range.location + range.length;
    
    if (_groups.count > 0)
    {
        min = MAX(0, min-extraItems);
        max = MIN([_totalGroupsArray count], max+extraItems);
    }
    else
    {
        min = MAX(0, min-extraItems);
        max = MIN([_contentArray count], max+extraItems);
    }
    return NSMakeRange(min, max-min);
}

#pragma mark Querying ViewControllers

- (NSIndexSet *)indexesOfViewControllers
{
    NSMutableIndexSet *set = [NSMutableIndexSet indexSet];
    for (NSNumber *number in [visibleViewControllers allKeys])
        [set addIndex:[number integerValue]];
    return set;
}

- (NSArray *)_visibleViewControllerArray
{
    return [visibleViewControllers allValues];
}

- (NSIndexSet *)indexesOfInvisibleViewControllers
{
    NSRange visibleRange = [self rangeOfVisibleItemsWithOverflow];
    return [[self indexesOfViewControllers] indexesPassingTest:^BOOL(NSUInteger idx, BOOL *stop) {
        return !NSLocationInRange(idx, visibleRange);
    }];
}

- (NSViewController *)viewControllerForItemAtIndex:(NSUInteger)index
{
    return [visibleViewControllers objectForKey:[NSNumber numberWithInteger:index]];
}

#pragma mark Swapping ViewControllers in and out
// 根据下标移除item的视图控制器
- (void)removeViewControllerForItemAtIndex:(NSUInteger)anIndex
{
    NSNumber *key = [NSNumber numberWithInteger:anIndex];
    NSViewController *viewController = [visibleViewControllers objectForKey:key];
    [[viewController view] removeFromSuperview];
    
    [self delegateUpdateDeselectionForItemAtIndex:anIndex];
    [self delegateViewControllerBecameInvisibleAtIndex:anIndex];
    
    // 把移除的视图控制器添加到复用队列
    
    [reusableViewControllers addObject:viewController];
    [visibleViewControllers removeObjectForKey:key];
}

// 移除溢出的可视视图控制器，但又不在可视范围内
- (void)removeInvisibleViewControllers
{
    [[self indexesOfInvisibleViewControllers] enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
        [self removeViewControllerForItemAtIndex:idx];
    }];
}

// 为item返回一个控制器，如果复用队列里面有数据，则使用复用队列，否则重新生成。
- (NSViewController *)emptyViewControllerForInsertion
{
    if ([reusableViewControllers count] > 0)
    {
        NSViewController *viewController = [reusableViewControllers lastObject];
        [reusableViewControllers removeLastObject];
        return viewController;
    }
    else
    {
        return [_delegate reusableViewControllerForCollectionView:self];
    }
}

- (void)addMissingViewControllerForItemAtIndex:(NSUInteger)anIndex withFrame:(NSRect)aRect
{
    BOOL couldLoad;
    if (_groups.count > 0)
    {
        couldLoad = _totalItemOfGroups > anIndex ? YES : NO;
    }
    else
    {
        couldLoad = _contentArray.count > anIndex ? YES : NO;
    }
    if (couldLoad) {
        NSViewController *viewController = [self emptyViewControllerForInsertion];
        [visibleViewControllers setObject:viewController forKey:[NSNumber numberWithInteger:anIndex]];
        [[viewController view] setFrame:aRect];
        [[viewController view] setAutoresizingMask:NSViewMaxXMargin | NSViewMaxYMargin];
        
        id itemToLoad = nil;
        if (_groups.count > 0)
        {
            itemToLoad = [self itemOfGroupAtViewIndex:anIndex];
        }
        else
        {
           itemToLoad = [_contentArray objectAtIndex:anIndex];

        }
        [_delegate collectionView:self willShowViewController:viewController forItem:itemToLoad];
        [self addSubview:[viewController view]];
        if ([selectionIndexes containsIndex:anIndex])
        {
            [self delegateUpdateSelectionForItemAtIndex:anIndex];
        }
        else
        {
            [self deselectItemAtIndex:anIndex];
        }
    }
}

- (void)addMissingGroupHeaders
{
    if ([_groups count] > 0) {
        [_groups enumerateObjectsUsingBlock:^(BCCollectionViewGroup *group, NSUInteger idx, BOOL *stop) {
            NSRect groupRect = NSMakeRect(0, NSMinY([_layoutManager rectOfItemAtIndex:[group itemRange].location])-[self groupHeaderHeight], NSWidth([self visibleRect]), [self groupHeaderHeight]);
            if (idx == 0 && ![group isCollapsed] && [_delegate respondsToSelector:@selector(topOffsetForItemsInCollectionView:)])
                groupRect.origin.y -= [_delegate topOffsetForItemsInCollectionView:self];

            BOOL groupShouldBeVisible = NSIntersectsRect(groupRect, [self visibleRect]);
            NSViewController *groupViewController = [visibleGroupViewControllers objectForKey:[NSNumber numberWithInteger:idx]];
            [[groupViewController view] setFrame:groupRect];
            if (groupShouldBeVisible && !groupViewController) {
                groupViewController = [_delegate collectionView:self headerForGroup:group];
                [self addSubview:[groupViewController view]];
                [visibleGroupViewControllers setObject:groupViewController forKey:[NSNumber numberWithInteger:idx]];
                [[groupViewController view] setFrame:groupRect];
            } else if (!groupShouldBeVisible && groupViewController) {
                [[groupViewController view] removeFromSuperview];
                [visibleGroupViewControllers removeObjectForKey:[NSNumber numberWithInteger:idx]];
            }
        }];
    }
}

- (void)addMissingViewControllersToView
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSIndexSet indexSetWithIndexesInRange:[self rangeOfVisibleItemsWithOverflow]] enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
            if (![visibleViewControllers objectForKey:[NSNumber numberWithInteger:idx]]) {
                [self addMissingViewControllerForItemAtIndex:idx withFrame:[_layoutManager rectOfItemAtIndex:idx]];
            }
        }];
        [self addMissingGroupHeaders];
    });
}

- (void)moveViewControllersToProperPosition
{
    for (NSNumber *number in visibleViewControllers) {
        NSRect r = [_layoutManager rectOfItemAtIndex:[number integerValue]];
        if (!NSEqualRects(r, NSZeroRect))
            [[[visibleViewControllers objectForKey:number] view] setFrame:r];
    }
}

#pragma mark Selecting and Deselecting Items

- (void)selectItemAtIndex:(NSUInteger)index
{
    [self selectItemAtIndex:index inBulk:NO];
}

- (void)selectItemAtIndex:(NSUInteger)index inBulk:(BOOL)bulkSelecting
{
    if (_groups.count > 0)
    {
        if (index >= [_totalGroupsArray count])
            return;
    }
    else
    {
        if (index >= [_contentArray count])
            return;
    }

    BOOL maySelectItem = YES;
    NSViewController *viewController = [self viewControllerForItemAtIndex:index];
    id item = nil;
    if (_groups.count > 0)
    {
        item = [self itemOfGroupAtViewIndex:index];
    }
    else
    {
        item = [_contentArray objectAtIndex:index];
    }
    
    if ([_delegate respondsToSelector:@selector(collectionView:shouldSelectItem:withViewController:)])
        maySelectItem = [_delegate collectionView:self shouldSelectItem:item withViewController:viewController];
    
    if (maySelectItem) {
        [selectionIndexes addIndex:index];
        [self delegateUpdateSelectionForItemAtIndex:index];
        [self delegateDidSelectItemAtIndex:index];
        if (!bulkSelecting)
            [self delegateCollectionViewSelectionDidChange];
        
    }
    
    if (!bulkSelecting)
        lastSelectionIndex = index;
}

- (void)selectItemsAtIndexes:(NSIndexSet *)indexes
{
    [indexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
        [self selectItemAtIndex:idx inBulk:YES];
    }];
    lastSelectionIndex = [indexes firstIndex];
    [self delegateCollectionViewSelectionDidChange];
}

- (void)deselectItemAtIndex:(NSUInteger)index
{
    BOOL couldDeSelected = NO;
    if (_groups.count > 0)
    {
        couldDeSelected = index < [_totalGroupsArray count] ? YES : NO;
    }
    else
    {
        couldDeSelected = index < [_contentArray count] ? YES : NO;
        
    }
    if (couldDeSelected) {
        [selectionIndexes removeIndex:index];
        
        [self delegateDidDeselectItemAtIndex:index];
        [self delegateUpdateDeselectionForItemAtIndex:index];
        
    }
}

- (void)deselectItemsAtIndexes:(NSIndexSet *)indexes
{
    [indexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
        [self deselectItemAtIndex:idx];
    }];
}

- (void)deselectAllItems
{
    [selectionIndexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
        [self deselectItemAtIndex:idx];
    }];
}

- (NSIndexSet *)selectionIndexes
{
    return selectionIndexes;
}

- (void)selectAll:(id)sender
{
    [self selectItemsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0,[_contentArray count])]];
}

#pragma mark User-interaction

- (BOOL)acceptsFirstResponder
{
    return YES;
}

- (BOOL)canBecomeKeyView
{
    return YES;
}

#pragma mark Reloading and Updating the Icon View

- (void)softReloadVisibleViewControllers
{
    NSMutableArray *removeKeys = [NSMutableArray array];
    
    for (NSString *number in visibleViewControllers) {
        NSUInteger index             = [number integerValue];
        NSViewController *controller = [visibleViewControllers objectForKey:number];
        
        BOOL reload;
        if (_groups.count > 0)
        {
            reload = index < [_totalGroupsArray count] ? YES : NO;
        }
        else
        {
            reload = index < [_contentArray count] ? YES : NO;

        }
        
        if (reload) {
            if ([selectionIndexes containsIndex:index])
            {
                [self delegateUpdateDeselectionForItemAtIndex:index];
            }
            if (_groups.count > 0)
            {
                [_delegate collectionView:self willShowViewController:controller forItem:[self itemOfGroupAtViewIndex:index]];
            }
            else
            {
                [_delegate collectionView:self willShowViewController:controller forItem:[_contentArray objectAtIndex:index]];
            }
        }
        else
        {
            if ([selectionIndexes containsIndex:index])
            {
                [self delegateUpdateDeselectionForItemAtIndex:index];
            }
            
            [self delegateViewControllerBecameInvisibleAtIndex:index];
            [[controller view] removeFromSuperview];
            [reusableViewControllers addObject:controller];
            [removeKeys addObject:number];
        }
    }
    [visibleViewControllers removeObjectsForKeys:removeKeys];
}

- (void)resizeFrameToFitContents
{
    NSRect frame = [self frame];
    frame.size.height = [self visibleRect].size.height;
    
    BOOL fitContent;
    if (_groups.count > 0)
    {
        fitContent = 0 < [_totalGroupsArray count] ? YES : NO;
    }
    else
    {
        fitContent = 0 < [_contentArray count] ? YES : NO;
        
    }
    
    if (fitContent) {
        BCCollectionViewLayoutItem *layoutItem = [[_layoutManager itemLayouts] lastObject];
        frame.size.height = MAX(frame.size.height, NSMaxY([layoutItem itemRect]));
    }
    [self setFrame:frame];
}

- (void)reloadDataWithItemsEmptyCaches:(BOOL)shouldEmptyCaches
{
    NSMutableArray *tagArray = [NSMutableArray new];

    _totalItemOfGroups = 0;
    if (_totalGroupsArray.count)
    {
        [_totalGroupsArray removeAllObjects];
    }
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(groupViewFromDataSource:)])
    {
        [tagArray addObjectsFromArray:[self.delegate groupViewFromDataSource:_totalGroupsArray]];
        _totalItemOfGroups += _totalGroupsArray.count;
    }
    
    [self reloadDataWithItems:_totalGroupsArray groups:tagArray emptyCaches:shouldEmptyCaches];
}

- (void)reloadDataWithItems:(NSArray *)newContent groups:(NSArray *)newGroups emptyCaches:(BOOL)shouldEmptyCaches
{
    [self reloadDataWithItems:newContent groups:newGroups emptyCaches:shouldEmptyCaches completionBlock:^{}];
}

// 分组的item在视图上的下标
- (id)itemOfGroupAtViewIndex:(NSInteger)index
{
    return _totalGroupsArray[index];
}

- (void)reloadDataWithItems:(NSArray *)newContent groups:(NSArray *)newGroups emptyCaches:(BOOL)shouldEmptyCaches completionBlock:(dispatch_block_t)completionBlock
{
    if (shouldEmptyCaches)
    {
        [self deselectAllItems];
    }
    [_layoutManager cancelItemEnumerator];
    
    if (!_delegate)
        return;
    
    for (BCCollectionViewGroup *group in _groups)
        [group removeObserver:self forKeyPath:@"isCollapsed"];
    for (BCCollectionViewGroup *group in newGroups)
        [group addObserver:self forKeyPath:@"isCollapsed" options:0 context:NULL];
    
    self.groups       = newGroups;
    self.contentArray = newContent;

    
    if (shouldEmptyCaches)
    {
        for (NSViewController *viewController in [visibleGroupViewControllers allValues])
            [[viewController view] removeFromSuperview];
        [visibleGroupViewControllers removeAllObjects];
        
        for (NSViewController *viewController in [visibleViewControllers allValues])
        {
            [[viewController view] removeFromSuperview];
            if ([_delegate respondsToSelector:@selector(collectionView:viewControllerBecameInvisible:)])
                [_delegate collectionView:self viewControllerBecameInvisible:viewController];
        }
        
        [reusableViewControllers removeAllObjects];
        [visibleViewControllers removeAllObjects];
    }
    else
    {
        [self softReloadVisibleViewControllers];
        [selectionIndexes removeAllIndexes];
    }
    
    
    // 如果有分组，则按分组显示，否则显示全部的图片
    if (_groups.count > 0)
    {
        NSRect visibleRect = [self visibleRect];
        __weak typeof(self) weakSelf = self;
        [_layoutManager enumerateItems:^(BCCollectionViewLayoutItem *layoutItem) {
            NSViewController *viewController = [weakSelf viewControllerForItemAtIndex:[layoutItem itemIndex]];
            if (viewController) {
                [[viewController view] setFrame:[layoutItem itemRect]];
                [weakSelf.delegate collectionView:weakSelf willShowViewController:viewController forItem:[weakSelf itemOfGroupAtViewIndex:[layoutItem itemIndex]]];
            } else if (NSIntersectsRect(visibleRect, [layoutItem itemRect]))
            {
                [self addMissingViewControllerForItemAtIndex:[layoutItem itemIndex] withFrame:[layoutItem itemRect]];
            }
        } completionBlock:^{
            [weakSelf resizeFrameToFitContents];
            [weakSelf addMissingGroupHeaders];
            dispatch_async(dispatch_get_main_queue(), completionBlock);
        }];
    }
    else
    {
        NSRect visibleRect = [self visibleRect];
        __weak typeof(self) weakSelf = self;
        [_layoutManager enumerateItems:^(BCCollectionViewLayoutItem *layoutItem) {
            NSViewController *viewController = [weakSelf viewControllerForItemAtIndex:[layoutItem itemIndex]];
            if (viewController) {
                [[viewController view] setFrame:[layoutItem itemRect]];
                [weakSelf.delegate collectionView:weakSelf willShowViewController:viewController forItem:[weakSelf.contentArray objectAtIndex:[layoutItem itemIndex]]];
            } else if (NSIntersectsRect(visibleRect, [layoutItem itemRect]))
            {
                [self addMissingViewControllerForItemAtIndex:[layoutItem itemIndex] withFrame:[layoutItem itemRect]];
            }
        } completionBlock:^{
            [weakSelf resizeFrameToFitContents];
            [weakSelf addMissingGroupHeaders];
            dispatch_async(dispatch_get_main_queue(), completionBlock);
        }];
    }

}

- (void)scrollViewDidScroll:(NSNotification *)note
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self removeInvisibleViewControllers];
        [self addMissingViewControllersToView];
    });
    
    if ([_delegate respondsToSelector:@selector(collectionViewDidScroll:inDirection:)]) {
        if ([self visibleRect].origin.y > previousFrameBounds.origin.y)
            [_delegate collectionViewDidScroll:self inDirection:BCCollectionViewScrollDirectionDown];
        else
            [_delegate collectionViewDidScroll:self inDirection:BCCollectionViewScrollDirectionUp];
        previousFrameBounds = [self visibleRect];
    }
}

- (void)viewDidResize
{
    if (_groups.count > 0)
    {
        if ([_totalGroupsArray count] > 0 && [visibleViewControllers count] > 0)
            [self softReloadDataWithCompletionBlock:NULL];
    }
    else
    {
        if ([_contentArray count] > 0 && [visibleViewControllers count] > 0)
            [self softReloadDataWithCompletionBlock:NULL];
    }
}

- (void)softReloadDataWithCompletionBlock:(dispatch_block_t)block
{
    NSRange range = [self rangeOfVisibleItemsWithOverflow];
    [_layoutManager enumerateItems:^(BCCollectionViewLayoutItem *layoutItem) {
        if (NSLocationInRange([layoutItem itemIndex], range)) {
            NSViewController *controller = [self viewControllerForItemAtIndex:[layoutItem itemIndex]];
            if (controller)
                [[controller view] setFrame:[layoutItem itemRect]];
            else
                [self addMissingViewControllerForItemAtIndex:[layoutItem itemIndex] withFrame:[layoutItem itemRect]];
        } else {
            if ([self viewControllerForItemAtIndex:[layoutItem itemIndex]])
                [self removeViewControllerForItemAtIndex:[layoutItem itemIndex]];
        }
    } completionBlock:^(void) {
        [self resizeFrameToFitContents];
        [self addMissingGroupHeaders];
        [self setNeedsDisplay:YES];
        if (block != NULL)
            block();
    }];
}

- (NSMenu *)menuForEvent:(NSEvent *)anEvent
{
    [self mouseDown:anEvent];
    NSUInteger index     = [self.layoutManager indexOfItemContentRectAtPoint:mouseDownLocation];
    if (index == NSNotFound)
        return nil;
    if ([_delegate respondsToSelector:@selector(collectionView:menuForItemsAtIndexes:)])
        return [_delegate collectionView:self menuForItemsAtIndexes:[NSIndexSet indexSetWithIndex:index]];
    else
        return nil;
}

- (BOOL)resignFirstResponder
{
    if ([_delegate respondsToSelector:@selector(collectionViewLostFirstResponder:)])
        [_delegate collectionViewLostFirstResponder:self];
    return [super resignFirstResponder];
}

- (BOOL)becomeFirstResponder
{
    if ([_delegate respondsToSelector:@selector(collectionViewBecameFirstResponder:)])
        [_delegate collectionViewBecameFirstResponder:self];
    return [super becomeFirstResponder];
}

- (BOOL)isOpaque
{
    return YES;
}

@end

