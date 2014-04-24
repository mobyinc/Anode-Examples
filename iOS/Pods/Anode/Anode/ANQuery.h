//
//  ANQuery.h
//  Anode
//
//  Created by James Jacoby on 8/9/13.
//  Copyright (c) 2013 Moby, Inc. All rights reserved.
//

#import "ANClient.h"

/** Use instances of ANQuery to fetch objects from the remote service.
 */

typedef enum {
    kANOrderDirectionDescending,
    kANOrderDirectionAscending
} ANOrderDirection;

typedef enum {
    kANCachePolicyIgnoreCache,
    kANCachePolicyCacheElseNetwork,
    kANCachePolicyNetworkElseCache,
    
} ANCachePolicy;

@interface ANQuery : ANClient

@property (nonatomic, strong) NSNumber* limit;
@property (nonatomic, strong) NSNumber* skip;
@property (nonatomic, strong) NSString* orderBy;
@property (nonatomic, assign) ANOrderDirection orderDirection;
@property (nonatomic, assign) ANCachePolicy cachePolicy;
@property (nonatomic, readonly) BOOL isRelationship;

/** @name Initialization
 */

/** Returns an ANQuery initialized for the specified resource
 */
+(ANQuery*)queryWithType:(NSString*)type;

/** Returns an ANQuery intialized for a relationship query.
 */
+(ANQuery*)queryWithType:(NSString*)type belongingToType:(NSString*)belongsToType throughRelationshipNamed:(NSString*)relationshipName withObjectId:(NSNumber*)objectId;

/** @name Finding objects
 */

-(void)findAllObjectsWithBlock:(ObjectsResultBlock)block;
-(void)findObjectsWithBlock:(ObjectsResultBlock)block;
-(void)findObjectWithId:(NSNumber*)objectId block:(ObjectResultBlock)block;

/** Find objects using a collection of objectIds
 
 This is a shortcut for executing a query using an "IN" predicate on the "id" field.
 
 For example:
     ANQuery* products = [ANQuery queryWithType:@"product"];
     [products findObjectsWithIds:@[@(7), @(8), @(9)] block:^(NSArray *objects, NSError *error) {
        NSLog(@"Found %d objects", objects.count);
     }];
 
 @param objectIds A collection of objectIds which specify the objects to be fetched
 @param block A block object to executed with the results of the query
 */
-(void)findObjectsWithIds:(NSArray*)objectIds block:(ObjectsResultBlock)block;
-(void)findObjectsWithPredicate:(NSPredicate*)predicate block:(ObjectsResultBlock)block;
-(void)findFirstObjectWithPredicate:(NSPredicate*)predicate block:(ObjectResultBlock)block;
-(void)findObjectsWithMethod:(NSString*)methodName parameters:(NSDictionary*)parameters block:(ObjectsResultBlock)block;
-(void)countObjectsWithPredicate:(NSPredicate*)predicate block:(ScalarResultBlock)block;
-(void)fetchScalarWithMethod:(NSString*)methodName parameters:(NSDictionary*)parameters block:(ScalarResultBlock)block;

@end
