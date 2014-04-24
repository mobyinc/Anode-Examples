//
//  Anode.m
//  Anode
//
//  Created by James Jacoby on 8/9/13.
//  Copyright (c) 2013 Moby, Inc. All rights reserved.
//

#import "Anode.h"
#import "Anode_Private.h"
#import "ANUser_Private.h"
#import "ANClient_Private.h"
#import "ANCache.h"

NSString *const ANErrorKey = @"ANErrorKey";
NSString *const ANErrorOriginalError = @"ANErrorOriginalError";

static Anode* sharedAnodeInstance = nil;

@implementation Anode

+(Anode*)sharedInstance {
    if (!sharedAnodeInstance) {
        sharedAnodeInstance = [[Anode alloc] init];
    }
    
    return sharedAnodeInstance;
}

+(void)initializeWithBaseUrl:(NSString *)url clientToken:(NSString *)token {
    [Anode initializeWithBaseUrl:url
                     clientToken:token
                           appId:nil];
}

+(void)initializeWithBaseUrl:(NSString *)url clientToken:(NSString *)token appId:(NSNumber*)appId
{
    [Anode sharedInstance].baseUrl = url;
    [Anode sharedInstance].clientToken = token;
    [Anode sharedInstance].appId = appId;
    
    if ([ANUser currentUser]) {
        [Anode sharedInstance].userToken = [[ANUser currentUser] token];
    }    
}

+(NSURL *)baseUrl
{
    return [NSURL URLWithString:[Anode sharedInstance].baseUrl];
}

+(NSString *)token
{
    return [Anode sharedInstance].userToken ? [Anode sharedInstance].userToken : [Anode sharedInstance].clientToken;
}

+(NSString *)appId
{
    return [Anode sharedInstance].appId ? [Anode sharedInstance].appId : nil;
}

+(void)setCacheVersion:(NSNumber*)cacheVersion
{
    [ANCache sharedInstance].cacheVersion = cacheVersion;
}

#pragma mark - Private

-(void)setUserToken:(NSString *)userToken
{
    _userToken = userToken;
    
    if (_userToken)
        [ANClient setToken:userToken];
    else
        [ANClient setToken:self.clientToken];    
}

@end
