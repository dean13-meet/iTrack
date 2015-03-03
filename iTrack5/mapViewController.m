//
//  mapViewController.m
//  iTrack5
//
//  Created by Dean Leitersdorf on 2/17/15.
//  Copyright (c) 2015 Dean Leitersdorf. All rights reserved.
//

#import "mapViewController.h"
#import "MapPinView.h"

@interface mapViewController ()

@property (strong, nonatomic) CLLocationManager* locationManager;
@property (strong, nonatomic) CLLocation* lastKnownLocation;

@property (strong, nonatomic) NSMutableArray* mapSettingEnums;
@property (strong, nonatomic) NSMutableArray* searchAnnotations;

@property (weak, nonatomic) IBOutlet UIButton *allButton;
@property (weak, nonatomic) IBOutlet UIButton *activeButton;
@property (weak, nonatomic) IBOutlet UIButton *completeButton;
@property (weak, nonatomic) IBOutlet UIButton *expiredButton;

@property (nonatomic) BOOL isSearching;


@end

//Map Enum
typedef enum {
    kAll, //Will show ALL pins, except for search pins
    kSearch, //Will show ONLY search pins
    kActive,
    kCompleted,
    kExpired,
    numberOfEnumItems//counts above items (because top item = 0 and we increment by 1)
} MapSetting;
//Overriding chain: Search overrides All which overrides ANY OTHER setting

/*
 Types of Pins:
 
 
 Search
    Not stored in core memory
    Only active when search bar is searching for locations
    */
    #define searchPinColor MKPinAnnotationColorPurple/*
 
 Active
    Stored in memory as status:active
    */
    #define activePinColor MKPinAnnotationColorGreen/*

 Completed
    Stored in memory as status:completed
    */
    #define completedPinColor MKPinAnnotationColorRed/*
 
 Expired
    Stored in memory as status:expired
    */
    #define expiredPinColor MKPinAnnotationColorRed/*


 */

@implementation mapViewController

- (NSMutableArray*) mapSettingEnums
{
    if(!_mapSettingEnums)
    {
        _mapSettingEnums = [[NSMutableArray alloc] init];
        for(int i = 0; i < numberOfEnumItems;i++)
        {
            [_mapSettingEnums addObject:[NSNumber numberWithBool:NO]];
        }
    }
    return _mapSettingEnums;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self dealWithSignificantLocationChanges];
    self.mapView.delegate = self;
    self.mapView.showsUserLocation = YES;

    [self requestStatusForAllMonitoredRegions];
    
    UITapGestureRecognizer* closeKeyboardsTap = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(closeKeyboard)] ;
    closeKeyboardsTap.numberOfTouchesRequired=1;
    [self.view addGestureRecognizer:closeKeyboardsTap];
    
    [self setSetting:kAll on:YES forceAnnotationUpdate:YES];
    
    
}



- (void) closeKeyboard
{
    [self.view endEditing:YES];
}

- (CLLocationManager*) locationManager
{
    if(!_locationManager)
    {
        _locationManager = [[CLLocationManager alloc] init];
        _locationManager.desiredAccuracy = kCLLocationAccuracyBest;
        [_locationManager requestAlwaysAuthorization];
        _locationManager.delegate = self;
    }
    return _locationManager;
}

- (void) requestStatusForAllMonitoredRegions
{

    NSSet* regions = self.locationManager.monitoredRegions;
    for(CLRegion* region in regions)
    {
        [self.locationManager requestStateForRegion:region];
    }
    
}

- (void) locationManager:(CLLocationManager *)manager didStartMonitoringForRegion:(CLRegion *)region
{
    [self.locationManager requestStateForRegion:region];
}

- (void) locationManager:(CLLocationManager *)manager monitoringDidFailForRegion:(CLRegion *)region withError:(NSError *)error
{
    [self.locationManager requestStateForRegion:region];//error typically happens during requestState - just recall
}

- (void) locationManager:(CLLocationManager *)manager didEnterRegion:(CLRegion *)region
{
    Geofence* fence = [self getFenceFromRegion:region];
    if(!fence)//if for some reason we recieved "didEnterRegion", but we are not looking to track that region, just remove it from monitoring
    {
        [self.locationManager stopMonitoringForRegion:region];
        return;
    }
    
    //check fence active && whether to expire:
    
    if([fence.setting isEqualToNumber:[NSNumber numberWithInt:kActive]])
    {
        if(![self expireFence:fence])
        {
            if([self isCurrentTimeInFenceTimeBounds:fence])
                [self hitFence:fence];
        }
        else
            [self save];//fence was set to expired. save this change.
    }
    
    
    
}
- (void) locationManager:(CLLocationManager *)manager didDetermineState:(CLRegionState)state forRegion:(CLRegion *)region
{
    if(state == CLRegionStateInside)
    {
        [self locationManager:manager didEnterRegion:region];
    }
}

- (void) locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
{
    self.lastKnownLocation = locations[locations.count-1];
    [self updateTrackers];
}

- (Geofence*) getFenceFromRegion:(CLRegion*)region
{
    NSArray* allRegions = self.fetchedResultsController.fetchedObjects;
    Geofence* retval;
    for (Geofence* fence in allRegions)
    {
        if([fence.identifier isEqualToString:region.identifier])
        {
            retval = fence;
            break;
        }
    }
    
    return retval;
}

- (void) hitFence:(Geofence*)fence
{
    
    if([fence.setting isEqualToNumber:[NSNumber numberWithInt:kActive]] && ![self expireFence:fence] && [self isCurrentTimeInFenceTimeBounds:fence]){//check again, even though it was supposed to be checked, because we are accessing async so 2 threads could have entered this method with same region being tracked (e.g. 1 from delegate method "didDetermineState" and other from "didEnterRegion"
        [self setFenceCompleted:fence];
        [self sendMessageTo:fence.recipient address:fence.address];}
    
    
}



- (void) sendMessageTo:(NSNumber*)rec address:(NSString*)address
{
    dispatch_queue_t q = dispatch_queue_create("Q5", NULL);
    dispatch_async(q, ^{
        
        NSURL *url = [NSURL URLWithString:@"http://dean-leitersdorf.herokuapp.com/sendmessage"];
        NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:url];
        
        NSString* message = [NSString stringWithFormat: @"You have been notified that ___ arrived at: %@.", address];
        NSDictionary* thisMessage = @{@"number":rec, @"message":message};
        /*NSString *messageBody = [NSString stringWithFormat:@"number=%@&message=%@",rec, message];
        NSData* dataToSend = [messageBody dataUsingEncoding:NSUTF8StringEncoding];*/
        NSData* dataToSend = [NSJSONSerialization dataWithJSONObject:thisMessage options:kNilOptions error:NULL];
        request.HTTPBody = dataToSend;
        request.HTTPMethod = @"POST";
        NSError* error;
        NSData* data = [NSURLConnection sendSynchronousRequest:request returningResponse:nil error:&error];
        NSDictionary* response = [NSJSONSerialization JSONObjectWithData:data options:0 error:NULL];
        BOOL success = [[response valueForKey:@"success"] boolValue];
        
        
        UILocalNotification *localNotification = [[UILocalNotification alloc] init];
        localNotification.fireDate = [NSDate date];
        localNotification.alertBody = success ? [NSString stringWithFormat:@"Sent to %@ that you arrived at: %@.", rec, address] : [NSString stringWithFormat:@"Failed to send to %@ that you arrived at: %@.", rec, address];
        localNotification.soundName = UILocalNotificationDefaultSoundName;
        localNotification.applicationIconBadgeNumber = 1;
        [[UIApplication sharedApplication] scheduleLocalNotification:localNotification];
    });
    
}

#pragma mark - Segues
/*
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([[segue identifier] isEqualToString:@"showDetail"]) {
        
        NSManagedObject *object;
        if (![sender isEqual:self]) {
            NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
            object = [[self fetchedResultsController] objectAtIndexPath:indexPath];
        }//if sender is self, then we are being launched from add button
        
        [[segue destinationViewController] setDetailItem:object];
        ((DetailViewController*)[segue destinationViewController]).delegate = self;
    }
}*/

- (void) addFenceWithLong:(float)longtitude lat:(float)lat start:(float)start stop:(float)stop recurr:(float)recurr recipient:(NSInteger)rec address:(NSString*)address radius:(NSInteger)radius givenFence:(Geofence *)fence{
    NSManagedObjectContext *context = [self.fetchedResultsController managedObjectContext];
    if(!fence)//a given fence would mean "Update" the fence. If no given fence, "Create" the fence.
        fence = [NSEntityDescription insertNewObjectForEntityForName:@"Geofence"inManagedObjectContext:context];
    
    fence.longtitude = [NSNumber numberWithFloat:longtitude];
    fence.lat = [NSNumber numberWithFloat:lat];
    fence.timestampStart = [NSNumber numberWithFloat:start];
    fence.timestampEnd = [NSNumber numberWithFloat:stop];
    fence.recur = [NSNumber numberWithFloat:recurr];
    fence.recipient = [NSNumber numberWithInteger: rec];
    if(!fence.identifier)
        fence.identifier = [self randomStringWithLength:10];
    fence.address = address;
    fence.setting = [NSNumber numberWithInt:kActive];
    fence.radius = [NSNumber numberWithInteger:radius];
    
    [self setSetting:kSearch on:NO forceAnnotationUpdate:NO];
    [self setSetting:kAll on:YES forceAnnotationUpdate:NO];//set ALL to be on
    [self save];
    //No need to updateMapAnnotations/trackers - when save changes context, updateMapAnnotations/trackers already get called.
    //[self updateMapAnnotaions];
    //[self updateTrackers];
}

- (void) setSetting:(int)setting on:(BOOL)on forceAnnotationUpdate:(BOOL)force
{
    //check bounds
    if(setting >= numberOfEnumItems)
        return;
    
    //change setting in enums
    self.mapSettingEnums[setting] = [NSNumber numberWithBool:on];
    
    //set button selected
    switch (setting) {
        case kAll:
            self.allButton.selected = on;
            break;
            
        case kActive:
            self.activeButton.selected = on;
            break;
            
        case kCompleted:
            self.completeButton.selected = on;
            break;
        
        case kExpired:
            self.expiredButton.selected = on;
            break;
            
        default:
            break;
    }
    
    //if setting was "search", update isSearching property. NOTE: Must be done AFTER buttons are changed above, because setting isSearching may change buttons.
    if(setting == kSearch)
    {
        self.isSearching = on;
    }
    
    //update map annotations
    if(force)
        [self updateMapAnnotaions];
    
}

- (void) save
{
    NSManagedObjectContext *context = [self.fetchedResultsController managedObjectContext];
    // Save the context.
    NSError *error = nil;
    if (![context save:&error]) {
        // Replace this implementation with code to handle the error appropriately.
        // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
    
}

NSString *letters = @"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
-(NSString *) randomStringWithLength: (int) len {
    
    NSMutableString *randomString = [NSMutableString stringWithCapacity: len];
    
    for (int i=0; i<len; i++) {
        [randomString appendFormat: @"%C", [letters characterAtIndex: arc4random()%[letters length]]];
    }
    
    return randomString;
}


#pragma mark - Fetched results controller

- (NSFetchedResultsController *)fetchedResultsController
{
    if (_fetchedResultsController != nil) {
        return _fetchedResultsController;
    }
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    // Edit the entity name as appropriate.
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Geofence" inManagedObjectContext:self.managedObjectContext];
    [fetchRequest setEntity:entity];
    
    // Set the batch size to a suitable number.
    [fetchRequest setFetchBatchSize:20];
    
    // Edit the sort key as appropriate.
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"timestampStart" ascending:NO];
    NSArray *sortDescriptors = @[sortDescriptor];
    
    [fetchRequest setSortDescriptors:sortDescriptors];
    
    // Edit the section name key path and cache name if appropriate.
    // nil for section name key path means "no sections".
    NSFetchedResultsController *aFetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:self.managedObjectContext sectionNameKeyPath:nil cacheName:@"Master"];
    aFetchedResultsController.delegate = self;
    self.fetchedResultsController = aFetchedResultsController;
    
    NSError *error = nil;
    if (![self.fetchedResultsController performFetch:&error]) {
        // Replace this implementation with code to handle the error appropriately.
        // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
    
    return _fetchedResultsController;
}


- (void) updateTrackers
{
    NSSet* monitored = self.locationManager.monitoredRegions;
    NSArray* allGeofences = [self.fetchedResultsController fetchedObjects];
    
    NSMutableArray* regionsToIgnore = [[NSMutableArray alloc] init];//monitored doesnt update instantly
    NSMutableDictionary* allGeoMatchedToMonitored = [[NSMutableDictionary alloc] init];//just keeps track of which fences have regions being monitored
    BOOL needToSave = NO;
    //weed out bad monitored regions: (BAD = doesn't appear in allGeofences)
    for(CLRegion* region in monitored)
    {
        BOOL regionIsGood = false;
        for(Geofence* fence in allGeofences)
        {
            if(![fence.setting isEqualToNumber:[NSNumber numberWithInt:kActive]])//don't use fences which are inactive
            {
                continue;
            }
            
            else if ([self expireFence:fence])//don't use expired fences
            {
                needToSave = YES;//need to save because fence was set on expired mode now
                continue;
            }
            
            if([fence.identifier isEqualToString:region.identifier])
            {
                regionIsGood = true;
                [allGeoMatchedToMonitored setObject:region forKey:fence.identifier];
                break;
            }
        }
        if(!regionIsGood)
        {
            [regionsToIgnore addObject:region];
            [self.locationManager stopMonitoringForRegion:region];
        }
        
    }
    
    //Loop through geofences
    for(Geofence* fence in allGeofences)
    {
        if([allGeoMatchedToMonitored valueForKey:fence.identifier])//its already being tracked
        {
            continue;
        }
        
        if([fence.setting isEqualToNumber:[NSNumber numberWithInt:kActive]]){
        if(![self expireFence:fence])//track only if fence isn't expired
            [self startTrackingGeofence:fence];
        else
            needToSave = YES;
        
        }
        
    }
    if(needToSave)
        [self save];
    [self requestStatusForAllMonitoredRegions];
    [self dealWithSignificantLocationChanges];
}


//BOOL says whether or not fence is expired (checks both setting and time). If it should be expired, this method automatically sets its status to expired. NOTE: THIS METHOD DOES NOT SAVE THE CONTEXT IF IT IS BAD!!!! YOU MUST SAVE CONTEXT ON YOUR OWN! (IT DOES SAVE IF IT IS GOOD AND RECUR HAPPENED - this is b/c recurFence saves context)
- (BOOL) expireFence:(Geofence*) fence
{
    if([fence.setting isEqualToNumber:[NSNumber numberWithInt:kExpired]])
        return YES;//fence is bad
    
    if([fence.timestampEnd doubleValue] > [[NSDate date] timeIntervalSince1970])
    {
        return NO;//fence is good
    }
    else
    {   //try recur:
        
        BOOL recurSuccess = [self recurFence:fence];
        if(!recurSuccess)
            fence.setting = [NSNumber numberWithInt:kExpired];
        return !recurSuccess;//recur worked = fence is good, recur fail = fence is bad
    }
}

- (BOOL) isCurrentTimeInFenceTimeBounds:(Geofence*)fence
{
    double start = [fence.timestampStart doubleValue];
    double end = [fence.timestampEnd doubleValue];
    double current = [[NSDate date] timeIntervalSince1970];
    
    return start <= current && end >= current;
}

//BOOL = recur success
- (BOOL) recurFence:(Geofence*)fence
{
    int recur = [fence.recur intValue];
    if(recur)
    {
        double timeInterval =([[NSDate date] timeIntervalSince1970] - [fence.timestampEnd doubleValue]);
        int numberOfTimesToIncrementByRecur = ceilf(timeInterval/recur);// time since fence expired, divided by recur 'size'.
        if(numberOfTimesToIncrementByRecur<1 && [self isCurrentTimeInFenceTimeBounds:fence])//number of times to recur can be 0 or negative IF we are still inside the recur time (e.g. user set the program to recur everyday between 7:00 and 8:00. If he misses 1 day entirely, numberOfTimes... will be more than 1, HOWEVER, if he arrives at say 7:15, timeInterval will be negative as his end time is still further in the future than the current time. Nonetheless, the user would want the program to recur, thus, numberOfTimesToRecur should be at least 1 whenever we are told to recur and are within the time frame for hits.
            numberOfTimesToIncrementByRecur = 1;
        fence.timestampEnd = [NSNumber numberWithFloat:[fence.timestampEnd floatValue] + recur * numberOfTimesToIncrementByRecur];
        fence.timestampStart = [NSNumber numberWithFloat:[fence.timestampStart floatValue] + recur * numberOfTimesToIncrementByRecur];
        
        [self save];
        return YES;
    }
    else
        return NO;
    
}

- (void) setFenceCompleted:(Geofence*)fence
{
    BOOL recurSuccess = [self recurFence:fence];//if recur success, no need to do anything. if not success, set to completed
    
    if(!recurSuccess)
    {
        fence.setting = [NSNumber numberWithInt:kCompleted];
        [self save];
    }
}

- (void) startTrackingGeofence:(Geofence*)fence
{
    CLCircularRegion* region = [[CLCircularRegion alloc] initWithCenter:CLLocationCoordinate2DMake([fence.lat doubleValue], [fence.longtitude doubleValue]) radius:[fence.radius doubleValue] identifier:fence.identifier];
    
    [self.locationManager startMonitoringForRegion:region];
}

- (void)controller:(NSFetchedResultsController *)controller didChangeSection:(id <NSFetchedResultsSectionInfo>)sectionInfo
           atIndex:(NSUInteger)sectionIndex forChangeType:(NSFetchedResultsChangeType)type
{
    [self updateMapAnnotaions];
}

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject
       atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type
      newIndexPath:(NSIndexPath *)newIndexPath
{
    [self updateMapAnnotaions];
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    [self dealWithSignificantLocationChanges];
    [self updateMapAnnotaions];
    [self updateTrackers];
}

- (void) dealWithSignificantLocationChanges
{
    NSArray* allGeos = self.fetchedResultsController.fetchedObjects;
    int numberOfActiveFences = 0;
    
    for(Geofence* fence in allGeos)
    {
        if([fence.setting isEqualToNumber:[NSNumber numberWithInt:kActive]])
        {
            numberOfActiveFences++;
        }
    }
    
    if(numberOfActiveFences >= 20)
    {
        [self.locationManager startMonitoringSignificantLocationChanges];
    }
    else
    {
        [self.locationManager stopMonitoringSignificantLocationChanges];
    }
}

#pragma mark searchbar

- (NSMutableArray*) searchAnnotations
{
    if(!_searchAnnotations)
    {
        _searchAnnotations = [[NSMutableArray alloc] init];
    }
    return _searchAnnotations;
}

- (void)searchBarTextDidEndEditing:(UISearchBar *)searchBar
{
    if([searchBar.text isEqualToString:@""])
    {
        [self setSetting:kSearch on:NO forceAnnotationUpdate:YES];
        return;
    }
    
    
    NSString* query = searchBar.text;
    [searchBar resignFirstResponder];
    CLGeocoder* geocoder = [[CLGeocoder alloc] init];
    [geocoder geocodeAddressString:query
                 completionHandler:^(NSArray* placemarks, NSError* error){
                     
                    [self.searchAnnotations removeAllObjects];
                     
                    for (CLPlacemark* aPlacemark in placemarks)
                     {
                         self.mapView.centerCoordinate = aPlacemark.location.coordinate;
                         NSArray *lines = aPlacemark.addressDictionary[ @"FormattedAddressLines"];
                         NSString *addressString = [lines componentsJoinedByString:@"\n"];
                         MapPin* annotation = [[MapPin alloc] initWithCoordinates:aPlacemark.location.coordinate placeName:addressString description:addressString];
                         annotation.address = addressString;
                         annotation.setting = [NSNumber numberWithInt: kSearch];
                         [self.searchAnnotations addObject:annotation];
                         
                     }
                     
                     [self setSetting:kSearch on:YES forceAnnotationUpdate:YES];
                     
                 }];
    
}


- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    [searchBar resignFirstResponder];
}



#pragma mark Manage Map

//Delegate methods:

- (void) mapView:(MKMapView *)mapView didSelectAnnotationView:(MKAnnotationView *)view
{
    [mapView setCenterCoordinate:view.annotation.coordinate animated:YES];
    /*
    make this work according to different enum settings
    self.selectedLocation = view.annotation.coordinate;
    self.selectedAddress = ((MapPin*)view.annotation).address;*/
}

- (MKOverlayView *)mapView:(MKMapView *)mapView viewForOverlay:(id<MKOverlay>)overlay

{
    MKCircleView *circleView = [[MKCircleView alloc] initWithCircle:(MKCircle *)overlay] ;
    circleView.fillColor = [[UIColor blueColor] colorWithAlphaComponent:0.4];
    return circleView;
}


- (MKAnnotationView*)mapView:(MKMapView *)mapView viewForAnnotation:(MapPin*)annotation
{
    
    // If the annotation is the user location, just return nil.
    if ([annotation isKindOfClass:[MKUserLocation class]])
        return nil;
    
    // Handle any custom annotations.
    if ([annotation isKindOfClass:[MapPin class]])
    {
        
        MapPinView* pinView;
        pinView = [[MapPinView alloc] initWithAnnotation:annotation
                                                      reuseIdentifier:@"CustomPinAnnotationView"];
        pinView.animatesDrop = YES;
        pinView.mapVC = self;
            
        // If appropriate, customize the callout by adding accessory views (code not shown).
        
        pinView.annotation = annotation;
        
        MKPinAnnotationColor pinColor;
        
        switch ([((MapPin*)annotation).setting intValue]) {
            case kSearch:
                pinColor = searchPinColor;
                break;
                
            case kActive:
                pinColor = activePinColor;
                break;
                
            case kCompleted:
                pinColor = completedPinColor;
                break;
                
            case kExpired:
                pinColor = expiredPinColor;
                break;
                
            default:
                pinColor = MKPinAnnotationColorRed;
                break;
        }
        pinView.pinColor = pinColor;
        
        pinView.calloutView.addressLabel.text = ((MapPin*)annotation).address;
        if(annotation.fence)
        {
            Geofence* fence = annotation.fence;
            pinView.calloutView.addressLabel.text = fence.address;
            pinView.calloutView.recipientField.text = [NSString stringWithFormat:@"%@", fence.recipient];
            pinView.calloutView.date1 = [NSDate dateWithTimeIntervalSince1970:[fence.timestampStart floatValue]];
            pinView.calloutView.date2 = [NSDate dateWithTimeIntervalSince1970:[fence.timestampEnd floatValue]];\
            
            switch ([fence.recur intValue]) {
                case 0:
                    [pinView.calloutView.repeatControl setSelectedSegmentIndex:0];
                    break;
                    
                case 60*60*24:
                    [pinView.calloutView.repeatControl setSelectedSegmentIndex:1];
                    break;
                    
                case 60*60*24*7:
                    [pinView.calloutView.repeatControl setSelectedSegmentIndex:2];
                    break;
                    
                default:
                    break;
            }
            
            [pinView.calloutView.radiusSlider setValue:[fence.radius floatValue] animated:YES];
            pinView.calloutView.recipientField.text = [NSString stringWithFormat:@"%@", fence.recipient];
            
            pinView.calloutView.fence = fence;
        }
        else
        {
            pinView.calloutView.editMode = YES;
        }
        
        return pinView;
    }
    
    return nil;
    
}

- (void) setSearchBarShown:(BOOL)shown
{
    [self setButtonsShown:shown];
    [UIView animateWithDuration:0.1 animations:^{
        self.searchBar.alpha = [[NSNumber numberWithBool:shown] doubleValue];
    }];
}

- (void) setButtonsShown:(BOOL)shown
{
    [UIView animateWithDuration:0.1 animations:^{
        self.activeButton.alpha = self.allButton.alpha = self.completeButton.alpha = self.expiredButton.alpha = [[NSNumber numberWithBool:shown] doubleValue];
        
        self.allButton.enabled = self.activeButton.enabled = self.completeButton.enabled = self.expiredButton.enabled = shown;
    }];
}

- (void) setIsSearching:(BOOL)isSearching
{
    _isSearching = isSearching;
    [self setButtonsShown:!isSearching];
}

- (IBAction)buttonTouched:(UIButton *)sender
{
    NSInteger tag = sender.tag;
    
    sender.selected = !sender.selected;
    [self setSetting:[[NSNumber numberWithInteger:tag] intValue] on:sender.selected forceAnnotationUpdate:YES];
    
}




- (void) updateMapAnnotaions
{
    NSMutableArray* annotationsToShow = [[NSMutableArray alloc] init];
    BOOL isSearch = [ self.mapSettingEnums[kSearch] boolValue ];
    if(isSearch)
    {
        annotationsToShow = self.searchAnnotations;
    }
    else
    {
        NSArray* geofencesFromCoreData = self.fetchedResultsController.fetchedObjects;
        NSMutableArray* geofencesInAnnotationForm = [[NSMutableArray alloc] init];
        
        for(Geofence* fence in geofencesFromCoreData)
        {
            MapPin* pin = [[MapPin alloc] initWithCoordinates:CLLocationCoordinate2DMake([fence.lat doubleValue], [fence.longtitude doubleValue]) placeName:fence.address description:fence.address];
            pin.address = fence.address;
            pin.setting = fence.setting;
            pin.fence = fence;
            [geofencesInAnnotationForm addObject:pin];
        }
        
        if([self.mapSettingEnums[kAll] boolValue])
        {
            annotationsToShow = geofencesInAnnotationForm;
        }
        
        else
        {
            for(MapPin* pin in geofencesInAnnotationForm)
            {
                int setting = [pin.setting intValue];
                if(setting >= numberOfEnumItems)
                    continue;//some error occured, skip this pin
                if([self.mapSettingEnums[setting] boolValue])
                   [annotationsToShow addObject:pin];
            }
            
        }
        
        
        
    }
    [self.mapView removeAnnotations:self.mapView.annotations];
    
    for(MapPin* pin in annotationsToShow)
    {
        [self.mapView addAnnotation:pin];
    }
    
    [self zoomToAnnotationsBounds];
}





//http://stackoverflow.com/questions/3434020/ios-mkmapview-zoom-to-show-all-markers
- (void) zoomToAnnotationsBounds{
    
    [self zoomToFitMapAnnotations:self.mapView];
    return;
    
    NSArray* annotations = [self.mapView annotations];
    
    if(![annotations count])
    {
        return;
    }
    
    CLLocationDegrees minLatitude = DBL_MAX;
    CLLocationDegrees maxLatitude = -DBL_MAX;
    CLLocationDegrees minLongitude = DBL_MAX;
    CLLocationDegrees maxLongitude = -DBL_MAX;
    
    for (MapPin *annotation in annotations) {
        double annotationLat = annotation.coordinate.latitude;
        double annotationLong = annotation.coordinate.longitude;
        minLatitude = fmin(annotationLat, minLatitude);
        maxLatitude = fmax(annotationLat, maxLatitude);
        minLongitude = fmin(annotationLong, minLongitude);
        maxLongitude = fmax(annotationLong, maxLongitude);
    }
    
    // See function below
    [self setMapRegionForMinLat:minLatitude minLong:minLongitude maxLat:maxLatitude maxLong:maxLongitude];
    
    // If your markers were 40 in height and 20 in width, this would zoom the map to fit them perfectly. Note that there is a bug in mkmapview's set region which means it will snap the map to the nearest whole zoom level, so you will rarely get a perfect fit. But this will ensure a minimum padding.
    UIEdgeInsets mapPadding = UIEdgeInsetsMake(40.0, 10.0, 0.0, 10.0);
    CLLocationCoordinate2D relativeFromCoord = [self.mapView convertPoint:CGPointMake(0, 0) toCoordinateFromView:self.mapView];
    
    // Calculate the additional lat/long required at the current zoom level to add the padding
    CLLocationCoordinate2D topCoord = [self.mapView convertPoint:CGPointMake(0, mapPadding.top) toCoordinateFromView:self.mapView];
    CLLocationCoordinate2D rightCoord = [self.mapView convertPoint:CGPointMake(0, mapPadding.right) toCoordinateFromView:self.mapView];
    CLLocationCoordinate2D bottomCoord = [self.mapView convertPoint:CGPointMake(0, mapPadding.bottom) toCoordinateFromView:self.mapView];
    CLLocationCoordinate2D leftCoord = [self.mapView convertPoint:CGPointMake(0, mapPadding.left) toCoordinateFromView:self.mapView];
    
    double latitudeSpanToBeAddedToTop = relativeFromCoord.latitude - topCoord.latitude;
    double longitudeSpanToBeAddedToRight = relativeFromCoord.latitude - rightCoord.latitude;
    double latitudeSpanToBeAddedToBottom = relativeFromCoord.latitude - bottomCoord.latitude;
    double longitudeSpanToBeAddedToLeft = relativeFromCoord.latitude - leftCoord.latitude;
    
    maxLatitude = maxLatitude + latitudeSpanToBeAddedToTop;
    minLatitude = minLatitude - latitudeSpanToBeAddedToBottom;
    
    maxLongitude = maxLongitude + longitudeSpanToBeAddedToRight;
    minLongitude = minLongitude - longitudeSpanToBeAddedToLeft;
    
    [self setMapRegionForMinLat:minLatitude minLong:minLongitude maxLat:maxLatitude maxLong:maxLongitude];
}

-(void) setMapRegionForMinLat:(double)minLatitude minLong:(double)minLongitude maxLat:(double)maxLatitude maxLong:(double)maxLongitude {
    
    MKCoordinateRegion region;
    region.center.latitude = ((minLatitude + maxLatitude)*1) / 2;
    region.center.longitude = ((minLongitude + maxLongitude)*1) / 2;
    region.span.latitudeDelta = (maxLatitude - minLatitude)*1.5;//*1.5 is for little buffer zone
    region.span.longitudeDelta = (maxLongitude - minLongitude)*1.5;
    
    // MKMapView BUG: this snaps to the nearest whole zoom level, which is wrong- it doesn't respect the exact region you asked for. See http://stackoverflow.com/questions/1383296/why-mkmapview-region-is-different-than-requested
    [self.mapView setRegion:region animated:YES];
}


- (void)zoomToFitMapAnnotations:(MKMapView *)theMapView {
    if ([theMapView.annotations count] == 0) return;
    
    CLLocationCoordinate2D topLeftCoord;
    topLeftCoord.latitude = -180;
    topLeftCoord.longitude = 360;
    
    CLLocationCoordinate2D bottomRightCoord;
    bottomRightCoord.latitude = 180;
    bottomRightCoord.longitude = -360;
    
    for (id <MKAnnotation> annotation in theMapView.annotations) {
        topLeftCoord.longitude = fmin(topLeftCoord.longitude, annotation.coordinate.longitude);
        topLeftCoord.latitude = fmax(topLeftCoord.latitude, annotation.coordinate.latitude);
        bottomRightCoord.longitude = fmax(bottomRightCoord.longitude, annotation.coordinate.longitude);
        bottomRightCoord.latitude = fmin(bottomRightCoord.latitude, annotation.coordinate.latitude);
    }
    
    MKCoordinateRegion region;
    region.center.latitude = topLeftCoord.latitude - (topLeftCoord.latitude - bottomRightCoord.latitude) * 0.5;
    region.center.longitude = topLeftCoord.longitude + (bottomRightCoord.longitude - topLeftCoord.longitude) * 0.5;
    region.span.latitudeDelta = fabs(topLeftCoord.latitude - bottomRightCoord.latitude) * 1.4;
    
    region.span.longitudeDelta = fabs(bottomRightCoord.longitude - topLeftCoord.longitude) * 1.4;
    
    region = [theMapView regionThatFits:region];
    [theMapView setRegion:region animated:YES];
}
@end
