//
//  DetailViewController.h
//  iTrack3
//
//  Created by Dean Leitersdorf on 2/13/15.
//  Copyright (c) 2015 Dean Leitersdorf. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
#import "Geofence.h"

@protocol geofenceCreator <NSObject>

- (void) addFenceWithLong:(float)longtitude lat:(float)lat start:(float)start stop:(float)stop recurr:(float)recurr recipient:(NSInteger)rec address:(NSString*)address;

@end

@interface DetailViewController : UIViewController <MKMapViewDelegate, UISearchBarDelegate>

@property (strong, nonatomic) Geofence* detailItem;
@property (weak, nonatomic) IBOutlet UILabel *detailDescriptionLabel;

@property (weak, nonatomic) IBOutlet UITextField *recipientField;
@property (weak, nonatomic) IBOutlet UISearchBar *searchBar;
@property (weak, nonatomic) IBOutlet MKMapView *mapView;
@property (weak, nonatomic) IBOutlet UITextField *startTime;
@property (weak, nonatomic) IBOutlet UITextField *endTime;
@property (weak, nonatomic) IBOutlet UITextField *recurTime;

@property (weak, nonatomic) id<geofenceCreator> delegate;

@end

