//
//  LHTag.m
//  LHCollectionView
//
//  Created by 浩  林 on 2019/2/24.
//  Copyright © 2019 linhao. All rights reserved.
//

#import "LHTag.h"
#import "LHImageFile.h"

@implementation LHTag
- (id)initWithName:(NSString *)newName {
    self = [super init];
    if (self) {
        name = [newName copy];
        imageFiles = [[NSMutableArray alloc] init];
    }
    return self;
}

@synthesize name;
@synthesize imageFiles;

- (void)insertImageFile:(LHImageFile *)imageFile {
    NSUInteger insertionIndex = [imageFiles indexOfObject:imageFile inSortedRange:NSMakeRange(0, [imageFiles count]) options:NSBinarySearchingInsertionIndex usingComparator:^NSComparisonResult(LHImageFile *imageFile1, LHImageFile *imageFile2) {
        return [imageFile1.filenameWithoutExtension caseInsensitiveCompare:imageFile2.filenameWithoutExtension];
    }];
    if (insertionIndex == NSNotFound) {
        NSLog(@"** Couldn't determine insertionIndex for imageFiles array");
    } else {
        [imageFiles insertObject:imageFile atIndex:insertionIndex];
    }
}

- (NSString *)description {
    return [NSString stringWithFormat:@"{Tag: %@}", self.name];
}
@end
