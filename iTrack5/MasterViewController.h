//
//  MasterViewController.h
//  iTrack5
//
//  Created by Dean Leitersdorf on 2/15/15.
//  Copyright (c) 2015 Dean Leitersdorf. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>
#import <CoreLocation/CoreLocation.h>
#import "DetailViewController.h"

@interface MasterViewController : UITableViewController <NSFetchedResultsControllerDelegate, CLLocationManagerDelegate, geofenceCreator>

@property (strong, nonatomic) NSFetchedResultsController *fetchedResultsController;
@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;

- (void) addFenceWithLong:(float)longtitude lat:(float)lat start:(float)start stop:(float)stop recurr:(float)recurr recipient:(NSInteger)rec address:(NSString*)address;

@end

