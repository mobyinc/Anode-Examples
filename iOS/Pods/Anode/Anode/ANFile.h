//
//  ANFile.h
//  Anode
//
//  Created by James Jacoby on 9/11/13.
//  Copyright (c) 2013 Moby, Inc. All rights reserved.
//

#import <Anode/Anode.h>
#import <UIKit/UIKit.h>

/** ANObject is wrapper for dealing with file downloads and uploads.
 */

@interface ANFile : ANClient

@property (nonatomic, strong) NSString* url;
@property (nonatomic, strong) NSData* data;
@property (nonatomic, strong) NSString* fileName;
@property (nonatomic, readonly) BOOL loaded;

/** @name Initialization
 */

+(ANFile*)fileWithName:(NSString*)fileName data:(NSData*)data;
+(ANFile*)fileWithUrl:(NSString*)url;

-(void)fetchWithBlock:(FileResultBlock)block;

-(UIImage*)imageRepresentation;

@end
