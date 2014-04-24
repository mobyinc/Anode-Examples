//
//  ANQuery.m
//  Anode
//
//  Created by James Jacoby on 8/9/13.
//  Copyright (c) 2013 Moby, Inc. All rights reserved.
//

#import "ANQuery.h"
#import "ANCache.h"
#import "ANClient_Private.h"
#import "ANObject_Private.h"
#import "ANJSONRequestOperation.h"
#import "NSString+ActiveSupportInflector.h"
#import "NSError+Helpers.h"
#import "NSData+MD5.h"

@interface ANQuery ()

@property (nonatomic, strong) NSString* type;
@property (nonatomic, strong) NSString* belongsToType;
@property (nonatomic, strong) NSString* belongsToRelationshipName;
@property (nonatomic, strong) NSNumber* belongsToObjectId;

@end

@implementation ANQuery

+(ANQuery*)queryWithType:(NSString *)type
{
    ANQuery* query = [[ANQuery alloc] init];
    query.type = type.lowercaseString;
    query.skip = [NSNumber numberWithInt:0];
    query.limit = [NSNumber numberWithInt:100];
    query.orderDirection = kANOrderDirectionAscending;
    query.cachePolicy = kANCachePolicyNetworkElseCache;
    
    return query;
}

+(ANQuery *)queryWithType:(NSString *)type belongingToType:(NSString *)belongsToType throughRelationshipNamed:(NSString *)relationshipName withObjectId:(NSNumber *)objectId
{
    ANQuery* query = [ANQuery queryWithType:type];
    query.belongsToType = belongsToType;
    query.belongsToRelationshipName = relationshipName;
    query.belongsToObjectId = objectId;
    query.orderDirection = kANOrderDirectionAscending;
    query.cachePolicy = kANCachePolicyNetworkElseCache;
    
    return query;
}

-(BOOL)isRelationship
{
    return self.belongsToType != nil;
}

-(void)findAllObjectsWithBlock:(ObjectsResultBlock)block
{
    [self findObjectsWithPredicate:nil skip:nil limit:nil block:block];
}

-(void)findObjectsWithBlock:(ObjectsResultBlock)block
{
    [self findObjectsWithPredicate:nil block:block];
}

-(void)findObjectWithId:(NSNumber *)objectId block:(ObjectResultBlock)block
{
    if (self.isRelationship) {
        NSLog(@"%@: Relationship ignored for findObjectWithId: %@", self.type, objectId);
    }
    
    NSMutableURLRequest* request = [self requestForVerb:@"GET" objectId:objectId action:nil parameters:nil];
    
    [self fetchObjectsWithRequest:request block:^(NSArray *objects, NSError *error) {
        if (objects && objects.count == 1) {
            block(objects[0], nil);
        } else {
            block(nil, error);
        }
    }];
}

-(void)findObjectsWithIds:(NSArray*)objectIds block:(ObjectsResultBlock)block
{
    [self findObjectsWithPredicate:[NSPredicate predicateWithFormat:@"id IN %@", objectIds] block:block];
}

-(void)findObjectsWithPredicate:(NSPredicate *)predicate block:(ObjectsResultBlock)block
{
    [self findObjectsWithPredicate:predicate skip:self.skip limit:self.limit block:block];
}

-(void)findFirstObjectWithPredicate:(NSPredicate *)predicate block:(ObjectResultBlock)block
{
    [self findObjectsWithPredicate:predicate skip:self.skip limit:@(1) block:^(NSArray *objects, NSError *error) {
        if (objects && objects.count >= 1) {
            block(objects[0], nil);
        } else {
            block(nil, error);
        }
    }];
}

-(void)findObjectsWithMethod:(NSString*)methodName parameters:(NSDictionary*)parameters block:(ObjectsResultBlock)block
{
    if (self.isRelationship) {
        NSLog(@"%@: Relationship ignored for findObjectsWithMethod: %@", self.type, methodName);
    }
    
    NSMutableURLRequest* request = [self requestForVerb:@"GET" objectId:nil action:methodName parameters:parameters];
    
    [self fetchObjectsWithRequest:request block:block];
}

-(void)countObjectsWithPredicate:(NSPredicate*)predicate block:(ScalarResultBlock)block
{
    NSMutableURLRequest* request = [self requestForVerb:@"POST" action:@"query"];
    request.HTTPBody = [self jsonWithPredicate:predicate skip:nil limit:nil orderBy:nil orderDirection:self.orderDirection countOnly:YES];
    
    [self fetchValuesWithRequest:request block:^(id object, NSError *error) {
        if (object && !error && object[@"count"]) {
            id value = object[@"count"];
            block(value, nil);
        } else {
            block(nil, error);
        }
    }];
}

-(void)fetchScalarWithMethod:(NSString *)methodName parameters:(NSDictionary *)parameters block:(ScalarResultBlock)block
{
    if (self.isRelationship) {
        NSLog(@"%@: Relationship ignored for fetchScalarWithMethod: %@", self.type, methodName);
    }
    
    NSMutableURLRequest* request = [self requestForVerb:@"GET" objectId:nil action:methodName parameters:parameters];
    
    [self fetchValuesWithRequest:request block:^(id object, NSError *error) {
        if (object && !error && object[@"value"]) {
            id value = object[@"value"];
            block(value, nil);
        } else {
            block(nil, error);
        }
    }];
}

#pragma mark - Private

-(void)findObjectsWithPredicate:(NSPredicate *)predicate skip:(NSNumber*)skip limit:(NSNumber*)limit block:(ObjectsResultBlock)block
{
    NSMutableURLRequest* request = nil;
    
    if (predicate || limit || self.isRelationship || self.orderBy) {
        request = [self requestForVerb:@"POST" action:@"query"];        
        request.HTTPBody = [self jsonWithPredicate:predicate skip:skip limit:limit orderBy:self.orderBy orderDirection:self.orderDirection countOnly:NO];
    } else {
        request = [self requestForVerb:@"GET"];
    }
    
    [self fetchObjectsWithRequest:request block:block];
}

-(void)fetchObjectsWithRequest:(NSURLRequest*)request block:(ObjectsResultBlock)block
{
    if (self.cachePolicy == kANCachePolicyIgnoreCache) {
        [self fetchObjectsFromNetworkWithRequest:request block:block];
    } else if (self.cachePolicy == kANCachePolicyNetworkElseCache) {
        [self fetchObjectsFromNetworkWithRequest:request block:^(NSArray *objects, NSError *error) {
            if (error) {
                if (error.code == kANStatusCodeServiceUnavailable) {
                    id objects = [self fetchObjectsFromCacheWithRequest:request];
                    
                    if (objects && block) {
                        block(objects, nil);
                    } else if (block) {
                        block(nil, error);
                    }
                } else if (block) {
                    block(nil, error);
                }
            } else if (block) {
                block(objects, nil);
            }
        }];
    } else if (self.cachePolicy == kANCachePolicyCacheElseNetwork) {
        id objects = [self fetchObjectsFromCacheWithRequest:request];
        
        if (objects && block) {
            block(objects, nil);
        } else {
            [self fetchObjectsFromNetworkWithRequest:request block:block];
        }
    }
}

-(void)fetchValuesWithRequest:(NSURLRequest*)request block:(CompletionBlock)block
{
    if (self.cachePolicy == kANCachePolicyIgnoreCache) {
        [self fetchValuesFromNetworkWithRequest:request block:block];
    } else if (self.cachePolicy == kANCachePolicyNetworkElseCache) {
        [self fetchValuesFromNetworkWithRequest:request block:^(id object, NSError *error) {
            if (error) {
                if (error.code == kANStatusCodeServiceUnavailable) {
                    id object = [self fetchObjectsFromCacheWithRequest:request];
                    
                    if (object && block) {
                        block(object, nil);
                    } else if (block) {
                        block(nil, error);
                    }
                } else if (block) {
                    block(nil, error);
                }
            } else if (block) {
                block(object, nil);
            }
        }];
    } else if (self.cachePolicy == kANCachePolicyCacheElseNetwork) {
        id object = [self fetchObjectsFromCacheWithRequest:request];
        
        if (object && block) {
            block(object, nil);
        } else {
            [self fetchValuesFromNetworkWithRequest:request block:block];
        }
    }
}

-(void)fetchObjectsFromNetworkWithRequest:(NSURLRequest*)request block:(ObjectsResultBlock)block
{
    ANJSONRequestOperation *operation = [ANJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
        NSError* error = nil;
        
        NSMutableArray* objects = [NSMutableArray array];
        
        if ([JSON isKindOfClass:[NSArray class]]) {
            for (id node in JSON) {
                ANObject* object = [ANObject objectWithJSON:node error:&error];
                
                if (!error && object) {
                    [objects addObject:object];
                } else {
                    break;
                }
            }
        } else if ([JSON isKindOfClass:[NSDictionary class]]) {
            ANObject* object = [ANObject objectWithJSON:JSON error:&error];
            
            if (!error && object) {
                [objects addObject:object];
            }
        } else {
            error = [NSError errorWithDescription:@"Unexpected root node in server response."];
        }
        
        if (block) block(objects, error);
        
        if (!error && self.cachePolicy != kANCachePolicyIgnoreCache) {
            [self commitObjectsToCacheWithRequest:request objects:objects];
        }
        
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
        if (block) block(nil, error);
    }];
    
    [operation start];
}

-(void)fetchValuesFromNetworkWithRequest:(NSURLRequest*)request block:(CompletionBlock)block
{
    ANJSONRequestOperation *operation = [ANJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
        NSError* error = nil;
        
        if (![JSON isKindOfClass:[NSDictionary class]]) {
            error = [NSError errorWithDescription:@"Unexpected root node in server response. Expected dictionary."];
        }
        
        if (block) block(JSON, error);
        
        if (!error && self.cachePolicy != kANCachePolicyIgnoreCache) {
            [self commitObjectsToCacheWithRequest:request objects:JSON];
        }        
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
        if (block) block(nil, error);
    }];
    
    [operation start];
}

-(id)fetchObjectsFromCacheWithRequest:(NSURLRequest*)request
{
    NSString* cacheKey = [self cacheKeyForRequest:request];
    return [[ANCache sharedInstance] objectForKey:cacheKey];
}

-(BOOL)commitObjectsToCacheWithRequest:(NSURLRequest*)request objects:(id<NSCoding>)objects
{
    NSString* cacheKey = [self cacheKeyForRequest:request];
    return [[ANCache sharedInstance] setObject:objects forKey:cacheKey];
}

-(NSData*)jsonWithPredicate:(NSPredicate*)predicate skip:(NSNumber*)skip limit:(NSNumber*)limit orderBy:(NSString*)orderBy orderDirection:(ANOrderDirection)orderDirection countOnly:(BOOL)countOnly
{
    NSError* serializationError = nil;
    NSMutableDictionary* components = [NSMutableDictionary dictionary];
    NSData* JSON = nil;
    
    if (limit) components[@"limit"] = limit;
    if (skip) components[@"skip"] = skip;
    
    if (orderBy) {
        components[@"order_by"] = orderBy;
        components[@"order_direction"] = orderDirection == kANOrderDirectionDescending ? @"DESC" : @"ASC";
    }
    
    if ([predicate isKindOfClass:[NSComparisonPredicate class]]) {
        NSComparisonPredicate* comparison = (NSComparisonPredicate*)predicate;
        NSString* operator = [self stringWithOperatorType:comparison.predicateOperatorType];
        NSString* left = [NSString stringWithFormat:@"%@", comparison.leftExpression];
        NSString* right = [NSString stringWithFormat:@"%@", comparison.rightExpression];
        
        components[@"predicate"] = @{@"left" : left,
                                     @"operator" : operator,
                                     @"right" : right};
    }
    
    if (self.belongsToType && self.belongsToRelationshipName && self.belongsToObjectId) {
        components[@"relationship"] = @{@"type" : self.belongsToType,
                                        @"name" : self.belongsToRelationshipName,
                                        @"object_id" : self.belongsToObjectId};
    }
    
    if (countOnly) {
        components[@"count_only"] = @(YES);
    }
    
    JSON = [NSJSONSerialization dataWithJSONObject:components options:0 error:&serializationError];
    
    if (serializationError) {
        return nil;
    } else {
        return JSON;
    }
}

-(NSString*)stringWithOperatorType:(NSPredicateOperatorType)type
{
    switch (type) {
        case NSEqualToPredicateOperatorType:
            return @"=";
        case NSGreaterThanPredicateOperatorType:
            return @">";
        case NSGreaterThanOrEqualToPredicateOperatorType:
            return @">=";
        case NSLessThanPredicateOperatorType:
            return @"<";
        case NSLessThanOrEqualToPredicateOperatorType:
            return @"<=";
        case NSInPredicateOperatorType:
            return @"in";
        default:
            @throw @"Unsupported predicate operator type";
            break;
    }
}

-(NSString*)cacheKeyForRequest:(NSURLRequest*)request;
{
    NSData* codedData = [NSKeyedArchiver archivedDataWithRootObject:request];
    return [codedData MD5];
}

@end
