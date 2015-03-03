//
//  MasterViewController.m
//  iTrack5
//
//  Created by Dean Leitersdorf on 2/15/15.
//  Copyright (c) 2015 Dean Leitersdorf. All rights reserved.
//

#import "MasterViewController.h"
#import "DetailViewController.h"

@interface MasterViewController ()

@property (strong, nonatomic) CLLocationManager* locationManager;
@property (strong, nonatomic) CLLocation* lastKnownLocation;

@end

@implementation MasterViewController

- (void)awakeFromNib {
    [super awakeFromNib];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    self.navigationItem.leftBarButtonItem = self.editButtonItem;

    UIBarButtonItem *addButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addButtonClicked)];
    self.navigationItem.rightBarButtonItem = addButton;
    
   
    [self.locationManager startMonitoringSignificantLocationChanges];
    /*
    CLCircularRegion* region = [[CLCircularRegion alloc] initWithCenter:CLLocationCoordinate2DMake(-36.923, 123.222) radius:100.00 identifier:@"random string"];
    [self.locationManager startMonitoringForRegion:region];*/
    
    
}

- (void) addButtonClicked
{
    [self performSegueWithIdentifier:@"showDetail" sender:self];
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
    
    //check fence time:
    float currentTime = [[NSDate date] timeIntervalSince1970];
    if(currentTime >= [fence.timestampStart floatValue] && currentTime <= [fence.timestampEnd floatValue])
    {
        [self hitFence:fence];
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
 
    if(!fence.hasBeenHit){//check again, even though it was supposed to be checked, because we are accessing async so 2 threads could have entered this method
    fence.hasBeenHit = [NSNumber numberWithBool:YES];
    [self save];
    [self sendMessageTo:fence.recipient address:fence.address];}
    
    
}

- (void) sendMessageTo:(NSNumber*)rec address:(NSString*)address
{
    dispatch_queue_t q = dispatch_queue_create("Q5", NULL);
    dispatch_async(q, ^{
        
        NSURL *url = [NSURL URLWithString:@"http://textbelt.com/text"];
        NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:url];
        NSString* message = [NSString stringWithFormat: @"You have been notified that ___ arrived at: %@.", address];
        NSString *messageBody = [NSString stringWithFormat:@"number=%@&message=%@",rec, message];
        NSData* dataToSend = [messageBody dataUsingEncoding:NSUTF8StringEncoding];
        request.HTTPBody = dataToSend;
        request.HTTPMethod = @"POST";
        NSError* error;
        NSData* data = [NSURLConnection sendSynchronousRequest:request returningResponse:nil error:&error];
        NSDictionary* response = [NSJSONSerialization JSONObjectWithData:data options:0 error:NULL];
        BOOL success = [response valueForKey:@"success"];
        
        
        UILocalNotification *localNotification = [[UILocalNotification alloc] init];
        localNotification.fireDate = [NSDate date];
        localNotification.alertBody = success ? [NSString stringWithFormat:@"Sent to %@ that you arrived at: %@.", rec, address] : [NSString stringWithFormat:@"Failed to send to %@ that you arrived at: %@.", rec, address];
        localNotification.soundName = UILocalNotificationDefaultSoundName;
        localNotification.applicationIconBadgeNumber = 1;
        [[UIApplication sharedApplication] scheduleLocalNotification:localNotification];
    });

}

#pragma mark - Segues

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
}

- (void) addFenceWithLong:(float)longtitude lat:(float)lat start:(float)start stop:(float)stop recurr:(float)recurr recipient:(NSInteger)rec address:(NSString*)address{
    NSManagedObjectContext *context = [self.fetchedResultsController managedObjectContext];
    Geofence* fence = [NSEntityDescription insertNewObjectForEntityForName:@"Geofence"inManagedObjectContext:context];
    
    fence.longtitude = [NSNumber numberWithFloat:longtitude];
    fence.lat = [NSNumber numberWithFloat:lat];
    fence.timestampStart = [NSNumber numberWithFloat:start];
    fence.timestampEnd = [NSNumber numberWithFloat:stop];
    fence.recur = [NSNumber numberWithFloat:recurr];
    fence.recipient = [NSNumber numberWithInteger: rec];
    fence.identifier = [self randomStringWithLength:10];
    fence.address = address;
    
    [self save];
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

#pragma mark - Table View

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return [[self.fetchedResultsController sections] count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    id <NSFetchedResultsSectionInfo> sectionInfo = [self.fetchedResultsController sections][section];
    return [sectionInfo numberOfObjects];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
    [self configureCell:cell atIndexPath:indexPath];
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        NSManagedObjectContext *context = [self.fetchedResultsController managedObjectContext];
        [context deleteObject:[self.fetchedResultsController objectAtIndexPath:indexPath]];
            
        NSError *error = nil;
        if (![context save:&error]) {
            // Replace this implementation with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        }
    }
}

- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath {
    NSManagedObject *object = [self.fetchedResultsController objectAtIndexPath:indexPath];
    cell.textLabel.text = [[object valueForKey:@"timestampStart"] description];
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

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller
{
    [self.tableView beginUpdates];
}

- (void) updateTrackers
{
    NSSet* monitored = self.locationManager.monitoredRegions;
    for(CLRegion* region in monitored)
    {
        [self.locationManager stopMonitoringForRegion:region];
    }
    
    NSArray* allGeofences = [self.fetchedResultsController fetchedObjects];
    for(Geofence* fence in allGeofences)
    {
        if(!fence.hasBeenHit && [fence.timestampEnd doubleValue] >= [[NSDate date] timeIntervalSince1970])//if geofence is expired, don't track
            [self startTrackingGeofence:fence];
    }
    NSSet* monitored2 = self.locationManager.monitoredRegions;
    
}

- (void) startTrackingGeofence:(Geofence*)fence
{
    CLCircularRegion* region = [[CLCircularRegion alloc] initWithCenter:CLLocationCoordinate2DMake([fence.lat doubleValue], [fence.longtitude doubleValue]) radius:1000.00 identifier:fence.identifier];
    
    [self.locationManager startMonitoringForRegion:region];
}

- (void)controller:(NSFetchedResultsController *)controller didChangeSection:(id <NSFetchedResultsSectionInfo>)sectionInfo
           atIndex:(NSUInteger)sectionIndex forChangeType:(NSFetchedResultsChangeType)type
{
    switch(type) {
        case NSFetchedResultsChangeInsert:
            [self.tableView insertSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeDelete:
            [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        default:
            return;
    }
}

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject
       atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type
      newIndexPath:(NSIndexPath *)newIndexPath
{
    UITableView *tableView = self.tableView;
    
    switch(type) {
        case NSFetchedResultsChangeInsert:
            [tableView insertRowsAtIndexPaths:@[newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeDelete:
            [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeUpdate:
            [self configureCell:[tableView cellForRowAtIndexPath:indexPath] atIndexPath:indexPath];
            break;
            
        case NSFetchedResultsChangeMove:
            [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
            [tableView insertRowsAtIndexPaths:@[newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
    }
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    [self.tableView endUpdates];
    [self updateTrackers];
}

/*
// Implementing the above methods to update the table view in response to individual changes may have performance implications if a large number of changes are made simultaneously. If this proves to be an issue, you can instead just implement controllerDidChangeContent: which notifies the delegate that all section and object changes have been processed. 
 
 - (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    // In the simplest, most efficient, case, reload the table view.
    [self.tableView reloadData];
}
 */

@end
