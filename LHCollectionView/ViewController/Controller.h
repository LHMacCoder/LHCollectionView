//
//  Controller.h
//  LHCollectionView
//
//  Created by 浩  林 on 2019/2/24.
//  Copyright © 2019 linhao. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BCCollectionView.h"

NS_ASSUME_NONNULL_BEGIN

@class LHImageCollection;
@interface Controller : NSObject <BCCollectionViewDelegate>
{
    NSMutableArray *imageContent;
    BCCollectionView *collectionView;
    LHImageCollection *imageCollection;
}
@property(nonatomic,retain) IBOutlet BCCollectionView *collectionView;
@property(nonatomic,retain) NSMutableArray *imageContent;
@property (nonatomic,strong) LHImageCollection *imageCollection;

- (IBAction)closeGroup:(id)sender;
- (IBAction)openGroup:(id)sender;
@end

NS_ASSUME_NONNULL_END
