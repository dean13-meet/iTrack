//
//  Geofence.h
//  iTrack5
//
//  Created by Dean Leitersdorf on 3/5/15.
//  Copyright (c) 2015 Dean Leitersdorf. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface Geofence : NSManagedObject

@property (nonatomic, retain) NSString * address;
@property (nonatomic, retain) NSString * identifier;
@property (nonatomic, retain) NSNumber * lat;
@property (nonatomic, retain) NSNumber * longtitude;
@property (nonatomic, retain) NSNumber * radius;
@property (nonatomic, retain) NSNumber * recipient;
@property (nonatomic, retain) NSNumber * recur;
@property (nonatomic, retain) NSNumber * setting;
@property (nonatomic, retain) NSNumber * onArrival;
@property (nonatomic, retain) NSNumber * onLeave;

@end
