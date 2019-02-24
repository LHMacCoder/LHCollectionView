//  Created by Pieter Omvlee on 15/02/2011.
//  Copyright 2011 Bohemian Coding. All rights reserved.

#import "BCCollectionViewLayoutManager.h"
#import "BCCollectionView.h"
#import "BCCollectionViewGroup.h"
#import "BCCollectionViewLayoutItem.h"

@implementation BCCollectionViewLayoutManager

- (id)initWithCollectionView:(BCCollectionView *)aCollectionView
{
  self = [super init];
  if (self) {
    _collectionView = aCollectionView;
    _queue = [[NSOperationQueue alloc] init];
    [_queue setMaxConcurrentOperationCount:1];
  }
  return self;
}

- (void)cancelItemEnumerator
{
  [_queue cancelAllOperations];
}

- (void)enumerateItems:(BCCollectionViewLayoutOperationIterator)itemIterator completionBlock:(dispatch_block_t)completionBlock
{
  BCCollectionViewLayoutOperation *operation = [[BCCollectionViewLayoutOperation alloc] init];
  [operation setCollectionView:_collectionView];
  [operation setLayoutCallBack:itemIterator];
  [operation setLayoutCompletionBlock:completionBlock];
  
// if ([queue operationCount] > 10)
    [_queue cancelAllOperations];
  [_queue addOperation:operation];
}

- (void)dealloc
{
//  [itemLayouts release];
//  [queue release];
//  [super dealloc];
}

#pragma mark -
#pragma mark Primitives

- (NSUInteger)maximumNumberOfItemsPerRow
{
    return MAX(1, [_collectionView frame].size.width/[self cellSize].width);;
}



- (NSSize)cellSize
{
  return [_collectionView cellSize];
}

#pragma mark -
#pragma mark Rows and Columns

- (NSPoint)rowAndColumnPositionOfItemAtIndex:(NSUInteger)anIndex
{
  BCCollectionViewLayoutItem *itemLayout = [_itemLayouts objectAtIndex:anIndex];
  return NSMakePoint(itemLayout.columnIndex, itemLayout.rowIndex);
}

- (NSUInteger)indexOfItemAtRow:(NSUInteger)rowIndex column:(NSUInteger)colIndex
{
  __block NSUInteger index = NSNotFound;
  [_itemLayouts enumerateObjectsWithOptions:NSEnumerationConcurrent usingBlock:^(id item, NSUInteger idx, BOOL *stop) {
    if ([item rowIndex] == rowIndex && [item columnIndex] == colIndex) {
      index = [item itemIndex];
      *stop = YES;
    }
  }];
  return index;
}

#pragma mark -
#pragma mark From Point to Index

- (NSUInteger)indexOfItemAtPoint:(NSPoint)p
{
  NSInteger count = [_itemLayouts count];
  for (NSInteger i=0; i<count; i++)
    if (NSPointInRect(p, [[_itemLayouts objectAtIndex:i] itemRect]))
      return i;
  return NSNotFound;
}

- (NSUInteger)indexOfItemContentRectAtPoint:(NSPoint)p
{
  NSUInteger index = [self indexOfItemAtPoint:p];
  if (index != NSNotFound) {
    if (NSPointInRect(p, [self contentRectOfItemAtIndex:index]))
      return index;
    else
      return NSNotFound;
  }
  return index;
}

#pragma mark -
#pragma mark From Index to Rect

- (NSRect)rectOfItemAtIndex:(NSUInteger)anIndex
{
  if (anIndex < [_itemLayouts count])
    return [[_itemLayouts objectAtIndex:anIndex] itemRect];
  else
    return NSZeroRect;
}

- (NSRect)contentRectOfItemAtIndex:(NSUInteger)anIndex
{
  if (anIndex < [_itemLayouts count])
    return [[_itemLayouts objectAtIndex:anIndex] itemContentRect];
  else
    return NSZeroRect;
}
@end
