//
//  AppDelegate.h
//  iTrack5
//
//  Created by Dean Leitersdorf on 2/15/15.
//  Copyright (c) 2015 Dean Leitersdorf. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>
#import "socketDealer.h"
#import <CoreLocation/CoreLocation.h>


@interface AppDelegate : UIResponder <UIApplicationDelegate, socketDealerDelegate, UIAlertViewDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;

@property (strong, nonatomic)socketDealer* socketDealer;

- (void)saveContext;
- (NSURL *)applicationDocumentsDirectory;

@property (strong, nonatomic)UIViewController* mapVC;//when the mapVC loads, it stores itself here
- (void) showLocationAlert;
@property (strong, nonatomic) CLLocationManager* locationManager;


- (void) setMapEnabled:(BOOL)enabled excluding:(NSArray*)excluding;

@end

