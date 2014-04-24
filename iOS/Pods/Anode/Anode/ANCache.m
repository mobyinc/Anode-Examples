//
//  ANCache.m
//  Anode
//
//  Created by FourtyTwo on 8/21/13.
//  Copyright (c) 2013 Moby, Inc. All rights reserved.
//

#import "ANCache.h"
#import "Anode.h"

int ANCacheVersion = 1;

static ANCache* sharedCache = nil;

@interface ANCache ()

@property (nonatomic, strong) NSString* cachePath;
@property (nonatomic, assign) long maxCacheSize;

-(void)pruneCache;
-(long)cacheSize;

@end

@implementation ANCache

+(ANCache *)sharedInstance
{
    if (!sharedCache) {
        sharedCache = [[ANCache alloc] init];
    }
    
    return sharedCache;
}

-(id)init
{
    self = [super init];
    
    if (self) {
        self.maxCacheSize = 5 * 1024 * 1024; // 5 MB
        
        NSArray* paths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
        self.cachePath = [[paths objectAtIndex:0] stringByAppendingPathComponent:@"/Anode_Object_Cache"];
        
        if (![[NSFileManager defaultManager] fileExistsAtPath:self.cachePath]) {
            [[NSFileManager defaultManager] createDirectoryAtPath:self.cachePath withIntermediateDirectories:YES attributes:nil error:nil];
            [[NSFileManager defaultManager] createDirectoryAtPath:[self.cachePath stringByAppendingPathComponent:@"/user/"] withIntermediateDirectories:YES attributes:nil error:nil];
        }
    }
    
    return self;
}

-(id)objectForKey:(NSString*)key
{
    NSString* path = [self pathForStorageKey:key];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
        return [NSKeyedUnarchiver unarchiveObjectWithFile:path];
    } else {
        return nil;
    }
}

-(BOOL)setObject:(id<NSCoding>)object forKey:(NSString *)key
{
    NSString* path = [self pathForStorageKey:key];
    BOOL result = [NSKeyedArchiver archiveRootObject:object toFile:path];
    
    // periodically prune cache
    if (arc4random() % 5 == 0) {
        [[NSOperationQueue currentQueue] addOperationWithBlock:^{
            [self pruneCache];
        }];
    }
    
    return result;
}

-(void)clearObjectForKey:(NSString *)key
{
    NSString* path = [self pathForStorageKey:key];
    [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
}

#pragma mark - Properties

-(NSNumber *)cacheVersion
{
    NSNumber* cacheVersion = [[NSUserDefaults standardUserDefaults] objectForKey:@"anode_cache_version"];
    return cacheVersion ? cacheVersion : @(ANCacheVersion);
}

-(void)setCacheVersion:(NSNumber *)cacheVersion
{
    NSNumber* currentVersion = [self cacheVersion];
    
    if (![cacheVersion isEqualToNumber:currentVersion]) {
        [self clearCache];
    }
    
    [[NSUserDefaults standardUserDefaults] setObject:cacheVersion forKey:@"anode_cache_version"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

#pragma mark - Private

-(void)pruneCache
{
    long cacheSize = [self cacheSize];
    
    if (cacheSize < self.maxCacheSize) return;

    NSError* error = nil;
    
    NSFileManager* fm = [NSFileManager defaultManager];
    NSArray* files = [fm contentsOfDirectoryAtPath:self.cachePath error:&error];
    NSMutableArray* filesAndProperties = [NSMutableArray arrayWithCapacity:[files count]];
    
    // get all files and their modified date
    for (NSString* fileName in files) {
        BOOL isDirectory;
        NSString* fullPath = [self.cachePath stringByAppendingPathComponent:fileName];
        NSDictionary* properties = [fm attributesOfItemAtPath:fullPath error:&error];
        NSDate* modifiedDate = [properties objectForKey:NSFileModificationDate];
        NSNumber* size = [properties objectForKey:NSFileSize];
        
        if (!error && [fm fileExistsAtPath:fullPath isDirectory:&isDirectory] && !isDirectory) {
            [filesAndProperties addObject:@{@"path" : fullPath, @"modified" : modifiedDate, @"size" : size}];
        }
    }
    
    // sort
    NSArray* sortedFiles = [filesAndProperties sortedArrayUsingComparator:^(id file1, id file2)
    {
        NSComparisonResult comp = [[file1 objectForKey:@"modified"] compare:[file2 objectForKey:@"modified"]];
        if (comp == NSOrderedDescending) {
            comp = NSOrderedAscending;
        } else if(comp == NSOrderedAscending) {
            comp = NSOrderedDescending;
        }
        return comp;
    }];
    
    float needToRemove = cacheSize - self.maxCacheSize;
    error = nil;
    
    for (int i = 0; i < sortedFiles.count; i++) {
        if (needToRemove <= 0) return;
        
        NSDictionary* fileInfo = sortedFiles[i];
        NSNumber* size = fileInfo[@"size"];
        
        [fm removeItemAtPath:fileInfo[@"path"] error:&error];
        needToRemove -= size.longValue;
    }
}

-(void)clearCache
{
    NSFileManager* fm = [NSFileManager defaultManager];
    NSError *error = nil;
    
    for (NSString* fileName in [fm contentsOfDirectoryAtPath:self.cachePath error:&error]) {
        BOOL isDirectory;
        NSString* fullPath = [self.cachePath stringByAppendingPathComponent:fileName];
        
        if ([fm fileExistsAtPath:fullPath isDirectory:&isDirectory] && !isDirectory) {
            [fm removeItemAtPath:fullPath error:&error];
        }
    }
}

-(long)cacheSize
{
    NSArray* filesArray = [[NSFileManager defaultManager] subpathsOfDirectoryAtPath:self.cachePath error:nil];
    NSEnumerator* filesEnumerator = [filesArray objectEnumerator];
    NSString* fileName;
    unsigned long long int fileSize = 0;
        
    while (fileName = [filesEnumerator nextObject]) {
        NSDictionary* fileDictionary = [[NSFileManager defaultManager] attributesOfItemAtPath:[self.cachePath stringByAppendingPathComponent:fileName] error:nil];
        if (fileDictionary) fileSize += [fileDictionary fileSize];
    }
        
    return fileSize;
}

-(NSString*)pathForStorageKey:(NSString*)key
{    
    NSString* filename = [NSString stringWithFormat:@"%@.obj", key];
    return [self.cachePath stringByAppendingPathComponent:filename];
}

@end
