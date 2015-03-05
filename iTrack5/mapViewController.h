//
//  mapViewController.h
//  iTrack5
//
//  Created by Dean Leitersdorf on 2/17/15.
//  Copyright (c) 2015 Dean Leitersdorf. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>
#import <CoreLocation/CoreLocation.h>
#import <MapKit/MapKit.h>
#import "Geofence.h"
#import "MapPin.h"


@protocol geofenceCreator <NSObject>

- (void) addFenceWithLong:(float)longtitude lat:(float)lat recurr:(float)recurr recipient:(NSInteger)rec address:(NSString*)address radius:(NSInteger)radius givenFence:(Geofence*)fence arrival:(BOOL)arrival leave:(BOOL)leave;

@end




@interface mapViewController : UIViewController <NSFetchedResultsControllerDelegate, CLLocationManagerDelegate, geofenceCreator, MKMapViewDelegate>
@property (strong, nonatomic) NSFetchedResultsController *fetchedResultsController;
@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (weak, nonatomic) IBOutlet MKMapView *mapView;
@property (weak, nonatomic) IBOutlet UISearchBar *searchBar;

- (void) setSearchBarShown:(BOOL)shown;


@end
