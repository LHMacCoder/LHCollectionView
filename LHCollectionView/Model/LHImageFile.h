//
//  LHImageFile.h
//  LHCollectionView
//
//  Created by 浩  林 on 2019/2/24.
//  Copyright © 2019 linhao. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface LHImageFile : NSObject
{
    CGImageSourceRef imageSource;           // NULL until metadata is loaded
    NSDictionary *imageProperties;          // nil until metadata is loaded
}

- (id)initWithURL:(NSURL *)newURL;


#pragma mark File Properties

@property(copy) NSURL *url;    // 图片的来源
@property(copy) NSString *fileType;
@property unsigned long long fileSize;
@property(copy) NSDate *dateLastUpdated;
@property(copy) NSArray *tagNames;    // 根据里面的值，将图片加入到相应的session.

@property(readonly) NSString *filename;
@property(readonly) NSString *filenameWithoutExtension;
@property(readonly) NSString *localizedTypeDescription;
@property(readonly) NSString *dimensionsDescription;


#pragma mark Image Properties

@property(readonly) NSInteger pixelsWide;
@property(readonly) NSInteger pixelsHigh;

@property(strong) NSImage *previewImage;


#pragma mark Loading

// 在第一次请求相关属性时，会自动触发这些属性，但可以显式调用以强制提前加载。
- (BOOL)loadMetadata;

- (void)requestPreviewImage;

@end


NS_ASSUME_NONNULL_END
