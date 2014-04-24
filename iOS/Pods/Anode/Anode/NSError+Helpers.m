//
//  NSError+Helpers.m
//  Anode
//
//  Created by James Jacoby on 8/17/13.
//  Copyright (c) 2013 Moby, Inc. All rights reserved.
//

#import "NSError+Helpers.h"
#import "Anode.h"

@implementation NSError (Helpers)

+(NSError*)errorWithDescription:(NSString*)description
{
    return [NSError errorWithCode:0 key:@"error" description:description originalError:nil];
}

+(NSError*)errorWithCode:(NSInteger)code description:(NSString*)description
{
    return [NSError errorWithCode:code key:@"error" description:description originalError:nil];
}

+(NSError*)errorWithCode:(NSInteger)code key:(NSString*)key description:(NSString*)description originalError:(NSError*)originalError
{
    if (originalError)
        return [NSError errorWithDomain:@"anode" code:code userInfo:@{@"NSLocalizedDescription" : description, ANErrorOriginalError : originalError, ANErrorKey : key}];
    else
        return [NSError errorWithDomain:@"anode" code:code userInfo:@{@"NSLocalizedDescription" : description}];
}

@end
