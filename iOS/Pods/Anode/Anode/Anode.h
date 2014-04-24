//
//  Anode.h
//  Anode
//
//  Created by FourtyTwo on 8/9/13.
//  Copyright (c) 2013 Moby, Inc. All rights reserved.
//

@class ANObject;
@class ANUser;

#import <Anode/ANObject.h>
#import <Anode/ANQuery.h>
#import <Anode/ANUser.h>
#import <Anode/ANCache.h>
#import <Anode/ANFile.h>
#import <Anode/BlockTypes.h>

FOUNDATION_EXPORT NSString *const ANErrorKey;
FOUNDATION_EXPORT NSString *const ANErrorOriginalError;

/** The Anode framwork aims to capture the primary patterns used when connecting apps to remote services.
 
 TODO: Installation instructions
 
 Include this file in your project's prefix header for easy access to all Anode classes anywhere in your code.
 */

@interface Anode : NSObject

/** @name Initialization
 */

/** Initialize the framework with base url and client token.
 
 In addition to setting parameters, this method handles automatically re-establishing the user session from the cache, if any exists.
 
 This method should be called as early as possible in the App Delegate.
 
 @param url A string representing the root of the remote service
 @param token The client token is shared between all clients and is used for anonymous access
 */
+(void)initializeWithBaseUrl:(NSString*)url clientToken:(NSString*)token;

/** Initialize the framework with base url, client token and appId.
 
 In addition to setting parameters, this method handles automatically re-establishing the user session from the cache, if any exists.
 
 This method should be called as early as possible in the App Delegate.
 
 @param url A string representing the root of the remote service
 @param token The client token is shared between all clients and is used for anonymous access
 */
+(void)initializeWithBaseUrl:(NSString*)url clientToken:(NSString*)token appId:(NSNumber*)appId;

/** @name Getting properties
 */

/** Returns the current base URL
 @return The current base URL
 */
+(NSURL*)baseUrl;

/** Returns the current token used for requests
 
 If a user session exists, the user-specific token is returned. Otherwise, the client token is returned.
 
 @return The current token
 */
+(NSString*)token;

/** Returns the current appId used for requests
 
 @return The current appId (or nil)
 */
+(NSString*)appId;

/** @name Controlling cache versioning
 */

/** Sets the current version of the cache
 
 If the current cache version does not match the existing value, the cache is emptied to avoid presenting outdated cache hits.
 
 @param cacheVersion The current cache version
 */
+(void)setCacheVersion:(NSNumber*)cacheVersion;

@end

