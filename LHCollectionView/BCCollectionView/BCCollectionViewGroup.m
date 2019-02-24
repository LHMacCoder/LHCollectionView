//  Created by Pieter Omvlee on 01/03/2011.
//  Copyright 2011 Bohemian Coding. All rights reserved.

#import "BCCollectionViewGroup.h"

@implementation BCCollectionViewGroup

+ (id)groupWithTitle:(NSString *)title range:(NSRange)range itemArray:(NSArray *)array
{
    BCCollectionViewGroup *group = [[BCCollectionViewGroup alloc] init];
    [group setTitle:title];
    [group setItemRange:range];
    [group setItemArray:array];
    return group;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"%@ %@", _title, NSStringFromRange(_itemRange)];
}

//- (void)dealloc
//{
//  [title release];
//  [super dealloc];
//}

- (NSString *)defaultsIdentifier
{
    return [NSString stringWithFormat:@"collectionGroup%@Status", _title];
}

- (void)setItemArray:(NSArray *)itemArray
{
    if (_itemArray == nil)
    {
        _itemArray = [NSArray new];
    }
    _itemArray = itemArray;
}

- (BOOL)isCollapsed
{
    return [[NSUserDefaults standardUserDefaults] boolForKey:[self defaultsIdentifier]];
}

- (void)setIsCollapsed:(BOOL)isCollapsed
{
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    [ud setBool:isCollapsed forKey:[self defaultsIdentifier]];
    [ud synchronize];
}


@end
