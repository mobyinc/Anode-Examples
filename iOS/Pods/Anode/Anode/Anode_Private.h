//
//  Anode_Private.h
//  Anode
//
//  Created by FourtyTwo on 8/21/13.
//  Copyright (c) 2013 Moby, Inc. All rights reserved.
//

#import <Anode/Anode.h>

@interface Anode ()

@property (nonatomic, readonly) NSString* token;
@property (nonatomic, retain) NSString* clientToken;
@property (nonatomic, retain) NSNumber* appId;
@property (nonatomic, retain) NSString* userToken;
@property (nonatomic, retain) NSString* baseUrl;

+(Anode*)sharedInstance;

@end
