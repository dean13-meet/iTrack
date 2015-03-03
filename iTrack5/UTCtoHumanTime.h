//
//  UTCtoHumanTime.h
//  Resturant App - User
//
//  Created by Dean Leitersdorf on 1/27/15.
//  Copyright (c) 2015 Dean Leitersdorf. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface UTCtoHumanTime : NSObject
+ (NSString*) msecToLocalTime:(NSTimeInterval)msec;
+ (NSString*) secToLocalTime:(NSTimeInterval)sec;
+ (NSInteger) msecToDayNumber:(NSTimeInterval)msec;
+ (BOOL) isLeap:(NSInteger)year;
@end
