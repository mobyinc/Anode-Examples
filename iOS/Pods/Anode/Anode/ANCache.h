//
//  ANCache.h
//  Anode
//
//  Created by FourtyTwo on 8/21/13.
//  Copyright (c) 2013 Moby, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#define ANODE_CACHE_VERSION 1

@interface ANCache : NSObject

@property (nonatomic, copy) NSNumber* cacheVersion;

+(ANCache*)sharedInstance;

-(id)objectForKey:(NSString*)key;
-(BOOL)setObject:(id<NSCoding>)object forKey:(NSString*)key;
-(void)clearObjectForKey:(NSString*)key;

@end
