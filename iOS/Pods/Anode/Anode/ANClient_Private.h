//
//  ANClient_Private.h
//  Anode
//
//  Created by James Jacoby on 8/18/13.
//  Copyright (c) 2013 Moby, Inc. All rights reserved.
//

#import "ANClient.h"
#import "AFNetworking.h"

@interface ANClient ()

@property (nonatomic, strong) NSString* type;
@property (nonatomic, strong) NSDateFormatter* dateFormatter;

+(AFHTTPClient*)client;
+(void)setToken:(NSString*)token;

+(NSMutableURLRequest*)requestForVerb:(NSString*)verb type:(NSString*)type objectId:(NSNumber *)objectId action:(NSString*)action parameters:(NSDictionary*)parameters;

+(NSMutableURLRequest*)multipartRequestForVerb:(NSString *)verb type:(NSString *)type objectId:(NSNumber *)objectId action:(NSString *)action parameters:(NSDictionary *)parameters formBodyData:(NSData*)formBodyData files:(NSDictionary*)files;

-(NSMutableURLRequest*)requestForVerb:(NSString*)verb;
-(NSMutableURLRequest*)requestForVerb:(NSString*)verb objectId:(NSNumber*)objectId;
-(NSMutableURLRequest*)requestForVerb:(NSString*)verb action:(NSString*)action;
-(NSMutableURLRequest*)requestForVerb:(NSString*)verb objectId:(NSNumber *)objectId action:(NSString*)action parameters:(NSDictionary*)parameters;
-(NSMutableURLRequest*)multipartRequestForVerb:(NSString*)verb objectId:(NSNumber *)objectId action:(NSString*)action parameters:(NSDictionary*)parameters formBodyData:(NSData*)formBodyData files:(NSDictionary*)files;
@end
