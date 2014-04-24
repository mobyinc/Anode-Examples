//
//  ANClient.m
//  Anode
//
//  Created by James Jacoby on 8/18/13.
//  Copyright (c) 2013 Moby, Inc. All rights reserved.
//

#import "ANClient.h"
#import "ANClient_Private.h"
#import "Anode.h"
#import "ANJSONRequestOperation.h"
#import "NSString+ActiveSupportInflector.h"

static AFHTTPClient* sharedClient = nil;

@implementation ANClient

+(void)setToken:(NSString *)token
{
    [[self client] setDefaultHeader:@"Authorization" value:[NSString stringWithFormat:@"Token token=%@", token]];
}

+(NSString*)pathForType:(NSString *)type objectId:(NSNumber *)objectId action:(NSString *)action
{
    NSString* typeSegment = [type pluralizeString];
    NSString* path = nil;
    
    if (action && objectId) {
        path = [NSString stringWithFormat:@"%@/%@/%@", typeSegment, objectId, action];
    } else if (objectId) {
        path = [NSString stringWithFormat:@"%@/%@", typeSegment, objectId];
    } else if (action) {
        path = [NSString stringWithFormat:@"%@/%@", typeSegment, action];
    } else {
        path = [NSString stringWithFormat:@"%@/", typeSegment];
    }
    
    return path;
}

+(NSMutableURLRequest *)requestForVerb:(NSString *)verb type:(NSString *)type objectId:(NSNumber *)objectId action:(NSString *)action parameters:(NSDictionary *)parameters
{
    NSString* path = [ANClient pathForType:type objectId:objectId action:action];
    NSMutableURLRequest* request = [[ANClient client] requestWithMethod:verb path:path parameters:parameters];
    
    return request;
}

+(NSMutableURLRequest*)multipartRequestForVerb:(NSString *)verb type:(NSString *)type objectId:(NSNumber *)objectId action:(NSString *)action parameters:(NSDictionary *)parameters formBodyData:(NSData*)formBodyData files:(NSDictionary*)files
{
    NSString* path = [ANClient pathForType:type objectId:objectId action:action];
    
    NSMutableURLRequest *request = [[ANClient client] multipartFormRequestWithMethod:verb
                                                                                path:path
                                                                          parameters:parameters
                                                           constructingBodyWithBlock: ^(id <AFMultipartFormData> formData)
        {
            [formData appendPartWithFormData:formBodyData name:@"DATA"];
            
            for (NSString* key in files.allKeys) {
                ANFile* file = files[key];
                NSString* name = [NSString stringWithFormat:@"%@[%@]", type, key];
                [formData appendPartWithFileData:file.data name:name fileName:file.fileName mimeType:@"image/png"];
            }
        }];
    
    return request;
}

-(id)init
{
    self = [super init];
    
    if (self) {
        self.dateFormatter = [[NSDateFormatter alloc] init];
        [self.dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ssZZZZ"];
    }
    
    return self;
}

+(AFHTTPClient *)client
{
    if (!sharedClient) {
        sharedClient = [[AFHTTPClient alloc] initWithBaseURL:[Anode baseUrl]];
        [sharedClient registerHTTPOperationClass:[ANJSONRequestOperation class]];
        [sharedClient setDefaultHeader:@"Accept" value:@"application/json"];
        [sharedClient setDefaultHeader:@"Content-Type" value:@"application/json"];
        [sharedClient setDefaultHeader:@"Authorization" value:[NSString stringWithFormat:@"Token token=%@", [Anode token]]];
        
        if ([Anode appId] != nil) {
            [sharedClient setDefaultHeader:@"AppId" value:[Anode appId]];
        }
    }
    
    return sharedClient;
}

-(NSMutableURLRequest *)requestForVerb:(NSString*)verb
{
    return [self requestForVerb:verb objectId:nil action:nil parameters:nil];
}

-(NSMutableURLRequest*)requestForVerb:(NSString*)verb objectId:(NSNumber*)objectId
{
    return [self requestForVerb:verb objectId:objectId action:nil parameters:nil];
}

-(NSMutableURLRequest*)requestForVerb:(NSString*)verb action:(NSString*)action
{
    return [self requestForVerb:verb objectId:nil action:action parameters:nil];
}

-(NSMutableURLRequest *)requestForVerb:(NSString*)verb objectId:(NSNumber *)objectId action:(NSString*)action parameters:(NSDictionary*)parameters
{
    return [ANClient requestForVerb:verb type:self.type objectId:objectId action:action parameters:parameters];
}

-(NSMutableURLRequest*)multipartRequestForVerb:(NSString*)verb objectId:(NSNumber *)objectId action:(NSString*)action parameters:(NSDictionary*)parameters formBodyData:(NSData*)formBodyData files:(NSDictionary*)files {
    return [ANClient multipartRequestForVerb:verb type:self.type objectId:objectId action:action parameters:parameters formBodyData:formBodyData files:files];
}

@end
