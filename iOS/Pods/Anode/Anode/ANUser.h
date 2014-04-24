//
//  ANUser.h
//  Anode
//
//  Created by James Jacoby on 8/10/13.
//  Copyright (c) 2013 Moby, Inc. All rights reserved.
//

#import "ANObject.h"

@interface ANUser : ANObject

@property (nonatomic, retain) NSString* username;
@property (nonatomic, retain) NSString* password;
@property (nonatomic, readonly) BOOL authenticated;

+(ANUser *)userWithUsername:(NSString*)username password:(NSString*)password;
+(void)loginWithUsername:(NSString*)username password:(NSString*)password block:(LoginBlock)block;
+(void)loginWithTwitterId:(NSString*)twitterId token:(NSString*)token secret:(NSString*)secret block:(LoginBlock)block;
+(void)loginWithFacebookId:(NSString*)facebookId token:(NSString*)token block:(LoginBlock)block;
+(void)refreshLoginWithBlock:(LoginBlock)block;
+(void)registerDeviceTokenWithData:(NSData*)data block:(CompletionBlock)block;
+(void)logout;
+(void)resetPasswordWithUsername:(NSString*)username block:(CompletionBlock)block;

+(ANUser*)currentUser;

@end
