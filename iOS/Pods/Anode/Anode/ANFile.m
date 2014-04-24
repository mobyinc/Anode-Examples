//
//  ANFile.m
//  Anode
//
//  Created by James Jacoby on 9/11/13.
//  Copyright (c) 2013 Moby, Inc. All rights reserved.
//

#import "ANFile.h"
#import "ANClient_Private.h"
#import "ANFile_Private.h"
#import "NSError+Helpers.h"
#import "AFHTTPRequestOperation.h"

@implementation ANFile

+(ANFile *)fileWithName:(NSString *)fileName data:(NSData *)data
{
    ANFile* file = [[ANFile alloc] init];
    file.fileName = fileName;
    file.data = data;
    
    return file;
}

+(ANFile *)fileWithUrl:(NSString *)url
{
    ANFile* file = [[ANFile alloc] init];
    file.url = url;
    
    return file;
}

-(id)init
{
    self = [super init];
    
    if (self) {
        self.loaded = NO;
    }
    
    return self;
}

-(void)fetchWithBlock:(FileResultBlock)block
{
    if (!self.url) {
        block(nil, [NSError errorWithDescription:@"Cannot fetch a file with no url."]);
        return;
    }
    
    NSURLRequest* request = [NSURLRequest requestWithURL:[NSURL URLWithString:self.url]];
    AFHTTPRequestOperation* operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    

    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        self.data = responseObject;
        block(self, nil);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        block(nil, error);
    }];
    
    [operation start];
}

-(UIImage *)imageRepresentation
{
    if (self.data) {
        return [[UIImage alloc] initWithData:self.data];
    } else {
        NSLog(@"Warning: no data for image representation.");
        return [[UIImage alloc] init];
    }
}

@end
