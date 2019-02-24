//
//  LHImageCollection.m
//  LHCollectionView
//
//  Created by 浩  林 on 2019/2/24.
//  Copyright © 2019 linhao. All rights reserved.
//

#import "LHImageCollection.h"
#import "LHImageFile.h"
#import "LHTag.h"

NSString *imageFilesKey = @"imageFiles";
static NSString *tagsKey = @"tags";


@implementation LHImageCollection

- (id)initWithRootURL:(NSURL *)newRootURL {
    
    self = [super init];
    if (self) {
        rootURL = [newRootURL copy];
        imageFiles = [[NSMutableArray alloc] init];
        imageFilesByURL = [[NSMutableDictionary alloc] init];
        untaggedImageFiles = [[NSMutableArray alloc] init];
        tags = [[NSMutableArray alloc] init];
        tagsByName = [[NSMutableDictionary alloc] init];
        fileTreeScanQueue = [[NSOperationQueue alloc] init];
        fileTreeScanQueue.name = @"LHImageCollection File Tree Scan Queue";
        
        [self startObservingImageCollection];
        [self startOrRestartFileTreeScan];
    }
    return self;
}


#pragma mark Property Accessors

@synthesize rootURL;
@synthesize imageFiles;
@synthesize untaggedImageFiles;


#pragma mark Querying the List of ImageFiles

- (LHImageFile *)imageFileForURL:(NSURL *)imageFileURL {
    return imageFilesByURL[imageFileURL];
}


#pragma mark Modifying the List of ImageFiles

- (void)addImageFile:(LHImageFile *)imageFile {
    [self insertImageFile:imageFile atIndex:imageFiles.count];
    [imageFile requestPreviewImage];
}

- (void)insertImageFile:(LHImageFile *)imageFile atIndex:(NSUInteger)index {
    
    // 根据imagefile的tagnamees添加更新tags
    NSArray *tagNames = imageFile.tagNames;
    if (tagNames.count > 0) {
        for (NSString *tagName in imageFile.tagNames) {
            LHTag *tag = [self tagWithName:tagName];
            if (tag == nil) {
                tag = [self addTagWithName:tagName];
            }
            [tag insertImageFile:imageFile];
        }
    } else {
        // imagefile 没有tags，所以添加到"untaggedImageFiles"
        NSUInteger insertionIndex = [untaggedImageFiles indexOfObject:imageFile inSortedRange:NSMakeRange(0, untaggedImageFiles.count) options:NSBinarySearchingInsertionIndex usingComparator:^NSComparisonResult(LHImageFile *imageFile1, LHImageFile *imageFile2) {
            return [imageFile1.filenameWithoutExtension caseInsensitiveCompare:imageFile2.filenameWithoutExtension];
        }];
        if (insertionIndex == NSNotFound) {
            NSLog(@"Failed to find insertion index for untaggedImageFiles");
        } else {
            [untaggedImageFiles insertObject:imageFile atIndex:insertionIndex];
        }
    }
    
    // Insert the imageFile into our "imageFiles" array (in a KVO-compliant way).
    [[self mutableArrayValueForKey:imageFilesKey] insertObject:imageFile atIndex:index];
    
    // Add the imageFile into our "imageFilesByURL" dictionary.
    [imageFilesByURL setObject:imageFile forKey:imageFile.url];
}

- (void)removeImageFile:(LHImageFile *)imageFile {
    
    // Remove the imageFile from our "imageFiles" array (in a KVO-compliant way).
    [[self mutableArrayValueForKey:imageFilesKey] removeObject:imageFile];
    
    // Remove the imageFile from our "imageFilesByURL" dictionary.
    [imageFilesByURL removeObjectForKey:imageFile.url];
    
    // Remove the imageFile from the "imageFiles" arrays of its TSTags (if any).
    for (NSString *tagName in imageFile.tagNames) {
        LHTag *tag = [self tagWithName:tagName];
        if (tag) {
            [[tag mutableArrayValueForKey:@"imageFiles"] removeObject:imageFile];
        }
    }
}

- (void)removeImageFileAtIndex:(NSUInteger)index {
    LHImageFile *imageFile = [imageFiles objectAtIndex:index];
    [self removeImageFile:imageFile];
}

- (void)moveImageFileFromIndex:(NSUInteger)fromIndex toIndex:(NSUInteger)toIndex {
    NSUInteger imageFilesCount = imageFiles.count;
    NSParameterAssert(fromIndex < imageFilesCount);
    NSParameterAssert(fromIndex < imageFilesCount);
    LHImageFile *imageFile = [imageFiles objectAtIndex:fromIndex];
    [self removeImageFileAtIndex:fromIndex];
    [self insertImageFile:imageFile atIndex:(toIndex <= fromIndex) ? toIndex : (toIndex - 1)];
}


#pragma mark Modifying the List of Tags

@synthesize tags;

- (LHTag *)tagWithName:(NSString *)name {
    return [tagsByName objectForKey:name];
}

- (LHTag *)addTagWithName:(NSString *)name {
    LHTag *tag = [self tagWithName:name];
    if (tag == nil) {
        tag = [[LHTag alloc] initWithName:name];
        if (tag) {
            [tagsByName setObject:tag forKey:name];
            
            // Binary-search and insert, in alphabetized tags array.
            NSUInteger insertionIndex = [tags indexOfObject:tag inSortedRange:NSMakeRange(0, [tags count]) options:NSBinarySearchingInsertionIndex usingComparator:^NSComparisonResult(LHTag *tag1, LHTag *tag2) {
                return [tag1.name caseInsensitiveCompare:tag2.name];
            }];
            if (insertionIndex == NSNotFound) {
                NSLog(@"** ERROR: Can't find insertion index in 'tags' array");
            } else {
                [tags insertObject:tag atIndex:insertionIndex];
            }
        }
    }
    return tag;
}


#pragma mark Finding Image Files

- (void)startObservingImageCollection {
    /*
     Sign up for Key-Value Observing (KVO) notifications, that will tell us
     when the content of our imageCollection changes.  If we are showing
     its ImageFiles grouped by tag, we want to observe the imageCollection's
     "tags" array, and the "imageFiles" array of each AAPLTag.  If we are
     showing our imageCollection's ImageFiles without grouping, we instead
     want to simply observe the imageCollection's "imageFiles" array.
     
     Whenever a change occurs, KVO will send us an
     -observeValueForKeyPath:ofObject:change:context: message, which we
     can respond to as needed to update the set of slides that we
     display.
     */
    [self addObserver:self forKeyPath:tagsKey options:0 context:NULL];
    for (LHTag *tag in self.tags) {
        [tag addObserver:self forKeyPath:imageFilesKey options:0 context:NULL];
    }
}


- (void)startOrRestartFileTreeScan {
    @synchronized(fileTreeScanQueue) {
        // Cancel any pending file tree scan operations.
        [self stopFileTreeScan];
        
        // Enqueue a new file tree scan operation.
        [fileTreeScanQueue addOperationWithBlock:^{
            
            /*
             Enumerate all of the image files in our given rootURL.  As we
             go, identify three groups of image files:
             
             (1) files that are in the catalog, but have since changed (the
             file's modification date is later than its last-cached date)
             
             (2) files that exist on disk but are not yet in the catalog
             (presumably the file was added and we should create an
             ImageFile instance for it)
             
             (3) files that exist in the ImageCollection but not in the
             folder (presumably the file was deleted and we should remove
             the corresponding ImageFile instance)
             */
            NSMutableArray *filesToProcess = [self.imageFiles mutableCopy];
            LHImageFile *imageFile;
            NSMutableArray *filesChanged = [NSMutableArray array];
            NSMutableArray *urlsAdded = [NSMutableArray array];
            NSMutableArray *filesRemoved = [NSMutableArray array];
            
            NSDirectoryEnumerator *directoryEnumerator = [[NSFileManager defaultManager] enumeratorAtURL:self.rootURL includingPropertiesForKeys:[NSArray arrayWithObjects:NSURLIsRegularFileKey, NSURLTypeIdentifierKey, NSURLContentModificationDateKey, nil] options:(NSDirectoryEnumerationSkipsSubdirectoryDescendants | NSDirectoryEnumerationSkipsPackageDescendants) errorHandler:^BOOL(NSURL *url, NSError *error) {
                NSLog(@"directoryEnumerator error: %@", error);
                return YES;
            }];
            for (NSURL *url in directoryEnumerator) {
                NSError *error;
                NSNumber *isRegularFile = nil;
                if ([url getResourceValue:&isRegularFile forKey:NSURLIsRegularFileKey error:&error]) {
                    if ([isRegularFile boolValue]) {
                        NSString *fileType = nil;
                        if ([url getResourceValue:&fileType forKey:NSURLTypeIdentifierKey error:&error]) {
                            if (UTTypeConformsTo((__bridge CFStringRef)fileType, CFSTR("public.image"))) {
                                
                                // Look for a corresponding entry in the catalog.
                                imageFile = [self imageFileForURL:url];
                                if (imageFile != nil) {
                                    // Check whether file has changed.
                                    NSDate *modificationDate = nil;
                                    if ([url getResourceValue:&modificationDate forKey:NSURLContentModificationDateKey error:&error]) {
                                        if ([modificationDate compare:imageFile.dateLastUpdated] == NSOrderedDescending) {
                                            [filesChanged addObject:imageFile];
                                        }
                                    }
                                    [filesToProcess removeObject:imageFile];
                                } else {
                                    // File was added.
                                    [urlsAdded addObject:url];
                                }
                            }
                        }
                    }
                }
            }
            
            // Check for images in the catalog for which no corresponding file was found.
            [filesRemoved addObjectsFromArray:filesToProcess];
            filesToProcess = nil;
            
            /*
             Perform our ImageCollection modifications on the main thread, so
             that corresponding KVO notifications and CollectionView updates will
             also happen on the main thread.
             */
            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                
                // Remove ImageFiles for files we knew about that have disappeared.
                for (LHImageFile *imageFile in filesRemoved) {
                    [self removeImageFile:imageFile];
                }
                
                // Add ImageFiles for files we've newly discovered.
                for (NSURL *imageFileURL in urlsAdded) {
                    LHImageFile *imageFile = [[LHImageFile alloc] initWithURL:imageFileURL];
                    if (imageFile != nil) {
                        [self addImageFile:imageFile];
                    }
                }
                
            }];
        }];
    }
    
}

- (void)stopFileTreeScan {
    @synchronized(fileTreeScanQueue) {
        [fileTreeScanQueue cancelAllOperations];
    }
}

#pragma mark Teardown

- (void)dealloc {
}

@end

