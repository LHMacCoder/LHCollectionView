//
//  LHTag.h
//  LHCollectionView
//
//  Created by 浩  林 on 2019/2/24.
//  Copyright © 2019 linhao. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class LHImageFile;
@interface LHTag : NSObject
{
    NSString *name;                 // the tag string (e.g. "Vacation")
    NSMutableArray *imageFiles;     // the ImageFiles that have this tag, ordered for display using our desired sort
}
- initWithName:(NSString *)newName;

@property(readonly) NSString *name;

@property(readonly) NSArray *imageFiles;

- (void)insertImageFile:(LHImageFile *)imageFile;
@end

NS_ASSUME_NONNULL_END
