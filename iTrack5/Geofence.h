//
//  Geofence.h
//  iTrack5
//
//  Created by Dean Leitersdorf on 4/11/15.
//  Copyright (c) 2015 Dean Leitersdorf. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface Geofence : NSManagedObject

@property (nonatomic, retain) NSString * address;
@property (nonatomic, retain) NSString * arrivalMessage;
@property (nonatomic, retain) NSData * arrivalsSent;
@property (nonatomic, retain) NSString * identifier;
@property (nonatomic, retain) NSNumber * lat;
@property (nonatomic, retain) NSString * leaveMessage;
@property (nonatomic, retain) NSData * leavesSent;
@property (nonatomic, retain) NSNumber * longtitude;
@property (nonatomic, retain) NSNumber * onArrival;
@property (nonatomic, retain) NSNumber * onLeave;
@property (nonatomic, retain) NSString * owner;
@property (nonatomic, retain) NSNumber * radius;
@property (nonatomic, retain) NSData * recipients;
@property (nonatomic, retain) NSNumber * recur;
@property (nonatomic, retain) NSString * requester;
@property (nonatomic, retain) NSNumber * setting;
@property (nonatomic, retain) NSString * requestApproved;

@end
