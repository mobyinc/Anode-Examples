//
//  BlockTypes.h
//  Anode
//
//  Created by James Jacoby on 8/10/13.
//  Copyright (c) 2013 Moby, Inc. All rights reserved.
//

@class ANObject;
@class ANUser;
@class ANFile;

typedef void (^CompletionBlock) (id object, NSError* error);
typedef void (^ObjectResultBlock) (ANObject* object, NSError* error);
typedef void (^FileResultBlock) (ANFile* file, NSError* error);
typedef void (^ObjectsResultBlock) (NSArray* objects, NSError* error);
typedef void (^ScalarResultBlock) (id value, NSError* error);
typedef void (^LoginBlock) (ANUser* user, NSError* error);
