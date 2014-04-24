//
//  ANUser.m
//  Anode
//
//  Created by James Jacoby on 8/10/13.
//  Copyright (c) 2013 Moby, Inc. All rights reserved.
//


#import "ANUser.h"
#import "Anode.h"
#import "ANCache.h"
#import "ANUser_Private.h"
#import "ANObject_Private.h"
#import "ANClient_Private.h"
#import "Anode_Private.h"
#import "ANJSONRequestOperation.h"
#import "NSError+Helpers.h"

static ANUser* sharedCurrentUser = nil;

#define CURRENT_USER_CACHE_KEY @"/user/current_user"

@implementation ANUser

+(ANUser *)userWithUsername:(NSString*)username password:(NSString*)password
{
    ANUser* user = (ANUser*)[self objectWithType:@"user"];
    [user setObject:username forKey:@"username"];
    [user setObject:password forKey:@"password"];
    
    return user;
}

+(void)loginWithUsername:(NSString*)username password:(NSString*)password block:(LoginBlock)block
{
    NSDictionary* parameters = nil;
    
    if (username && password) {
        parameters = @{@"username": username, @"password": password};
    }
    
    NSURLRequest* request = [ANClient requestForVerb:@"POST" type:@"user" objectId:nil action:@"login" parameters:parameters];
    
    ANJSONRequestOperation *operation = [ANJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
        NSError* error = nil;
        ANUser* user = (ANUser*)[ANUser objectWithJSON:JSON error:&error];
        [ANUser setCurrentUser:user];
        
        if (block) block(user, nil);
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
        if (block) block(nil, error);
    }];
    
    [operation start];
}

+(void)loginWithTwitterId:(NSString *)twitterId token:(NSString *)token secret:(NSString *)secret block:(LoginBlock)block
{
    NSDictionary* parameters = @{@"twitter_id": twitterId, @"twitter_token":token, @"twitter_secret":secret};    
    NSURLRequest* request = [ANClient requestForVerb:@"POST" type:@"user" objectId:nil action:@"login_or_create_twitter" parameters:parameters];
    
    ANJSONRequestOperation *operation = [ANJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
        NSError* error = nil;
        ANUser* user = (ANUser*)[ANUser objectWithJSON:JSON error:&error];
        [ANUser setCurrentUser:user];
        
        if (block) block(user, nil);
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
        if (block) block(nil, error);
    }];
    
    [operation start];
}

+(void)loginWithFacebookId:(NSString *)facebookId token:(NSString *)token block:(LoginBlock)block
{
    NSDictionary* parameters = @{@"facebook_id": facebookId, @"facebook_token":token};
    NSURLRequest* request = [ANClient requestForVerb:@"POST" type:@"user" objectId:nil action:@"login_or_create_facebook" parameters:parameters];
    
    ANJSONRequestOperation *operation = [ANJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
        NSError* error = nil;
        ANUser* user = (ANUser*)[ANUser objectWithJSON:JSON error:&error];
        [ANUser setCurrentUser:user];
        
        if (block) block(user, nil);
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
        if (block) block(nil, error);
    }];
    
    [operation start];
}

+(void)refreshLoginWithBlock:(LoginBlock)block
{
    if (![ANUser currentUser]) {
        if (block) block(nil, [NSError errorWithDescription:@"Cannot refresh login while logged out."]);
        return;
    }
    
    NSString* provider = [[ANUser currentUser] objectForKey:@"__provider"];

    // TODO: use respective providers
    if ([provider isEqualToString:@"twitter"]) {
        [ANUser loginWithUsername:nil password:nil block:block];
    } else if ([provider isEqualToString:@"facebook"]) {
        [ANUser loginWithUsername:nil password:nil block:block];
    } else {
        [ANUser loginWithUsername:nil password:nil block:block];
    }
}

+(void)registerDeviceTokenWithData:(NSData *)data block:(CompletionBlock)block
{
    if (![ANUser currentUser]) {
        NSLog(@"Cannot register device token without current user.");
        return;
    }
    
    NSString* token = [[data description] stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"<>"]];

    NSURLRequest* request = [ANClient requestForVerb:@"POST" type:@"user" objectId:nil action:@"register_device_token" parameters:@{@"device_token":token}];
    
    ANJSONRequestOperation *operation = [ANJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
        if (block) block(nil, nil);
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
        if (block) block(nil, error);
    }];
    
    [operation start];
}

+(void)logout
{
    sharedCurrentUser = nil;
    [Anode sharedInstance].userToken = nil;
    [[ANCache sharedInstance] clearObjectForKey:CURRENT_USER_CACHE_KEY];
}

+(void)resetPasswordWithUsername:(NSString *)username block:(CompletionBlock)block
{
    NSURLRequest* request = [ANClient requestForVerb:@"POST" type:@"user" objectId:nil action:@"reset_password" parameters:@{@"username":username}];
    
    ANJSONRequestOperation *operation = [ANJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
        if (block) block(nil, nil);
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
        if (block) block(nil, error);
    }];
    
    [operation start];
}

+(ANUser*)currentUser
{
    if (!sharedCurrentUser) {
        sharedCurrentUser = [[ANCache sharedInstance] objectForKey:CURRENT_USER_CACHE_KEY];
    }
    
    return sharedCurrentUser;
}

#pragma mark - Special Properties

-(NSString *)username
{
    return [self objectForKey:@"username"];
}

-(void)setUsername:(NSString *)username
{
    [self setObject:username forKey:@"username"];
}

-(NSString *)password
{
    return [self objectForKey:@"password"];
}

-(void)setPassword:(NSString *)password
{
    [self setObject:password forKey:@"password"];
}

#pragma mark - Private

-(NSString *)token
{
    return [self.attributes objectForKey:@"__token"];
}

+(void)setCurrentUser:(ANUser*)user
{
    sharedCurrentUser = user;
    [[ANCache sharedInstance] setObject:user forKey:CURRENT_USER_CACHE_KEY];
    [Anode sharedInstance].userToken = [user token];
}

@end
