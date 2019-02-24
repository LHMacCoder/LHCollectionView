//
//  LHImageCollection.h
//  LHCollectionView
//
//  Created by 浩  林 on 2019/2/24.
//  Copyright © 2019 linhao. All rights reserved.
//

#import <Foundation/Foundation.h>

@class LHImageFile;
@class LHTag;

@interface LHImageCollection : NSObject
{
    NSURL *rootURL;                         // 文件夹url,通过此URL搜索图片
    NSOperationQueue *fileTreeScanQueue;    // 异步浏览图片操作队列
    
    NSMutableArray *imageFiles;             // 有序的集合映像文件列表
    NSMutableDictionary *imageFilesByURL;   // TSImageFile字典，url作为key，可以快速查找图片
    NSMutableArray *untaggedImageFiles;     // 没有被任何TSTag引用的图像文件的有序列表
    
    NSMutableArray *tags;                   // 按字母顺序排列的标签列表
    NSMutableDictionary *tagsByName;
}
- (id)initWithRootURL:(NSURL *)newRootURL;


#pragma mark Properties

@property(readonly) NSURL *rootURL;
@property(readonly) NSArray *imageFiles;    // KVO observable


#pragma mark Querying the List of ImageFiles

- (LHImageFile *)imageFileForURL:(NSURL *)imageFileURL;


#pragma mark Modifying the List of ImageFiles

- (void)addImageFile:(LHImageFile *)imageFile;
- (void)insertImageFile:(LHImageFile *)imageFile atIndex:(NSUInteger)index;
- (void)removeImageFile:(LHImageFile *)imageFile;
- (void)removeImageFileAtIndex:(NSUInteger)index;
- (void)moveImageFileFromIndex:(NSUInteger)fromIndex toIndex:(NSUInteger)toIndex;


#pragma mark Modifying the List of Tags

@property(readonly) NSArray *tags;
- (LHTag *)tagWithName:(NSString *)name;
- (LHTag *)addTagWithName:(NSString *)name;

@property(readonly) NSArray *untaggedImageFiles;


#pragma mark Finding Image Files

- (void)startOrRestartFileTreeScan;
- (void)stopFileTreeScan;

@end

extern NSString *imageFilesKey;

