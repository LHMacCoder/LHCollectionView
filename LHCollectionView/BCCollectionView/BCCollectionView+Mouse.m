//  Created by Pieter Omvlee on 25/11/2010.
//  Copyright 2010 Bohemian Coding. All rights reserved.

#import "BCCollectionView+Mouse.h"
#import "BCGeometryExtensions.h"
#import "BCCollectionView+Dragging.h"
#import "BCCollectionViewLayoutManager.h"

@implementation BCCollectionView (BCCollectionView_Mouse)

- (BOOL)shiftOrCommandKeyPressed
{
    return [NSEvent modifierFlags] & NSShiftKeyMask || [NSEvent modifierFlags] & NSCommandKeyMask;
}

- (void)mouseDown:(NSEvent *)theEvent
{
    [[self window] makeFirstResponder:self];
    
    isDragging           = YES;
    mouseDownLocation    = [self convertPoint:[theEvent locationInWindow] fromView:nil];
    mouseDraggedLocation = mouseDownLocation;
    if ([theEvent type] == NSRightMouseDown)
    {
        return;
    }
    NSUInteger index     = [self.layoutManager indexOfItemContentRectAtPoint:mouseDownLocation];
    
    if (index != NSNotFound && [self.delegate respondsToSelector:@selector(collectionView:didClickItem:withViewController:)])
    {
        [self.delegate collectionView:self didClickItem:[self.contentArray objectAtIndex:index] withViewController:[visibleViewControllers objectForKey:[NSNumber numberWithInt:index]]];
    }
    
    if (![self shiftOrCommandKeyPressed] && ![selectionIndexes containsIndex:index])
    {
        [self selectItemAtIndex:index];
        
    }
    else if (![self shiftOrCommandKeyPressed] && [selectionIndexes containsIndex:index])
    {
        [self deselectItemAtIndex:index];
        if ([theEvent type] == NSLeftMouseDown && [theEvent clickCount] == 2 && [self.delegate respondsToSelector:@selector(collectionView:didDoubleClickViewControllerAtIndex:)])
        {
            [self.delegate collectionView:self didDoubleClickViewControllerAtIndex:index];
        }
        return;
    }
    
    self.originalSelectionIndexes = [selectionIndexes copy];
    
    if ([theEvent type] == NSLeftMouseDown && [theEvent clickCount] == 2 && [self.delegate respondsToSelector:@selector(collectionView:didDoubleClickViewControllerAtIndex:)])
    {
        [self.delegate collectionView:self didDoubleClickViewControllerAtIndex:index];
    }
    
    if ([self shiftOrCommandKeyPressed] && [self.originalSelectionIndexes containsIndex:index])
    {
        [self deselectItemAtIndex:index];
    }
    else
    {
        if ([NSEvent modifierFlags] & NSCommandKeyMask || [[self originalSelectionIndexes] count] == 0)
        {
            [self selectItemAtIndex:index];
        }
        else if ([NSEvent modifierFlags] & NSShiftKeyMask)
        {
            NSInteger one = [[self originalSelectionIndexes] lastIndex];
            if (index > NSNotFound - 1)
                return;
            NSInteger two = index;
            if (two > one)
                [self selectItemsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(MIN(one,two), 1+MAX(one,two)-MIN(one,two))]];
            else
                [self selectItemsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(MIN(one,two), MAX(one,two)-MIN(one,two))]];
        }
    }
}

- (void)regularMouseDragged:(NSEvent *)anEvent
{
    NSIndexSet *originalSet = [[self selectionIndexes] copy];
    selectionChangedDisabled = YES;
    
    [self deselectAllItems];
    if ([self shiftOrCommandKeyPressed]) {
        [self.originalSelectionIndexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
            [self selectItemAtIndex:idx];
        }];
    }
    [self setNeedsDisplayInRect:BCRectFromTwoPoints(mouseDownLocation, mouseDraggedLocation)];
    
    mouseDraggedLocation = [self convertPoint:[anEvent locationInWindow] fromView:nil];
    NSIndexSet *suggestedIndexes = [self indexesOfItemContentRectsInRect:BCRectFromTwoPoints(mouseDownLocation, mouseDraggedLocation)];
    
    if (![self shiftOrCommandKeyPressed]) {
        NSMutableIndexSet *oldIndexes = [selectionIndexes mutableCopy];
        [oldIndexes removeIndexes:suggestedIndexes];
        [self deselectItemsAtIndexes:oldIndexes];
    }
    
    [suggestedIndexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop){
        if ([self shiftOrCommandKeyPressed]) {
            if ([self.originalSelectionIndexes containsIndex:idx])
                [self deselectItemAtIndex:idx];
            else
                [self selectItemAtIndex:idx];
        } else
            [self selectItemAtIndex:idx];
    }];
    
    [self setNeedsDisplayInRect:BCRectFromTwoPoints(mouseDownLocation, mouseDraggedLocation)];
    
    selectionChangedDisabled = NO;
    if (![selectionIndexes isEqual:originalSet])
        [self performSelector:@selector(delegateCollectionViewSelectionDidChange)];
}

- (void)mouseDragged:(NSEvent *)anEvent
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(collectionViewCanDragSelection:)])
    {
        if (![self.delegate collectionViewCanDragSelection:self])
        {
            return;
        }
    }
    [self autoscroll:anEvent];
    
    if (isDragging) {
        NSUInteger index = [self.layoutManager indexOfItemContentRectAtPoint:mouseDownLocation];
        if (index != NSNotFound && [selectionIndexes count] > 0 && [self delegateSupportsDragForItemsAtIndexes:selectionIndexes]) {
            NSPoint mouse = [self convertPoint:[anEvent locationInWindow] fromView:nil];
            CGFloat distance = sqrt(pow(mouse.x-mouseDownLocation.x,2)+pow(mouse.y-mouseDownLocation.y,2));
            if (distance > 3)
                [self initiateDraggingSessionWithEvent:anEvent];
        } else
            [self regularMouseDragged:anEvent];
    }
}

- (void)mouseUp:(NSEvent *)theEvent
{
    [self setNeedsDisplayInRect:BCRectFromTwoPoints(mouseDownLocation, mouseDraggedLocation)];
    
    mouseDownLocation    = NSZeroPoint;
    mouseDraggedLocation = NSZeroPoint;
    
    isDragging = NO;
    self.originalSelectionIndexes = nil;
}

@end

