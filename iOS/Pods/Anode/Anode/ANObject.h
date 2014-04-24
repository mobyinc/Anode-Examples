//
//  ANObject.h
//  Anode
//
//  Created by James Jacoby on 8/9/13.
//  Copyright (c) 2013 Moby, Inc. All rights reserved.
//

#import "ANClient.h"
#import "ANQuery.h"

@class ANFile;

/** ANObject is the primary interface used for inspection and modification of remote objects.
 */

@interface ANObject : ANClient<NSCoding>

/** @name Initialization
 */

/** Initialize a new ANObject with an object type.
 
 The object type represents the singualar, lowercase name of the remote resource. 
 
    For example: 
    A model stored in a products table, and represented by the Product class, would require a type identifier of "product"
 
 The type parameter may not be changed once initialized and serves to scope all network interactions to the associated resource.
 
 When objects are retrieved via an ANQuery, the type parameter is automatically set.
 
 @param type The object type
 @returns An empty ANObject, initialized with the specified type
 */
+(ANObject*)objectWithType:(NSString*)type;

/** Initialize a new object with an object type and objectId
 
 Similar to objectWithType:, this method builds an empty object with the added objectId attribute. 
 
 Use this method to initialize an ANObject you already know the objectId of. The object may then be refreshed by calling reloadWithBlock: or remotely destroyed by calling destroyWithBlock:.
 
 Before being refresh, an ANObject in this state may not be saved.
 
 @param type The object type
 @returns An empty ANObject, initialized with the specified type and objectId
 */
+(ANObject*)objectWithType:(NSString*)type objectId:(NSNumber*)objectId;

/** @name Accessing special attributes
 
 All ANObjects include objectId, createdAt, and updatedAt in the attributes list. These special attributes may be accessed via read-only propertiesof the same name.
 */

/** Returns the objectId

 The objectId represents the primary key field for all resources.
 */
@property (nonatomic, strong, readonly) NSNumber* objectId;
@property (nonatomic, strong, readonly) NSDate* createdAt;
@property (nonatomic, strong, readonly) NSDate* updatedAt;
@property (nonatomic, readonly) BOOL isNew;
@property (nonatomic, assign) BOOL destroyOnSave;

/** @name Inspection and modification of attributes
 
 The attributes of an ANObject usaully have a 1:1 relationship with the attributes of the resource. However, it is up to the remote service to determine which attributes are returned and which it will accept.
 */

/** Sets an object for an attribute with name key
 
 Objects accepted include:
 
 - NSString
 - NSNumber
 - NSDate

 Attempts to modify special attributes are ignored.
 
 @param object The value to set
 @param key The name of the attribute
 */
-(void)setObject:(id)object forKey:(NSString*)key;

/** Clears an attribute
 
 Rather than delete the entry from the internal dictionary, the value is stored as NSNull so it can be passed to the service.

 Passing nil to [setObject: forKey:] has the same effect.
 
 @param key The name of the attribute to clear
 */
-(void)removeObjectForKey:(NSString*)key;


-(id)objectForKey:(NSString*)key;

/** Returns an ANFile object initialized with the value of the specified key
 
 @param key A key containing a valid remote url from which the file should be fetched
 @param version The version of the file to fetch (optional)
 @returns An ANFile initialized with the remote url
 */
-(ANFile*)fileForKey:(NSString*)key version:(NSString*)version;

-(ANFile*)fileForKey:(NSString *)key;

/** @name Commiting and refreshing changes 
 */

-(void)save;
-(void)saveWithBlock:(CompletionBlock)block;
-(void)reload;
-(void)reloadWithBlock:(CompletionBlock)block;
-(void)destroy;
-(void)destroyWithBlock:(CompletionBlock)block;

/** Marks the object as dirty to force a save which may be usful if modifying nested objects
 */
-(void)touch;

/** Makes copy of the object through NSCoding. The resulting object will be memory-independent of the original, but will idential field values.\
 
 @returns The cloned copy
 */
-(ANObject*)clone;

/** @name Calling custom remote methods
 */

/** Invokes a remote method passing the current objectId and any supplied parameters
 
 The objectId and methodName will be used to build the request url.
 
 The response, if any, is returned as an NSDictionary.
 
 @param methodName The name of the remote method
 @param parameters Optional key/value parameters
 @param block A block object to executed with the results of the method call
 */
-(void)callMethod:(NSString*)methodName parameters:(NSDictionary*)parameters block:(CompletionBlock)block;

/** @name Obtaining a relationship query
 */

/** Returns an ANQuery initalized with a releationship that exists on the object instance.
 
 This is a shortcut for calling [ANQuery queryWithType:belongingToType:throughRelationshipNamed:withObjectId:]
 
 An ANQuery initialized in this way is appropriate for returning objects from a has-many relationship. The resuting query will return objects of the object type associated with the relationship, which should match the type parameter. Additionally, the ANQuery is scoped to the objectId of the object instance.
 
    For example:
    Assume a company which has many employees. The follow code will fetch all employeees of a specific company.
 
    ANObject* company = [ANObject objectWithType:@"company" objectId:@(1)];
    ANQuery* employees = [company queryForRelationshipNamed:@"employees" type:@"user"];
    [employees findAllObjectsWithBlock:^(NSArray *objects, NSError *error) {
        NSLog(@"There are %@ employees.", @(objects.count)];
    }];
 
 @param relationshipName The name of the has-many relationship
 @param type The object type to be returned from the relationship
 @returns An ANQuery initialized to return objects through the specified relationshipName
 @see [ANQuery queryWithType:belongingToType:throughRelationshipNamed:withObjectId:]
 */
-(ANQuery*)queryForRelationshipNamed:(NSString*)relationshipName type:(NSString*)type;

@end
