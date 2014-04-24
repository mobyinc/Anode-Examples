//
//  NSError+Helpers.h
//  Anode
//
//  Created by James Jacoby on 8/17/13.
//  Copyright (c) 2013 Moby, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSError (Helpers)

+(NSError*)errorWithDescription:(NSString*)description;
+(NSError*)errorWithCode:(NSInteger)code description:(NSString*)description;
+(NSError*)errorWithCode:(NSInteger)code key:(NSString*)key description:(NSString*)description originalError:(NSError*)originalError;

@end
