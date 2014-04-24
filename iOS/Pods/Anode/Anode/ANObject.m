//
//  ANObject.m
//  Anode
//
//  Created by James Jacoby on 8/9/13.
//  Copyright (c) 2013 Moby, Inc. All rights reserved.
//

#import "ANObject.h"
#import "ANClient_Private.h"
#import "ANObject_Private.h"
#import "ANFile_Private.h"
#import "Anode.h"
#import "ANJSONRequestOperation.h"
#import "NSError+Helpers.h"
#import "NSString+TypeDetection.h"
#import "NSString+ActiveSupportInflector.h"

@implementation ANObject

+(ANObject*)objectWithType:(NSString*)type
{
    ANObject* object = [[self alloc] init];
    object.type = type.lowercaseString;
    
    return object;
}

+(ANObject*)objectWithType:(NSString*)type objectId:(NSNumber*)objectId
{
    ANObject* object = [[self alloc] init];
    object.type = type.lowercaseString;
    object.objectId = objectId;
    object.emptyObject = YES; // id was manually specified and therefore cannot be saved unless reloaded first
    
    return object;
}

+(ANObject*)objectWithJSON:(NSDictionary *)node error:(NSError**)error
{
    NSString* type = node[@"__type"];
    
    if (type) {
        ANObject* object = [self objectWithType:type];
        [ANObject applyAttributesWithDictionary:node toObject:object error:error];
        return object;
    } else {
        *error = [NSError errorWithDescription:@"Missing type attribute in server response."];
        return nil;
    }
}

-(id)init
{
    self = [super init];
    
    if (self) {
        self.dirty = NO;
        self.emptyObject = NO;
        self.destroyOnSave = NO;
        self.attributes = [NSMutableDictionary dictionaryWithCapacity:10];
        self.files = [NSMutableDictionary dictionary];
    }
    
    return self;
}

#pragma mark - NSCoding

- (id)initWithCoder:(NSCoder *)decoder
{
    if (self = [super init]) {
        self.dirty = NO;
        self.emptyObject = NO;
        self.attributes = [[decoder decodeObjectForKey:@"attributes"] mutableCopy];
        self.type = self.attributes[@"__type"];
    }
    return self;
}

-(void)encodeWithCoder:(NSCoder *)encoder
{
    [encoder encodeObject:self.attributes forKey:@"attributes"];
}

#pragma mark - Public

-(void)setObject:(id)object forKey:(NSString*)key
{
    if ([key rangeOfString:@"__"].location != NSNotFound) return; // disallow access to protected fields
    
    id existingValue = _attributes[key];
    
    if (![existingValue isEqual:object]) {
        _dirty = YES;
        
        if (object) {
            self.attributes[key] = object;
        } else {
            [self removeObjectForKey:key];
        }
    }
}

-(void)removeObjectForKey:(NSString*)key
{
    [self setObject:[NSNull null] forKey:key];
}

-(id)objectForKey:(NSString*)key
{
    if ([key rangeOfString:@"__"].location != NSNotFound) return nil; // disallow access to protected fields
    
    id object = self.attributes[key];

    return object;
}

-(ANFile *)fileForKey:(NSString *)key
{
    return [self fileForKey:key version:nil];
}

-(ANFile*)fileForKey:(NSString *)key version:(NSString *)version
{
    id object = [self objectForKey:key];
    
    if (version) object = object[version];    
    
    if (!object) {
        NSLog(@"Warning: nil object for file");
        return nil;
    }
    
    if ([object isKindOfClass:[NSString class]]) {
        ANFile* file = [ANFile fileWithUrl:object];
        return file;
    } else if ([object isKindOfClass:[ANFile class]]) {
        return object;
    } else {
        NSLog(@"Warning: invalid object type for file.");
        return nil;
    }
}

-(void)save
{
    [self saveWithBlock:nil];
}

-(void)saveWithBlock:(CompletionBlock)block
{
    if (self.destroyOnSave) {
        [self destroyWithBlock:block];
        return;
    }
    
    if (!_dirty) {
        if (block) block(self, nil);
        return;
    } else if (self.emptyObject) {
        if (block) block(self, [NSError errorWithDescription:@"Cannot save an empty object. Load by id or reload first."]);
        return;
    }
    
    NSString* verb = self.objectId ? @"PUT" : @"POST";
    NSData* httpBody = [self attributesToJSON];
    
    [self performRequestWithVerb:verb httpBody:httpBody block:block];    
}

-(void)reload
{
    [self reloadWithBlock:nil];
}

-(void)reloadWithBlock:(CompletionBlock)block
{
    if (!self.objectId) {
        if (block) block(self, [NSError errorWithDescription:@"Cannot reload object with no object id."]);
        return;
    }

    [self performRequestWithVerb:@"GET" httpBody:nil block:block];
}

-(void)destroy
{
    [self destroyWithBlock:nil];
}

-(void)destroyWithBlock:(CompletionBlock)block
{
    if (!self.objectId) {
        if (block) block(self, [NSError errorWithDescription:@"Cannot destroy object with no object id."]);
        return;
    }
    
    [self performRequestWithVerb:@"DELETE" httpBody:nil block:^(id object, NSError *error) {
        if (!error) {
            [self.attributes removeObjectForKey:@"id"];
            self.destroyOnSave = NO;
        }
        
        if (block) block(self, error);
    }];
}

-(void)touch
{
    self.dirty = YES;
}

-(ANObject *)clone
{
    NSData* data = [NSKeyedArchiver archivedDataWithRootObject:self];
    ANObject* clonedCopy = [NSKeyedUnarchiver unarchiveObjectWithData:data];
    
    return clonedCopy;
}

-(void)callMethod:(NSString *)methodName parameters:(NSDictionary *)parameters block:(CompletionBlock)block
{
    NSMutableURLRequest* request = [self requestForVerb:@"POST" objectId:self.objectId action:methodName parameters:parameters];
    
    ANJSONRequestOperation *operation = [ANJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {        
        if (block) block(JSON, nil);
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
        if (block) block(nil, error);
    }];
    
    [operation start];
}

-(ANQuery *)queryForRelationshipNamed:(NSString *)relationshipName type:(NSString *)type
{
    return [ANQuery queryWithType:type belongingToType:self.type throughRelationshipNamed:relationshipName withObjectId:self.objectId];
}

#pragma mark - Special Attributes

-(NSNumber*)objectId
{
    return [self objectForKey:@"id"];
}

-(void)setObjectId:(NSNumber*)objectId
{
    [self setObject:objectId forKey:@"id"];
}

-(NSDate*)createdAt
{
    return [self objectForKey:@"created_at"];
}

-(NSDate*)updatedAt
{
    return [self objectForKey:@"updated_at"];
}

-(BOOL)isNew
{
    return self.objectId == nil;
}

-(void)setDestroyOnSave:(BOOL)destroyOnSave
{
    _destroyOnSave = destroyOnSave;
    
    self.attributes[@"_destroy"] = @(_destroyOnSave);
}

#pragma mark - Private

-(void)performRequestWithVerb:(NSString*)verb httpBody:(NSData*)httpBody block:(CompletionBlock)block
{
    NSMutableURLRequest* request = nil;
    
    if (self.files.count == 0) {
        request = [self requestForVerb:verb objectId:self.objectId];
        request.HTTPBody = httpBody;
    } else {
        request = [self multipartRequestForVerb:verb objectId:self.objectId action:nil parameters:nil formBodyData:httpBody files:self.files];
//        request.HTTPBody = httpBody;
    }
    
    ANJSONRequestOperation *operation = [ANJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
        NSError* error = nil;
        
        if (![request.HTTPMethod isEqualToString:@"DELETE"]) {
            [self applyAttributesWithJSONResponse:JSON error:&error];
        }
        
        if (block) block(self, error);
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
        if (block) block(nil, error);
    }];
    
    [operation start];
}

-(void)applyAttributesWithJSONResponse:(id)rootNode error:(NSError**)error
{
    if (rootNode && [rootNode isKindOfClass:[NSDictionary class]] && rootNode[@"id"]) {        
        [ANObject applyAttributesWithDictionary:rootNode toObject:self error:error];
    } else if (error) {
        *error = [NSError errorWithDescription:@"Missing object root node in server response."];
    }
}

+(void)applyAttributesWithDictionary:(NSDictionary*)node toObject:(ANObject*)object error:(NSError**)error
{
    object.attributes = [NSMutableDictionary dictionary];
    object.dirty = NO;
    object.emptyObject = NO;
    
    for (id key in node.allKeys) {
        id value = node[key];
        
        // handle special types
        // others pass straight through
        if ([value isKindOfClass:[NSString class]]) {
            if ([value isDate]) {
                value = [object.dateFormatter dateFromString:value];
            } else if ([value isNil]) {
                value = nil;
            }
        } else if ([value isKindOfClass:[NSArray class]]) {
            NSMutableArray* newArray = [NSMutableArray arrayWithCapacity:[value count]];
            for (NSDictionary* childNode in value) {
                ANObject* newObject = [ANObject objectWithJSON:childNode error:error];
                
                if (!*error && newObject) {
                    [newArray addObject:newObject];
                } else {
                    break;
                }
            }
            
            value = newArray;
        } else if ([value isKindOfClass:[NSDictionary class]]) {
            NSDictionary* dictionary = value;
            if ([dictionary objectForKey:@"__type"]) {
                value = [ANObject objectWithJSON:dictionary error:error];
            }
        } else if ([value isKindOfClass:[NSNull class]]) {
            value = nil;
        }
        
        if (*error) return;
        
        if (value) {
            object.attributes[key] = value;
        } else {
            [object.attributes removeObjectForKey:key];
        }
            
    }
}

-(NSData*)attributesToJSON
{
    NSError* serializationError = nil;
    NSDictionary* attributesToSend = [self dictionaryRepresentation];
    NSDictionary* encapsulatedAttributes = @{self.type : attributesToSend};
    
    NSData* JSON = [NSJSONSerialization dataWithJSONObject:encapsulatedAttributes options:0 error:&serializationError];
    
    if (serializationError) {
        return nil;
    } else {
        return JSON;
    }
}

-(NSDictionary*)dictionaryRepresentation
{
    NSMutableDictionary* attributesToSend = [NSMutableDictionary dictionaryWithDictionary:self.attributes];
    
    // strip unwanted attributes
    [attributesToSend removeObjectForKey:@"__type"];
//    [attributesToSend removeObjectForKey:@"id"];
    [attributesToSend removeObjectForKey:@"created_at"];
    [attributesToSend removeObjectForKey:@"updated_at"];
    
    self.files = [NSMutableDictionary dictionary];
    
    // handle special data types
    for (id key in attributesToSend.allKeys) {
        id value = attributesToSend[key];
        
        if ([value isKindOfClass:[NSDate class]]) {
            NSString* dateString = [self.dateFormatter stringFromDate:value];
            [attributesToSend setObject:dateString forKey:key];
        } else if ([value isKindOfClass:[ANFile class]]) {
            [attributesToSend removeObjectForKey:key];
            self.files[key] = value; // will be sent as muti-part form data separately
        } else if ([value isKindOfClass:[NSArray class]]) {
            // recursively convert nested objects into a format Rails understands
            NSArray* array = value;            
            NSMutableDictionary* dictionary = [NSMutableDictionary dictionary];
            
            if (array.count > 0 && [array[0] isKindOfClass:[ANObject class]]) {    
                for (int i=0; i<array.count; i++) {
                    ANObject* object = array[i];
                    NSString* key = object.isNew ? [NSString stringWithFormat:@"%d", i+100000000] : [NSString stringWithFormat:@"%d", i];
                    [dictionary setObject:[object dictionaryRepresentation] forKey:key];
                }
            }
            

            [attributesToSend setObject:dictionary forKey:[key stringByAppendingString:@"_attributes"]];
            [attributesToSend removeObjectForKey:key];
        } else if ([value isKindOfClass:[ANObject class]]) {
            // this implies a belongs_to relationship, substitute for just the id if it exists
            [attributesToSend removeObjectForKey:key];
            
            ANObject* object = value;
            
            if (!object.isNew) {
                [attributesToSend setObject:object.objectId forKey:[key stringByAppendingString:@"_id"]];
            }
        }
    }

    return attributesToSend;
}

@end
