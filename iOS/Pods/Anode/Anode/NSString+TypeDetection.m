//
//  NSString+TypeDetection.m
//  Anode
//
//  Created by James Jacoby on 8/20/13.
//  Copyright (c) 2013 Moby, Inc. All rights reserved.
//

#import "NSString+TypeDetection.h"

@implementation NSString (TypeDetection)

-(BOOL)isDate
{
    NSString* dateTimeRegex = @"\\d{4}-\\d{2}-\\d{2}T\\d{2}:\\d{2}:\\d{2}[+-]\\d{4}";
    NSPredicate* pre = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", dateTimeRegex];
    return [pre evaluateWithObject:self];
}

-(BOOL)isFileUrl
{
    NSURL* url = [NSURL URLWithString:self];
    if (url == nil) {
        return NO;
    } else {
        return [[[url absoluteURL] path] pathExtension].length > 0;
    }
}

-(BOOL)isNil
{
    return [self isEqualToString:@"<null>"];
}

@end
