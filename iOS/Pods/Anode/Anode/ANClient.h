//
//  ANClient.h
//  Anode
//
//  Created by James Jacoby on 8/18/13.
//  Copyright (c) 2013 Moby, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BlockTypes.h"

/** ANClient is the base class for all objects that communicate with the remote service.
 */

typedef enum {
    kANStatusCodeOk = 200,
    kANStatusCodeBadRequest = 400,
    kANStatusCodeUnauthorized = 401,
    kANStatusCodeServerError = 500,
    kANStatusCodeServiceUnavailable = 503
} ANStatusCode;

@interface ANClient : NSObject

/** @name Retreiving the object type
 */

/** Returns the object type
 
 All subclasses of ANClient are initialized with an object type which scopes the interactions with the service to a particular resource. This value cannot be changed once an object is initialized.
 
 @return The object type
 */
@property (nonatomic, strong, readonly) NSString* type;

@end
