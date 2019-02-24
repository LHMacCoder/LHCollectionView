//  Created by Pieter Omvlee on 01/03/2011.
//  Copyright 2011 Bohemian Coding. All rights reserved.

#import <Foundation/Foundation.h>

@class TSTag;
@interface BCCollectionViewGroup : NSObject
{
}
+ (id)groupWithTitle:(NSString *)title range:(NSRange)range itemArray:(NSArray *)array;
@property (copy) NSString *title;
@property NSRange itemRange;    // 用于计算分组标题的坐标 
@property (nonatomic) BOOL isCollapsed;
@property (nonatomic,strong) NSArray *itemArray;

@end
