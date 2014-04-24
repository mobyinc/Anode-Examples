//
//  ANJSONRequestOperation.m
//  Anode
//
//  Created by James Jacoby on 8/17/13.
//  Copyright (c) 2013 Moby, Inc. All rights reserved.
//

#import "ANJSONRequestOperation.h"
#import "NSError+Helpers.h"

@implementation ANJSONRequestOperation

+ (instancetype)JSONRequestOperationWithRequest:(NSURLRequest *)urlRequest
                                        success:(void (^)(NSURLRequest *request, NSHTTPURLResponse *response, id JSON))success
                                        failure:(void (^)(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON))failure;
{
    ANJSONRequestOperation *requestOperation = [(ANJSONRequestOperation *)[self alloc] initWithRequest:urlRequest];
    
    [requestOperation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        if (success) {
            success(operation.request, operation.response, responseObject);
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if (failure) {
            id JSON = [(AFJSONRequestOperation *)operation responseJSON];
            NSString* description = @"unknown error";
            NSString* key = @"error";
            int code = 0;
            
            if (JSON && JSON[@"error"]) {
                @try {
                    description = JSON[@"error"][@"message"] ? JSON[@"error"][@"message"] : @"unspecified error";
                    code = JSON[@"error"][@"code"] ? [JSON[@"error"][@"code"] intValue] : 0;
                    key = JSON[@"error"][@"key"] ? JSON[@"error"][@"key"] : @"error";
                }
                @catch (NSException *exception) {
                    NSLog(@"error parsing error response");
                }
            } else if (error && (error.code == -1004 || error.code == -1009)) {
                description = @"Could not connect to server";
                key = @"connection_error";
                code = 503;
            }
            
            NSError* friendlyError = [NSError errorWithCode:code key:key description:description originalError:error];
            
            failure(operation.request, operation.response, friendlyError, JSON);
        }
    }];
    
    return requestOperation;
}

@end
