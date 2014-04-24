//
//  NSString+TypeDetection.h
//  Anode
//
//  Created by James Jacoby on 8/20/13.
//  Copyright (c) 2013 Moby, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (TypeDetection)

-(BOOL)isDate;
-(BOOL)isFileUrl;
-(BOOL)isNil;

@end
