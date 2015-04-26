//
//  mapViewController.m
//  iTrack5
//
//  Created by Dean Leitersdorf on 2/17/15.
//  Copyright (c) 2015 Dean Leitersdorf. All rights reserved.
//

#import "mapViewController.h"
#import "urls.m"
#import "signInPopup.h"
#import "AppDelegate.h"
#import "socketDealer.h"
#import "takeCareOfUserUpdates.h"
#import "MapPinView.h"
#import "Person.h"
#import "welcome.h"



@interface mapViewController ()


@property (strong, nonatomic) CLLocation* lastKnownLocation;

@property (nonatomic, weak) CLLocationManager* locationManager;
@property (strong, nonatomic) NSMutableArray* searchAnnotations;

@property (weak, nonatomic) IBOutlet UIButton *allButton;
@property (weak, nonatomic) IBOutlet UIButton *activeButton;
@property (weak, nonatomic) IBOutlet UIButton *completeButton;
@property (weak, nonatomic) IBOutlet UIButton *expiredButton;

@property (strong, nonatomic) signInPopup* signInPopup;
@property (strong, nonatomic) welcome* welcomeSign;


@property (nonatomic) BOOL isSearching;
@property (strong, nonatomic) NSMutableDictionary* searchResultsCache;

@property (strong, nonatomic) takeCareOfUserUpdates* updateCaretaker;

@property (nonatomic) CGRect searchBarDefaultFrame;
@property (strong, nonatomic) NSString* lastestQuery;
@property (strong, nonatomic) UIColor* defaultSearchBarColor;


@end


@implementation mapViewController

- (CLLocationManager*)locationManager
{
	if(!_locationManager)
	{
		_locationManager = ((AppDelegate*)[UIApplication sharedApplication].delegate).locationManager;//pull it from the app delegate
		_locationManager.delegate = self;
	}
	return _locationManager;
}
- (void) locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status
{
	if(status != kCLAuthorizationStatusAuthorizedAlways)
	{
		[((AppDelegate*)[UIApplication sharedApplication].delegate) showLocationAlert];
	}
}

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
{	mapVCFromAppDelegate = self;
    [super viewDidLoad];
	
    [self dealWithSignificantLocationChanges];
    self.mapView.delegate = self;
    self.mapView.showsUserLocation = YES;

    [self requestStatusForAllMonitoredRegions];
    
    UITapGestureRecognizer* closeKeyboardsTap = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(closeKeyboard)] ;
	closeKeyboardsTap.cancelsTouchesInView = NO;
    closeKeyboardsTap.numberOfTouchesRequired=1;
    [self.view addGestureRecognizer:closeKeyboardsTap];
    
    [self setSetting:kAll on:YES forceAnnotationUpdate:YES];
    
    
    MapPinView* pinView;
    pinView = [[MapPinView alloc] initWithAnnotation:[[MapPin alloc] initWithCoordinates:CLLocationCoordinate2DMake(0, 0) placeName:nil description:nil mapVC:nil] reuseIdentifier:@"test"];
    CGRect prevFrame = pinView.frame;
    pinView.pinColor = searchPinColor;
    
    pinView.frame = CGRectMake((self.searchBarPinBox.frame.size.width-prevFrame.size.width)/2, (self.searchBarPinBox.frame.size.height-prevFrame.size.height)/2, prevFrame.size.width, prevFrame.size.height);
    pinView.userInteractionEnabled = YES;
    
    UIPanGestureRecognizer* pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(moveSearchBarPin:)];
    [pinView addGestureRecognizer:pan];
    
    
    [self.searchBarPinBox addSubview:pinView];
	
	[self dealWithLogin];
	[self registerTrackerForGeofences];
	
	self.modeButton.selected = YES;//just looks better
	
	[self getUserUpdates];
	[self prepareServerForCoreData];
	[((AppDelegate*)[[UIApplication sharedApplication] delegate]) showLocationAlert];
	[self showWelcomeSign];
	
	
	
}

- (void) dealWithLogin
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSString* userUUID = [defaults valueForKey:userUUIDDefaultsURL];
	if(!userUUID)
	{//create popup to create username or login:
		
		self.signInPopup =  [[signInPopup alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width*.92, self.view.frame.size.height*.92)];
		signInPopup* popup = self.signInPopup;//just easier to write "popup"
		popup.center = self.view.center;
		popup.transform = CGAffineTransformMakeScale(2, 2);
		[self.view addSubview:popup];
		[UIView animateWithDuration:.2 animations:^{
			popup.transform = CGAffineTransformMakeScale(1, 1);
		}];
		
		[self removeAllGeofences];
		[self ensureNotTrackingAnyFence];
		
	}

}
- (void) dismissSignInPopup
{
	[UIView animateWithDuration:.1
					 animations:^{
						 //self.frame = CGRectMake(self.center.x - 350, self.center.y - 350, 700,700);
						 self.signInPopup.transform = CGAffineTransformMakeScale(.1, .1);
					 } completion:^(BOOL finished) {
						 self.signInPopup.transform = CGAffineTransformMakeScale(1, 1);//so that next time the view is loaded, its back to normal
						 [self.signInPopup removeFromSuperview];
					 }];
	
	
	[self registerTrackerForGeofences];
	[self getUserUpdates];
	[self showWelcomeSign];
}


- (void) showWelcomeSign
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSString* username = [defaults valueForKey:usernameDefaultsURL];
	if(!username)return;
	self.welcomeSign = [[welcome alloc]init];
	self.welcomeSign.center = self.view.center;
	[self.view addSubview:self.welcomeSign];
	
}
- (void) dismissWelcomeSign
{
	if(self.welcomeSign.superview)//it's presented
	{
		[self.welcomeSign enterClicked:nil];
	}
}
-(void) touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
	[self dismissWelcomeSign];
	[super touchesBegan:touches withEvent:event];
}

- (void) removeWelcomeSign
{
	[self.welcomeSign enterClicked:nil];
}

- (void) getUserUpdates
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSString* userUUID = [defaults valueForKey:userUUIDDefaultsURL];
	if(!userUUID)return;
	self.updateCaretaker = [[takeCareOfUserUpdates alloc] init];
	self.updateCaretaker.mapVC = self;
}


- (void) registerTrackerForGeofences
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSString* userUUID = [defaults valueForKey:userUUIDDefaultsURL];
	if(!userUUID)return;//its ok - after sign in, all geofences will be fetched. For now, as long as not signed in, there is nothing we can do.
	//register for created/deleted geofences
	[((AppDelegate*)[[UIApplication sharedApplication] delegate]).socketDealer signUpForDataWithInfo:@{@"id" : userUUID, @"field" : @"geofences"} sender:self withSelector:@selector(fetchAllGeofences)];
	[((AppDelegate*)[[UIApplication sharedApplication] delegate]).socketDealer signUpForDataWithInfo:@{@"id" : userUUID, @"field" : @"requestedGeofences"} sender:self withSelector:@selector(fetchAllRequestedGeofences)];
	
	//register for getting updated fences:
	[((AppDelegate*)[[UIApplication sharedApplication] delegate]).socketDealer signUpForEvent:@"getGeofencesForUserUUID" sender:self withSelector:@selector(updateAllGeofences:)];
	[((AppDelegate*)[[UIApplication sharedApplication] delegate]).socketDealer signUpForEvent:@"getRequestedGeofencesForUserUUID" sender:self withSelector:@selector(updateAllRequestedGeofences:)];
}
- (void) unRegisterTrackerForGeofences
{
	[((AppDelegate*)[[UIApplication sharedApplication] delegate]).socketDealer resignEvent:@"getGeofencesForUserUUID" sender:self];
	[((AppDelegate*)[[UIApplication sharedApplication] delegate]).socketDealer resignEvent:@"getRequestedGeofencesForUserUUID" sender:self];
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSString* userUUID = [defaults valueForKey:userUUIDDefaultsURL];
	[((AppDelegate*)[[UIApplication sharedApplication] delegate]).socketDealer resignDataUpdatesWithInfo: @{@"id" : userUUID, @"field" : @"geofences"} sender:self];
	[((AppDelegate*)[[UIApplication sharedApplication] delegate]).socketDealer resignDataUpdatesWithInfo: @{@"id" : userUUID, @"field" : @"requestedGeofences"} sender:self];
}
- (void) fetchAllGeofences
{
	//Fetch only after a while to ensure that if we sent over stuff to the server, we fetch the new info, not old.
	//[NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(dummySelector3) userInfo:nil repeats:NO];
	[self dummySelector3];
}
- (void) dummySelector3
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSString* userUUID = [defaults valueForKey:userUUIDDefaultsURL];
	[((AppDelegate*)[[UIApplication sharedApplication] delegate]).socketDealer sendEvent:@"/itrack/getgeofencesforuseruuid" withData:@{@"userUUID":userUUID}];
}

- (void) fetchAllRequestedGeofences
{
	//[NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(dummySelector4) userInfo:nil repeats:NO];
	[self dummySelector4];
}
- (void) dummySelector4
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSString* userUUID = [defaults valueForKey:userUUIDDefaultsURL];
	[((AppDelegate*)[[UIApplication sharedApplication] delegate]).socketDealer sendEvent:@"/itrack/getrequestedgeofencesforuseruuid" withData:@{@"userUUID":userUUID}];
}

- (void) updateAllGeofences:(NSNotification*)notification
{
	NSDictionary* desc = [notification userInfo];
	NSMutableDictionary* geofences = @{}.mutableCopy;
	NSArray* rows = [desc objectForKey:@"rows"];
	for(NSDictionary* dic in rows)
	{
		NSObject* doc = [dic valueForKey:@"doc"];
		if([doc isEqual:[NSNull null]])continue;
		[geofences setObject:[dic objectForKey:@"doc"] forKey:[[dic objectForKey:@"doc"] objectForKey:@"userKnownIdentifier"]];
	}
	
	[self updateAGeofenceSet:geofences mode:NO];
	
	
}

- (void) updateAllRequestedGeofences:(NSNotification*)notification
{
	NSDictionary* desc = [notification userInfo];
	NSMutableDictionary* geofences = @{}.mutableCopy;
	NSArray* rows = [desc objectForKey:@"rows"];
	for(NSDictionary* dic in rows)
	{
		if(![dic valueForKey:@"doc"] || [[dic valueForKey:@"doc"] isEqual:[NSNull null]])continue;
		[geofences setObject:[dic objectForKey:@"doc"] forKey:[[dic objectForKey:@"doc"] objectForKey:@"userKnownIdentifier"]];
	}
	
	[self updateAGeofenceSet:geofences mode:YES];
	
	
}


- (void) updateAGeofenceSet:(NSMutableDictionary*)geofences mode:(BOOL)mode
{
	//mode: 0 = normal, 1 = requested
	NSArray* allGeofences = [self.fetchedResultsController fetchedObjects];
	
	BOOL needToSave = NO;
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSString* username = [defaults valueForKey:usernameDefaultsURL];
	for(Geofence* fence in allGeofences)
	{
		if([fence.owner isEqualToString:username] == mode)continue;
		NSDictionary* serverVersion = [geofences objectForKey:fence.identifier];
		
		
		if(!serverVersion)
		{
			[self deleteFence:fence notifyServer:NO];
			needToSave = NO;//Delete fence already ran a save - reset needToSave
			continue;
		}
		
		//if there is a server version:
		[geofences removeObjectForKey:fence.identifier];//after we check this, no need for it to stay in geofences.
		
		
		//check if there where any changes
		//reason we check for changes instead of outright automatically replacing data and saving is b/c every save causes map to reload - don't wanna do extra reloads and disturb user if many geofences weren't updated
		
		BOOL a = [fence.owner isEqualToString:[serverVersion objectForKey:@"owner"]];
		BOOL b = ([fence.requester isEqualToString:[serverVersion objectForKey:@"requestedBy"]]||([[serverVersion objectForKey:@"requestedBy"] isEqualToString:@"" ] && fence.requester == nil));
		BOOL c = [fence.requestApproved isEqualToString:[serverVersion objectForKey:@"requestApproved"]];
		BOOL d = [fence.leaveMessage isEqualToString:[serverVersion objectForKey:@"leaveMessage"]];
		BOOL e = [fence.arrivalMessage isEqualToString:[serverVersion objectForKey:@"arrivalMessage"]];
		BOOL f = [fence.setting isEqualToNumber:[NSNumber numberWithInt:[self stringToSettingInt:[serverVersion objectForKey:@"status"]]]];
		BOOL g = [fence.recur isEqualToNumber:[serverVersion objectForKey:@"repeat"]];
		BOOL h = [fence.radius isEqualToNumber:[serverVersion objectForKey:@"radius"]];
		BOOL i = [fence.recipients isEqualToData:[NSKeyedArchiver archivedDataWithRootObject:[serverVersion objectForKey:@"recs"]]];
		BOOL j = [fence.leavesSent isEqualToData:[NSKeyedArchiver archivedDataWithRootObject:[serverVersion objectForKey:@"leavesSent"]]];
		BOOL k = [fence.arrivalsSent isEqualToData:[NSKeyedArchiver archivedDataWithRootObject:[serverVersion objectForKey:@"arrivalsSent"]]];
		BOOL l = [fence.onArrival isEqualToNumber:[serverVersion objectForKey:@"onArrival"]];
		BOOL m = [fence.onLeave isEqualToNumber:[serverVersion objectForKey:@"onLeave"]];
		BOOL n = [fence.longtitude isEqualToNumber:[NSNumber numberWithFloat:[[serverVersion objectForKey:@"long"] floatValue]]];
		BOOL o = [fence.lat isEqualToNumber:[NSNumber numberWithFloat:[[serverVersion objectForKey:@"lat"] floatValue]]];
		BOOL p =[fence.address isEqualToString:[serverVersion objectForKey:@"address"]];
		
		if(!(p
			 &&
			 o
			 &&
			 n
			 &&
			 l
			 &&
			 m
			 &&
			 k
			 &&
			 j
			 &&
			 i
			 &&
			 h
			 &&
			 g
			 &&
			 f
			 &&
			 e
			 &&
			 d
			 &&
			 a
			 &&
			 b
			 &&
			 c
			 ))
		{
			//means at least 1 thing changed:
			
			[self setFencePropertiesToMatchDic:fence withDic:serverVersion];
			needToSave = YES;
		}
	}
	
	//if anything left in server response, create new fences with it:
	
	for(NSString* key in geofences)
	{
		NSDictionary* fenceDic = [geofences objectForKey:key];
		
		[self addFenceWithLong:[[fenceDic objectForKey:@"long"]floatValue] lat:[[fenceDic objectForKey:@"lat"]floatValue] recurr:[[fenceDic valueForKey:@"repeat"]floatValue] recipients:[fenceDic objectForKey:@"recs"] address:[fenceDic objectForKey:@"address"] radius:[[fenceDic objectForKey:@"radius"]integerValue] givenFence:nil arrival:[[fenceDic objectForKey:@"onArrival"]boolValue] leave:[[fenceDic objectForKey:@"onLeave"]boolValue] shouldChangeMapSetting:NO optionalIdentifier:[fenceDic objectForKey:@"userKnownIdentifier"] arrivalMessage:[fenceDic objectForKey:@"arrivalMessage"] leaveMessage:[fenceDic objectForKey:@"leaveMessage"] arrivalsSent:[fenceDic objectForKey:@"arrivalsSent"] leavesSent:[fenceDic objectForKey:@"leavesSent"] forceSave:YES optionalSetSetting:[NSNumber numberWithInt:[self stringToSettingInt:[fenceDic objectForKey:@"status"]]] owner:[fenceDic objectForKey:@"owner"] requester:[fenceDic objectForKey:@"requestedBy"] optionalRequestApproved:[fenceDic valueForKey:@"requestApproved"] fenceWasSyncedDownFromServer:YES];
		needToSave = YES;
		
	}
	
	if(needToSave){
		[self save];
	}

}


- (void) moveSearchBarPin:(UIPanGestureRecognizer*)pan
{
    MapPinView* pinView = self.searchBarPinBox.subviews[0];
    CGPoint currentLocation = [pan locationInView:self.searchBarPinBox];
    pinView.frame = CGRectMake(currentLocation.x, currentLocation.y, pinView.frame.size.width, pinView.frame.size.height);
    
    if(pan.state == UIGestureRecognizerStateEnded)
    {
        CGRect prevFrame = pinView.frame;
        pinView.frame = CGRectMake((self.searchBarPinBox.frame.size.width-prevFrame.size.width)/2, (self.searchBarPinBox.frame.size.height-prevFrame.size.height)/2, prevFrame.size.width, prevFrame.size.height);
        CLLocationCoordinate2D leavePoint = [self.mapView convertPoint:currentLocation toCoordinateFromView:self.searchBarPinBox];
        MapPin* annotation = [[MapPin alloc] initWithCoordinates:leavePoint placeName:@"" description:@"" mapVC:self];
        
        if(self.currentlyDraggedAnnotation)
        {
            [self.additionalAnnotationsToShow removeObject:self.currentlyDraggedAnnotation];
        }
        self.currentlyDraggedAnnotation = annotation;
        [self.additionalAnnotationsToShow addObject:annotation];
        
        annotation.setting = [NSNumber numberWithInt:kSearch];
        [self setSetting:kSearch on:YES forceAnnotationUpdate:NO];
        annotation.blockToRunOnceAddressUpdates = ^void(UIViewController* mapVC, MapPin* annotation)
        {
            [((mapViewController*)mapVC).mapView selectAnnotation:annotation animated:YES];
        };
        [annotation setCoordinate:leavePoint];//causes everything to load
        
		[self updateMapAnnotaions];
    }
}

- (NSMutableArray*)additionalAnnotationsToShow
{
    if(!_additionalAnnotationsToShow)
    {
        _additionalAnnotationsToShow = [[NSMutableArray alloc] init];
    }
    return _additionalAnnotationsToShow;
}


- (void) closeKeyboard
{
    [self.view endEditing:YES];
}



- (void) requestStatusForAllMonitoredRegions
{
/*Method is currently disabled.
    NSSet* regions = self.locationManager.monitoredRegions;
    for(CLRegion* region in regions)
    {
        [self.locationManager requestStateForRegion:region];
    }*/
    
}

- (void) locationManager:(CLLocationManager *)manager didStartMonitoringForRegion:(CLRegion *)region
{
	//give it 2 seconds before doing anything. This is to make sure the server has time to react and
	//get the new geofence changes, incase a message must be fired immedietally (the server must first
	//know of the existance of the geofence before sending messages for it)
	[NSTimer
	 scheduledTimerWithTimeInterval:2.0 target:self selector:@selector(dummySelector:) userInfo:region repeats:NO];
	
	
}

- (void) dummySelector:(NSTimer*)timer
{
	CLRegion* region = [timer userInfo];
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
    
    if([fence.setting isEqualToNumber:[NSNumber numberWithInt:kActive]] && [self fenceTimeoutOK:fence withCode:0]
	   &&
	   fence.onArrival)
    {
        
        [self hitFence:fence mode:YES];
        
    }
    
    
    
}
- (void) locationManager:(CLLocationManager *)manager didExitRegion:(CLRegion *)region
{
	Geofence* fence = [self getFenceFromRegion:region];
	if(!fence)//if for some reason we recieved "didEnterRegion", but we are not looking to track that region, just remove it from monitoring
	{
		[self.locationManager stopMonitoringForRegion:region];
		return;
	}
	
	//check fence active && whether to expire:
	
	if([fence.setting isEqualToNumber:[NSNumber numberWithInt:kActive]] && [self fenceTimeoutOK:fence withCode:1]
	   &&
	   fence.onLeave)
	{
		
		[self hitFence:fence mode:NO];
		
	}

}
- (void) locationManager:(CLLocationManager *)manager didDetermineState:(CLRegionState)state forRegion:(CLRegion *)region
{
    if(state == CLRegionStateInside)
    {
        [self locationManager:manager didEnterRegion:region];
    }
    else if(state == CLRegionStateOutside)
    {
        [self locationManager:manager didExitRegion:region];
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

- (void) hitFence:(Geofence*)fence mode:(BOOL)isArrival
{
    
    if([fence.setting isEqualToNumber:[NSNumber numberWithInt:kActive]]
	   &&
	   (isArrival ? [fence.onArrival boolValue] : [fence.onLeave boolValue])
	   ){//check again, even though it was supposed to be checked, because we are accessing async so 2 threads could have entered this method with same region being tracked (e.g. 1 from delegate method "didDetermineState" and other from "didEnterRegion"
		
		//first send the message, then wait a while to allow the server to finish processing the message sending request, and only then have it mark the fence as completed. Otherwise, the fence might be marked completed before the server sends the message, and that will block the server from sending the message!
		[self sendMessageWithFence:fence mode:isArrival];
		[NSTimer
		 scheduledTimerWithTimeInterval:2.0 target:self selector:@selector(dummySelector2:) userInfo:fence repeats:NO];
		
	}
	
}

- (void) dummySelector2:(NSTimer*)timer
{
	Geofence* fence = [timer userInfo];
	[self setFenceCompleted:fence];
}

- (void) sendMessageWithFence:(Geofence*)fence mode:(BOOL)isArrival
{
	dispatch_queue_t q = dispatch_queue_create("Q8", NULL);
	dispatch_async(q, ^{
		
		NSURL *url = [NSURL URLWithString:@"http://dean-leitersdorf.herokuapp.com/itrack/sendfencemessage"];
		NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:url];
		
		
		NSDictionary* thisMessage = @{@"userKnownIdentifier":fence.identifier, @"lat":fence.lat, @"long":fence.longtitude, @"mode":[NSNumber numberWithBool:isArrival]};
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
		localNotification.alertBody = success ? [NSString stringWithFormat:@"Sent message successfully!"] : [NSString stringWithFormat:@"Failed to send message."];
		localNotification.soundName = UILocalNotificationDefaultSoundName;
		localNotification.applicationIconBadgeNumber = 1;
		[[UIApplication sharedApplication] scheduleLocalNotification:localNotification];
	});

}

/*
- (void) sendMessageTo:(NSNumber*)rec address:(NSString*)address
{
    dispatch_queue_t q = dispatch_queue_create("Q5", NULL);
    dispatch_async(q, ^{
        
        NSURL *url = [NSURL URLWithString:@"http://dean-leitersdorf.herokuapp.com/sendmessage"];
        NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:url];
        
        NSString* message = [NSString stringWithFormat: @"You have been notified that ___ arrived at: %@.", address];
        NSDictionary* thisMessage = @{@"number":rec, @"message":message};
        NSString *messageBody = [NSString stringWithFormat:@"number=%@&message=%@",rec, message];
        NSData* dataToSend = [messageBody dataUsingEncoding:NSUTF8StringEncoding];
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
    
}*/

- (BOOL) fenceTimeoutOK:(Geofence*)fence withCode:(int)code
{
    //code: 0 = arrival, !0 = leave;
    //retval: BOOL ok to proceed (YES = timeout has passed, NO = still waiting on cooldown
    /*
#define timeout 30.0 //seconds
    
    NSMutableArray* useArray;
    
    if(!code)//arrival
    {
        useArray = ((NSArray*) [NSKeyedUnarchiver unarchiveObjectWithData:fence.arrivalsSent] ).mutableCopy;
    }
    else
    {
        useArray = ((NSArray*)[NSKeyedUnarchiver unarchiveObjectWithData:fence.leavesSent]).mutableCopy;
    }
    
    BOOL retval;
    
    if(![useArray count])
        retval = YES;
    else
    {
        NSSortDescriptor *lowestToHighest = [NSSortDescriptor sortDescriptorWithKey:@"self" ascending:YES];
        [useArray sortedArrayUsingDescriptors:@[lowestToHighest]];
        
        float currentTime = [[NSDate date] timeIntervalSince1970];
        float timedif = currentTime - [useArray[0] floatValue];
        retval = timedif >=timeout;
    }*/
    /*
    if(retval)//add entry to log
    {
        if(!useArray)
        {
            useArray = [[NSMutableArray alloc] init];
        }
        
        [useArray addObject:[NSNumber numberWithFloat:[[NSDate date] timeIntervalSince1970]]];
        if(!code)//arrival
        {
            fence.arrivalsSent = [NSKeyedArchiver archivedDataWithRootObject:useArray];
        }
        else
        {
            fence.leavesSent = [NSKeyedArchiver archivedDataWithRootObject:useArray];
        }
        [self save];
    }*/
    
	return true;//retval;
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

- (void) addFenceWithLong:(float)longtitude lat:(float)lat recurr:(float)recurr recipients:(NSArray*)recs address:(NSString*)address radius:(NSInteger)radius givenFence:(Geofence *)fence arrival:(BOOL)arrival leave:(BOOL)leave shouldChangeMapSetting:(BOOL)settingChange optionalIdentifier:(NSString*)identifier arrivalMessage:(NSString*) arrivalMessage leaveMessage:(NSString*)leaveMessage arrivalsSent:(NSArray*)arrivalsSent leavesSent:(NSArray*)leavesSent forceSave:(BOOL)forceSave optionalSetSetting:(NSNumber*)setting owner:(NSString*)owner requester:(NSString*)requester optionalRequestApproved:(NSString*)requestApproved fenceWasSyncedDownFromServer:(BOOL)syncDown{
    NSManagedObjectContext *context = [self.fetchedResultsController managedObjectContext];
	BOOL shouldLaterCreateNewFenceOnServer = !fence;
    if(!fence)//a given fence would mean "Update" the fence. If no given fence, "Create" the fence.
		fence = [NSEntityDescription insertNewObjectForEntityForName:@"Geofence"inManagedObjectContext:context];
    
    fence.longtitude = [NSNumber numberWithFloat:longtitude];
    fence.lat = [NSNumber numberWithFloat:lat];
    fence.recur = [NSNumber numberWithFloat:recurr];
	
	recs = [mapViewController personsToDics:recs.mutableCopy];
	
    fence.recipients = [NSKeyedArchiver archivedDataWithRootObject:recs];
    if(!fence.identifier)
		fence.identifier = identifier ? identifier :[self randomStringWithLength:30];
    fence.address = address;
    fence.radius = [NSNumber numberWithInteger:radius];
    fence.onArrival = [NSNumber numberWithBool:arrival];
    fence.onLeave = [NSNumber numberWithBool:leave];
	fence.arrivalsSent = [NSKeyedArchiver archivedDataWithRootObject:arrivalsSent?arrivalsSent: [[NSMutableArray alloc] init]];
	fence.leavesSent = [NSKeyedArchiver archivedDataWithRootObject: leavesSent ? leavesSent : [[NSMutableArray alloc] init]];
	fence.arrivalMessage = arrivalMessage?arrivalMessage: @"I have arrived!";
	fence.leaveMessage = leaveMessage ? leaveMessage: @"I have left!";
	fence.owner = owner;
	fence.requester = (requester && ![requester isEqualToString:@""])?requester:fence.requester;//requester isn't always yourself - if loading a requested pin, the requester is someone else
	if(setting)
	{
		fence.setting = setting;
	}
	
	if(requestApproved)
		fence.requestApproved = requestApproved;
	else
		fence.requestApproved = (requester && ![requester isEqualToString:@""])? @"Pending" : @"N/A";
	
    if(settingChange){
        fence.setting = [NSNumber numberWithInt:kActive];
    [self setSetting:kSearch on:NO forceAnnotationUpdate:NO];
    [self setSetting:kAll on:YES forceAnnotationUpdate:NO];//set ALL to be on
    }
	if(forceSave)
		[self save];
    //No need to updateMapAnnotations/trackers - when save changes context, updateMapAnnotations/trackers already get called.
    //[self updateMapAnnotaions];
    //[self updateTrackers];
	
	//send update to server:
	
	
	if(shouldLaterCreateNewFenceOnServer && !syncDown)//shouldLater.. is "edit", syncDown is we just got this fence off the server - dont create a new one -_-
	{
		NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
		NSString* userUUID = [defaults valueForKey:userUUIDDefaultsURL];
		if(requester)//means we are requesting
		{
			[((AppDelegate*)[[UIApplication sharedApplication] delegate]).socketDealer sendEvent:@"/itrack/requestgeofence" withData:@{@"owner":owner, @"arrivalMessage":fence.arrivalMessage, @"leaveMessage":fence.leaveMessage, @"lat":fence.lat, @"long":fence.longtitude, @"onArrival":fence.onArrival, @"onLeave":fence.onLeave, @"radius":fence.radius, @"requester":userUUID, @"repeat":fence.recur, @"address":fence.address, @"userKnownIdentifier":fence.identifier}];
		}
		else{
		
			[((AppDelegate*)[[UIApplication sharedApplication] delegate]).socketDealer sendEvent:@"/itrack/creategeofence" withData:@{@"owner":userUUID, @"arrivalMessage":fence.arrivalMessage, @"leaveMessage":fence.leaveMessage, @"lat":fence.lat, @"long":fence.longtitude, @"onArrival":fence.onArrival, @"onLeave":fence.onLeave, @"radius":fence.radius, @"recs":recs, @"repeat":fence.recur, @"address":fence.address, @"userKnownIdentifier":fence.identifier}];}
	}
	
}


- (void) prepareServerForCoreData
{
	[[NSNotificationCenter defaultCenter]
	 addObserver:self
	 selector:@selector(handleDataModelChange:)
	 name:NSManagedObjectContextDidSaveNotification
	 object:[self.fetchedResultsController managedObjectContext]];
}

- (void)handleDataModelChange:(NSNotification *)note
{
	NSSet *updatedObjects = [[note userInfo] objectForKey:NSUpdatedObjectsKey];
	
	//NSSet *deletedObjects = [[note userInfo] objectForKey:NSDeletedObjectsKey];
	//NSSet *insertedObjects = [[note userInfo] objectForKey:NSInsertedObjectsKey];
	
	
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSString* username = [defaults valueForKey:usernameDefaultsURL];
	NSString* userUUID = [defaults valueForKey:userUUIDDefaultsURL];
	
	for(NSManagedObject* obj in updatedObjects)
	{
		if([obj isKindOfClass:[Geofence class]])
		{
			Geofence* fence = (Geofence*)obj;
			BOOL amIOwner = [username isEqualToString:fence.owner];
			NSArray* recs =[mapViewController personsToDics:[mapViewController recsFromFenceData:fence.recipients].mutableCopy ];
			//send to server geofence edit:
			[((AppDelegate*)[[UIApplication sharedApplication] delegate]).socketDealer sendEvent:@"/itrack/editgeofence" withData:@{@"owner":amIOwner?userUUID:fence.owner, @"arrivalMessage":fence.arrivalMessage, @"leaveMessage":fence.leaveMessage, @"lat":fence.lat, @"long":fence.longtitude, @"onArrival":fence.onArrival, @"onLeave":fence.onLeave, @"radius":fence.radius, @"requester":amIOwner?(fence.requester?fence.requester:@""):userUUID, @"repeat":fence.recur, @"address":fence.address, @"userKnownIdentifier":fence.identifier, @"recs":(recs?recs:@[]) , @"status":[self settingIntToString:[fence.setting intValue]], @"amIOwner":[NSNumber numberWithBool:amIOwner]}];
		}
	}
	
	// Do something in response to this
}


- (void) deleteFence:(Geofence*) fence notifyServer:(BOOL)notify
{
	if(!fence)return;
    NSManagedObjectContext *context = [self.fetchedResultsController managedObjectContext];
    [context deleteObject:fence];
	
	if(notify)
	{	//notify server the fence is deleted
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSString* userUUID = [defaults valueForKey:userUUIDDefaultsURL];
		[((AppDelegate*)[[UIApplication sharedApplication] delegate]).socketDealer sendEvent:@"/itrack/deletegeofence" withData:@{@"userUUID":userUUID,  @"userKnownIdentifier":fence.identifier}];}

    [self save];
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

- (NSString*) settingIntToString:(int)setting
{
	switch (setting) {
		case kAll:
			return @"All";
			break;
			
		case kActive:
			return @"Active";
			break;
			
		case kCompleted:
			return @"Completed";
			break;
			
		case kExpired:
			return @"Expired";
			break;
			
		default:
			return @"Error";
	}

}

- (int) stringToSettingInt:(NSString*)string
{
	if([string isEqualToString:@"All"])
		return kAll;
	else if([string isEqualToString:@"Active"])
		return kActive;
	else if([string isEqualToString:@"Completed"])
		return kCompleted;
	else if ([string isEqualToString:@"Expired"])
		return kExpired;
	else
		return -1;
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
	[self dealWithSignificantLocationChanges];
	[self updateMapAnnotaions];
	[self updateTrackers];
	
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
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"identifier" ascending:NO];
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
	
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSString* username = [defaults valueForKey:usernameDefaultsURL];
    //Loop through geofences
    for(Geofence* fence in allGeofences)
    {
        if([allGeoMatchedToMonitored valueForKey:fence.identifier])//its already being tracked
        {
            continue;
        }
        
        if([fence.setting isEqualToNumber:[NSNumber numberWithInt:kActive]] && (!fence.requester || [fence.requester isEqualToString:@""] || [fence.requestApproved isEqualToString:@"Accepted"]) && [fence.owner isEqualToString:username]){
        
            [self startTrackingGeofence:fence];
        
        
        }
        
    }
    
    [self requestStatusForAllMonitoredRegions];
    [self dealWithSignificantLocationChanges];
}

/*
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
}*/
/*
- (BOOL) isCurrentTimeInFenceTimeBounds:(Geofence*)fence
{
    double start = [fence.timestampStart doubleValue];
    double end = [fence.timestampEnd doubleValue];
    double current = [[NSDate date] timeIntervalSince1970];
    
    return start <= current && end >= current;
}
*/
/*
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
*/
- (void) setFenceCompleted:(Geofence*)fence
{
    if([fence.recur intValue])
    {
        return;
    }
    
    fence.setting = [NSNumber numberWithInt:kCompleted];
    [self save];
    
}

- (void) startTrackingGeofence:(Geofence*)fence
{
    CLCircularRegion* region = [[CLCircularRegion alloc] initWithCenter:CLLocationCoordinate2DMake([fence.lat doubleValue], [fence.longtitude doubleValue]) radius:[fence.radius doubleValue] identifier:fence.identifier];
    region.notifyOnEntry = fence.onArrival;
    region.notifyOnExit = fence.onLeave;
    
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
    //[self updateMapAnnotaions];
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    /*[self dealWithSignificantLocationChanges];
    [self updateMapAnnotaions];
    [self updateTrackers];*/
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

-(void) searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
	[self lookupQuery:searchBar];
}

- (void) cancelSearch
{
	[self setSetting:kSearch on:NO forceAnnotationUpdate:self.searchAnnotations.count>0];//only force annotation update if there are searchAnnotations on the map!
	[self.searchAnnotations removeAllObjects];
	[self setSearchResultsViewVisible:NO];
}

- (void)searchBarTextDidEndEditing:(UISearchBar *)searchBar
{
    if([searchBar.text isEqualToString:@""])
    {
		[self cancelSearch];
		return;
    }
    
	[self lookupQuery:searchBar];
	
	
}

- (void) lookupQuery:(UISearchBar*)searchBar
{
	NSString* query = searchBar.text;
	if(![self.searchResultsCache objectForKey:query])
	{
		//[searchBar resignFirstResponder];
		CLGeocoder* geocoder = [[CLGeocoder alloc] init];
		[geocoder geocodeAddressString:query
					 completionHandler:^(NSArray* placemarks, NSError* error){
						 
						 //[self.searchAnnotations removeAllObjects];
						 NSMutableArray* annotations = [[NSMutableArray alloc] init];
						 
						 for (CLPlacemark* aPlacemark in placemarks)
						 {
							 self.mapView.centerCoordinate = aPlacemark.location.coordinate;
							 NSArray *lines = aPlacemark.addressDictionary[ @"FormattedAddressLines"];
							 NSString *addressString = [lines componentsJoinedByString:@"\n"];
							 MapPin* annotation = [[MapPin alloc] initWithCoordinates:aPlacemark.location.coordinate placeName:addressString description:addressString mapVC:self];
							 annotation.address = addressString;
							 annotation.setting = [NSNumber numberWithInt: kSearch];
							 [annotations addObject:annotation];
							 //[self.searchAnnotations addObject:annotation];
							 
						 }
						 [self.searchResultsCache setObject:annotations forKey:query];
						 //[self setSetting:kSearch on:YES forceAnnotationUpdate:YES];
						 self.lastestQuery = query;
					 }];
		
	}
	else
	{
		self.lastestQuery = query;
	}
}

- (void) setLastestQuery:(NSString *)lastestQuery
{
	if([lastestQuery isEqualToString:_lastestQuery])return;
	_lastestQuery = lastestQuery;
	[self.tableViewForSearchResults reloadData];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    [searchBar resignFirstResponder];
}

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar
{
	[self dismissWelcomeSign];
	[self setSearchResultsViewVisible:YES];
}

- (void) setSearchResultsViewVisible:(BOOL)visible
{
	[UIView animateWithDuration:.3 animations:^{
		if(visible)
		{
			if(CGRectIsEmpty(self.searchBarDefaultFrame))
			{
				self.searchBarDefaultFrame = self.searchBar.frame;
			}
			self.searchBar.frame = CGRectMake(8, self.searchBar.frame.origin.y, self.view.frame.size.width-16 - self.closeSearchButton.frame.size.width - 8, self.searchBar.frame.size.height);
		}
		else
		{
			self.searchBar.frame = self.searchBarDefaultFrame;
		}

		
		self.searchResultsView.alpha = visible;
		self.searchResultsView.userInteractionEnabled = visible;
		
		self.logoutButton.alpha = !visible;
		self.logoutButton.userInteractionEnabled = !visible;
		self.searchBarPinBox.alpha = !visible;
		self.searchBarPinBox.userInteractionEnabled = !visible;
		
		self.closeSearchButton.alpha = visible;
		self.closeSearchButton.userInteractionEnabled = visible;
		
		self.topBar.alpha = visible ? 1 : .9;
		self.topBar.backgroundColor = visible ? self.searchResultsView.backgroundColor : [UIColor whiteColor];
		
		UITextField *textField;
		UISearchBar* searchBar = self.searchBar;
		NSUInteger numViews = [searchBar.subviews count];
		for(int i = 0; i < numViews; i++) {
			if([self.searchBar.subviews[i] isKindOfClass:[UITextField class]]) {
				textField = [searchBar.subviews objectAtIndex:i];
				break;
			}
		}
		
		if(visible){
		if(!self.defaultSearchBarColor)
		{
			self.defaultSearchBarColor = textField.backgroundColor;
		}
			textField.backgroundColor = [UIColor whiteColor];
			self.searchBar.barTintColor = [UIColor whiteColor];
		}
		else
		{
			textField.backgroundColor = self.defaultSearchBarColor;
		}}
		];
	
}

- (NSMutableDictionary*)searchResultsCache
{
	if(!_searchResultsCache)
	{
		_searchResultsCache = [[NSMutableDictionary alloc] init];
	}
	return _searchResultsCache;
}

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	static NSString *cellIdentifier = @"searchCell";
	UITableViewCell * cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier forIndexPath:indexPath];

	MapPin* annotation = [self.searchResultsCache objectForKey:self.lastestQuery][indexPath.row];
	cell.textLabel.text = annotation.address;
	cell.selectionStyle = UITableViewCellSelectionStyleNone;
	return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return [[self.searchResultsCache objectForKey:self.lastestQuery] count];
}
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return 1;
}

- (BOOL) tableView:(UITableView *)tableView shouldHighlightRowAtIndexPath:(NSIndexPath *)indexPath
{
	return YES;
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	self.searchAnnotations  = @[[self.searchResultsCache objectForKey:self.lastestQuery][indexPath.row]].mutableCopy;
	[self setSetting:kSearch on:YES forceAnnotationUpdate:YES];
	[self setSearchResultsViewVisible:NO];
	[self.searchBar resignFirstResponder];
}

- (IBAction)closeSearchResults:(id)sender
{
	[self setSearchResultsViewVisible:NO];
	[self.searchBar resignFirstResponder];
}

#pragma mark Manage Map

//Delegate methods:

- (void) mapView:(MKMapView *)mapView didSelectAnnotationView:(MKAnnotationView *)view
{
    [mapView setCenterCoordinate:view.annotation.coordinate animated:YES];
    //1° Longitude = cos (33.1519) * 69.172 mi
    //1° of latitude = 69.172 miles
    MKCoordinateRegion region = MKCoordinateRegionMake(view.annotation.coordinate, MKCoordinateSpanMake(1/69.172, 1/(0.8372236*69.172)));
    [mapView setRegion:region animated:YES];
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

-(NSString*) writablePath {
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString *documentsDirectory = [paths objectAtIndex:0];
	return documentsDirectory;
}

- (MKAnnotationView*)mapView:(MKMapView *)mapView viewForAnnotation:(MapPin*)annotation
{
    
    // If the annotation is the user location, just return nil.
    if ([annotation isKindOfClass:[MKUserLocation class]])
        return nil;
    
    // Handle any custom annotations.
    if ([annotation isKindOfClass:[MapPin class]])
    {
        
        if(annotation.delegate)
            return (MapPinView*)annotation.delegate;
        
        MapPinView* pinView;
        pinView = [[MapPinView alloc] initWithAnnotation:annotation
                                                      reuseIdentifier:@"CustomPinAnnotationView"];
		if([annotation.fence.requestApproved isEqualToString:@"Pending"])
		{
			//pinView.image = [UIImage imageNamed:@"orangePin.png"];
			/*
			pinView.pinColor=MKPinAnnotationColorPurple;
			UIImage* image = nil;
			// 2.0 is for retina. Use 3.0 for iPhone6+, 1.0 for "classic" res.
			UIGraphicsBeginImageContextWithOptions(pinView.frame.size, NO, 2.0);
			[pinView.layer renderInContext: UIGraphicsGetCurrentContext()];
			image = UIGraphicsGetImageFromCurrentImageContext();
			UIGraphicsEndImageContext();
			NSData* imgData = UIImagePNGRepresentation(image);
			NSString* targetPath = [NSString stringWithFormat:@"%@/%@", [self writablePath], @"orangePin.png" ];
			[imgData writeToFile:targetPath atomically:YES];*/
			//from: http://stackoverflow.com/questions/1185611/mkpinannotationview-are-there-more-than-three-colors-available
			
			//Note: this is covering the normal green icon. See if you can replace it.
			UIImage * image = [UIImage imageNamed:@"orangePin.png"];
			UIImageView *imageView = [[UIImageView alloc] initWithImage:image];
			[pinView addSubview:imageView];
		}
		
		
        pinView.animatesDrop = YES;
        pinView.mapVC = self;
		pinView.draggable = [annotation.setting intValue]==kSearch;
        annotation.pinView = pinView;
		
		if(annotation == self.currentlyDraggedAnnotation)
		{
			[((MapPinView*)annotation.pinView) showToViewCancelButton];
		}
			
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
        
        pinView.annotation = annotation;
        annotation.delegate = pinView;
        [pinView updateCalloutView:true];
        
        return pinView;
    }
    
    return nil;
   
    
}

- (MKAnnotationView*) getMapAnnotationForGeofenceIdentifier:(NSString*)identifier orData:(NSDictionary*)data
{
	Geofence* fence;
	
	if(data){
		
		NSManagedObjectContext *context = [self.fetchedResultsController managedObjectContext];
		NSEntityDescription *entity = [NSEntityDescription entityForName:@"Geofence" inManagedObjectContext:context];
		fence = (Geofence*)[[NSManagedObject alloc] initWithEntity:entity insertIntoManagedObjectContext:nil];
		[self setFencePropertiesToMatchDic:fence withDic:data];
		
	}
	else{
	
	for(NSManagedObject* object in self.fetchedResultsController.fetchedObjects)
	{
		if([object isKindOfClass:[Geofence class]])
		{
			Geofence* testFence = (Geofence*)object;
			if([testFence.identifier isEqualToString: identifier])
			{
				fence = testFence;
				break;
			}
		}
	}}
	
	
	MapPin* pin = [self pinFromFence:fence];
	MapPinView* ret = (MapPinView*)[self mapView:self.mapView viewForAnnotation:pin];
	return ret;
}

- (Geofence*) setFencePropertiesToMatchDic:(Geofence*)fence withDic:(NSDictionary*)dic
{
	fence.address = [dic objectForKey:@"address"];
	fence.arrivalsSent =[NSKeyedArchiver archivedDataWithRootObject:[dic objectForKey:@"arrivalsSent"]];
	fence.lat =[dic objectForKey:@"lat"];
	fence.leavesSent =[NSKeyedArchiver archivedDataWithRootObject:[dic objectForKey:@"leavesSent"]];
	fence.longtitude =[dic objectForKey:@"long"];
	fence.onArrival =[dic objectForKey:@"onArrival"];
	fence.onLeave =[dic objectForKey:@"onLeave"];
	fence.radius =[dic objectForKey:@"radius"];
	
	NSArray* recs = [dic objectForKey:@"recs"];
	//recs = [mapViewController personsToDics:recs.mutableCopy]; -- recs here are from server and thus already in dic form
	fence.recipients = [NSKeyedArchiver archivedDataWithRootObject:recs];
	fence.recur =[dic objectForKey:@"repeat"];
	fence.setting =[NSNumber numberWithInt:[self stringToSettingInt:[dic objectForKey:@"status"]]];
	fence.arrivalMessage =[dic objectForKey:@"arrivalMessage"];
	fence.leaveMessage =[dic objectForKey:@"leaveMessage"];
	fence.owner = [dic objectForKey:@"owner"];
	fence.requester = [dic objectForKey:@"requestedBy"];
	fence.requestApproved = [dic objectForKey:@"requestApproved"];
	return fence;
}

+ (NSArray*) personsToDics:(NSMutableArray*)recs
{
	NSMutableArray* recsMutable = recs;
	for(int i = 0; i < recs.count; i++)
	{
		id rec = recsMutable[i];
		if([rec isKindOfClass:[Person class]])
		{
			rec = [((Person*)rec) dicForm];
		}
		recsMutable[i] = rec;
	}
	return recsMutable;
}

+ (NSArray*) dicsToPersons:(NSMutableArray*)recs
{
	NSMutableArray* recsMutable = recs;
	for(int i = 0; i < recs.count; i++)
	{
		id rec = recsMutable[i];
		if([rec isKindOfClass:[NSDictionary class]])
		{
			Person* p = [[Person alloc] init];
			[p setValuesForKeysWithDictionary:(NSDictionary*)rec];
			rec = p;
		}
		recsMutable[i] = rec;
	}
	return recsMutable;

}
+ (NSArray*) recsFromFenceData:(NSData*)data
{
	NSArray* recs = [NSKeyedUnarchiver unarchiveObjectWithData:data];
	recs = [mapViewController dicsToPersons:recs.mutableCopy];
	return recs;
}

- (void) mapView:(MKMapView *)mapView annotationView:(MKAnnotationView *)view didChangeDragState:(MKAnnotationViewDragState)newState fromOldState:(MKAnnotationViewDragState)oldState
{
    
}
- (void) setSearchBarShown:(BOOL)shown
{
    [self setButtonsShown:shown];
    [UIView animateWithDuration:0.1 animations:^{
        self.topBar.alpha = [[NSNumber numberWithBool:shown] doubleValue];
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
        annotationsToShow = self.searchAnnotations.mutableCopy;
    }
    else
    {
        NSArray* geofencesFromCoreData = self.fetchedResultsController.fetchedObjects;
        NSMutableArray* geofencesInAnnotationForm = [[NSMutableArray alloc] init];
		
		NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
		NSString* username = [defaults valueForKey:usernameDefaultsURL];
        
        for(Geofence* fence in geofencesFromCoreData)
        {
			if([fence.owner isEqualToString:username] != self.mode)
			{
				MapPin* pin = [self pinFromFence:fence];
				[geofencesInAnnotationForm addObject:pin];
			}
			
        }
		
        if([self.mapSettingEnums[kAll] boolValue])
        {
            annotationsToShow = geofencesInAnnotationForm.mutableCopy;
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
    
    [annotationsToShow addObjectsFromArray:self.additionalAnnotationsToShow];
    for(MapPin* pin in annotationsToShow)
    {
        [self.mapView addAnnotation:pin];
    }
    
    [self zoomToAnnotationsBounds];
	if(isSearch && self.searchAnnotations.count ==1)//directly open that one
	{
		[self.mapView selectAnnotation:self.searchAnnotations[0] animated:YES];
	}
}

- (MapPin*) pinFromFence:(Geofence*)fence
{
	MapPin* pin = [[MapPin alloc] initWithCoordinates:CLLocationCoordinate2DMake([fence.lat doubleValue], [fence.longtitude doubleValue]) placeName:fence.address description:fence.address mapVC:self];
	pin.address = fence.address;
	pin.setting = fence.setting;
	pin.fence = fence;

	return pin;
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

- (IBAction)zoomout:(id)sender
{
	[self dismissWelcomeSign];
    [self zoomToAnnotationsBounds];
}

- (void)zoomToFitMapAnnotations:(MKMapView *)theMapView {
    if ([theMapView.annotations count] == 0) return;
	
	[theMapView showAnnotations:self.mapView.annotations animated:YES];
	for(MapPin* pin in self.mapView.annotations)
	{
		[self.mapView deselectAnnotation:pin animated:YES];
	}
	return;
    
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
	
	if(region.center.latitude == -180.00 || region.center.longitude == -180.00)
	{
		NSLog(@"invalid region");
		return;
	}
    [theMapView setRegion:region animated:YES];
}

//Mode Setting
- (IBAction)toggleMode:(id)sender
{
	[self dismissWelcomeSign];
	self.mode = !self.mode;
}

- (void) setMode:(BOOL)mode
{
	if(_mode==mode)return;
	
	_mode = mode;
	[self.modeButton setTitle:mode?@"Requesting Mode":@"Sending Mode" forState:UIControlStateNormal];
	[self updateMapAnnotaions];
}
- (IBAction)logoutClicked:(id)sender
{
	[self dismissWelcomeSign];
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:@"Log out of app?"
                                                             delegate:self
                                                    cancelButtonTitle:@"Cancel"
                                               destructiveButtonTitle:@"Logout"
                                                    otherButtonTitles: nil];
	actionSheet.tag = 20;
	[actionSheet showInView:self.view];

}

-(void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex{
	if (actionSheet.tag == 20) {
		if([[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:@"Logout"])
		{
			[self logout];
		}
	}
}
- (void) logout
{
	[self removeAllGeofences];
	[self ensureNotTrackingAnyFence];
	self.updateCaretaker = nil;
	[self unRegisterTrackerForGeofences];
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	[defaults setObject:nil forKey:userUUIDDefaultsURL];
	[defaults setObject:nil forKey:usernameDefaultsURL];
	[defaults synchronize];
	[self removeWelcomeSign];
	
	[self dealWithLogin];

}
- (void) removeAllGeofences
{
	for(Geofence* fence in self.fetchedResultsController.fetchedObjects)
	{
		[self deleteFence:fence notifyServer:NO];
	}
}
- (void) ensureNotTrackingAnyFence
{
	NSSet* regions = self.locationManager.monitoredRegions;
	for(CLRegion* region in regions)
	{
		[self.locationManager stopMonitoringForRegion:region];
	}
}
- (void) destoryDraggedSearchPin
{
	
	[self.additionalAnnotationsToShow removeObject:self.currentlyDraggedAnnotation];
	self.currentlyDraggedAnnotation = nil;
	[self setSetting:kSearch on:NO forceAnnotationUpdate:YES];
}


@end
