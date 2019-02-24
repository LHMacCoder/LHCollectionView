//  Created by Pieter Omvlee on 01/03/2011.
//  Copyright 2011 Bohemian Coding. All rights reserved.

#import "BCCollectionViewLayoutItem.h"

@implementation BCCollectionViewLayoutItem

+ (id)layoutItem
{
  return [[self alloc] init];
}

- (NSString *)description
{
  return [NSString stringWithFormat:@"i:%i r:%i c:%i", (int)_itemIndex, (int)_rowIndex, (int)_columnIndex];
}

@end
