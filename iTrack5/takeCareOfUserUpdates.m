//
//  takeCareOfUserUpdates.m
//  iTrack5
//
//  Created by Dean Leitersdorf on 4/12/15.
//  Copyright (c) 2015 Dean Leitersdorf. All rights reserved.
//

#import "takeCareOfUserUpdates.h"
#import "AppDelegate.h"
#import "socketDealer.h"
#import "geofenceRequestedPopup.h"
#import "geofenceDeletedByOwner.h"
#import "geofenceAccepted.h"

@implementation takeCareOfUserUpdates

- (instancetype) init
{
	self = [super init];
	if(self)
	{
		[self signUpForUserUpdates];
		[self launchRequest];
		[self dealUpdates];
	}
	
	return self;
}

- (void) signUpForUserUpdates
{
	//sign up to get the updates:
	[((AppDelegate*)[[UIApplication sharedApplication] delegate]).socketDealer signUpForEvent:@"getUpdatesForUser" sender:self withSelector:@selector(updatesRecieved:)];
	
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSString* userUUID = [defaults valueForKey:userUUIDDefaultsURL];
	
	//sign up to get the tracker updates:
	[((AppDelegate*)[[UIApplication sharedApplication] delegate]).socketDealer signUpForDataWithInfo:@{@"id" : userUUID, @"field" : @"updates"} sender:self withSelector:@selector(launchRequest)];
	
}
- (void) removeUpdates{
	[((AppDelegate*)[[UIApplication sharedApplication] delegate]).socketDealer resignEvent:@"getUpdatesForUser" sender:self];
	
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSString* userUUID = [defaults valueForKey:userUUIDDefaultsURL];
	[((AppDelegate*)[[UIApplication sharedApplication] delegate]).socketDealer resignDataUpdatesWithInfo:@{@"id" : userUUID, @"field" : @"updates"} sender:self];
}
- (void) dealloc
{
	[self removeUpdates];
}

- (void) launchRequest
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSString* userUUID = [defaults valueForKey:userUUIDDefaultsURL];
	[((AppDelegate*)[[UIApplication sharedApplication] delegate]).socketDealer sendEvent:@"/itrack/getupdatesforuser" withData:@{@"userUUID":userUUID}];
}


/*
 *
 * Applicable updates:
 * -deletedGeofenceByOwner
 * -deletedGeofenceByRequester
 * -requestedGeofence
 * -requestedGeofenceAccepted
 * -requestedGeofenceDeclined
 * -requesterChangedFence
 * -ownerChangedFence
 *
 */
- (NSMutableDictionary*)updates
{
	if(!_updates)
	{
		_updates = @{}.mutableCopy;
	}
	return _updates;
}

- (NSMutableArray*)updatesDealtWith
{
	if(!_updatesDealtWith)
	{
		_updatesDealtWith = @[].mutableCopy;
	}
	return _updatesDealtWith;
}

- (void) updatesRecieved:(NSNotification*)notification
{
	NSDictionary* desc = [notification userInfo];
	NSDictionary* updates = [desc valueForKey:@"updates"];
	for(NSString* key in updates)
	{
		if([self.updatesDealtWith containsObject:key])continue;
		[self.updates setObject:[updates objectForKey:key] forKey:key];
	}
	
	[self dealUpdates];
}

- (void) dealUpdates
{
	if(self.currentPopup || self.updates.count==0)return;
	
	NSString* key = self.updates.allKeys[0];//get first update
	NSDictionary* update = [self.updates objectForKey:key];
	[self.updatesDealtWith addObject:key];
	[self.updates removeObjectForKey:key];
	
	NSString* updateName = [update objectForKey:@"updateName"];
	
	
	updateDealerPopup* popup;
	
	if([updateName isEqualToString: @"requestedGeofence"])
	{
		popup = [[geofenceRequestedPopup alloc] initWithFrame:[geofenceRequestedPopup presentFrameWithMapVC:self.mapVC]];
		
		self.mapVC.mode = NO;//go to normal mode in order for user to see newly requested pin
		
		
	}
	else if ([updateName isEqualToString:@"deletedGeofenceByRequester"])
	{
		popup = [[geofenceDeletedByOwner alloc] initWithFrame:[geofenceDeletedByOwner presentFrameWithMapVC:self.mapVC]];
		
		((geofenceDeletedByOwner*)popup).messageLabel.text = @"USERNAME has deleted the location notification they asked of you.";
		
		self.mapVC.mode = NO;//go to normal mode in order for user to see no more pin

	}
	else if([updateName isEqualToString:@"deletedGeofenceByOwner"])
	{
		popup = [[geofenceDeletedByOwner alloc] initWithFrame:[geofenceDeletedByOwner presentFrameWithMapVC:self.mapVC]];
		
		self.mapVC.mode = YES;//go to requesting mode in order for user to see lack of pin
	}
	else if([updateName isEqualToString:@"requestedGeofenceAccepted"])
	{
		[self.mapVC fetchAllRequestedGeofences];
		
		popup = [[geofenceAccepted alloc] initWithFrame:[geofenceAccepted presentFrameWithMapVC:self.mapVC]];
		
		self.mapVC.mode = YES;//go to req mode in order for user to see newly accepted pin
		
	}
	else if([updateName isEqualToString:@"requestedGeofenceDeclined"])
	{
		[self.mapVC fetchAllRequestedGeofences];//incase the fence changes while user is online.
		
		popup = [[geofenceAccepted alloc] initWithFrame:[geofenceAccepted presentFrameWithMapVC:self.mapVC]];
		((geofenceAccepted*)popup).messageLabel.text = [((geofenceAccepted*)popup).messageLabel.text stringByReplacingOccurrencesOfString:@"accepted" withString:@"declined"];
		
		((geofenceAccepted*)popup).titleLabel.text = @"Request Declined";
		
		self.mapVC.mode = YES;//go to req mode in order for user to see lack of requested pin

	}
	else if([updateName isEqualToString:@"requesterChangedFence"])
	{
		[self.mapVC fetchAllGeofences];
		
		popup = [[geofenceRequestedPopup alloc] initWithFrame:[geofenceRequestedPopup presentFrameWithMapVC:self.mapVC]];		((geofenceRequestedPopup*)popup).messageLabel.text = [NSString stringWithFormat:@"%@ edited the location notification they asked you for. Please review the new location notification!", [update valueForKey:@"changedBy"]];
		
		((geofenceRequestedPopup*)popup).titleLabel.text = @"Request Modified";
		
		self.mapVC.mode = NO;
	}
	else if([updateName isEqualToString:@"ownerChangedFence"])
	{
		[self.mapVC fetchAllRequestedGeofences];
		
		popup = [[geofenceAccepted alloc] initWithFrame:[geofenceAccepted presentFrameWithMapVC:self.mapVC]];
		((geofenceAccepted*)popup).messageLabel.text =
		[NSString stringWithFormat:@"%@ edited the location notification you asked them for. Please see the new location notification!", [update valueForKey:@"changedBy"]];

		((geofenceAccepted*)popup).titleLabel.text = @"Request Modified";
		
		self.mapVC.mode = YES;
	}
	if(!popup){
		[self dealUpdates];//that update was useless, call ourselves again to try to get the next update
		return;}
	
	
	popup.delegate = self;
	popup.updateID = key;//key is updateID
	popup.mapVC = self.mapVC;
	popup.updateData = update;
	
	
	[popup present];
	self.currentPopup = popup;
	
}

- (void) finishedWithUpdate:(NSString *)updateID
{
	
	//send to server to remove updateID
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSString* userUUID = [defaults valueForKey:userUUIDDefaultsURL];
	[((AppDelegate*)[[UIApplication sharedApplication] delegate]).socketDealer sendEvent:@"/itrack/dismissupdateforuser" withData:@{@"userUUID":userUUID, @"updateID":updateID}];
	
	[self dismissCurrentPopup];

	
}

- (void)couldNotResolveUpdate:(NSString *)updateID
{
	[self dismissCurrentPopup];
}

- (void) dismissCurrentPopup
{
	[self.currentPopup dismiss];
	self.currentPopup = nil;
	[self dealUpdates];
}

@end
