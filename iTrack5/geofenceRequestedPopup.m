//
//  geofenceRequestedPopup.m
//  iTrack5
//
//  Created by Dean Leitersdorf on 4/12/15.
//  Copyright (c) 2015 Dean Leitersdorf. All rights reserved.
//

#import "geofenceRequestedPopup.h"
#import "MapPinView.h"
#import "mapViewController.h"
#import "Geofence.h"
#import "customCalloutView.h"
#import "AppDelegate.h"
#import "socketDealer.h"

@implementation geofenceRequestedPopup


- (instancetype) initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if(self)
    {
        
        [[NSBundle mainBundle] loadNibNamed:@"geofenceRequestedPopup" owner:self options:nil];
        
        self.frame = frame;
        self.view.frame = CGRectMake(0, 0, frame.size.width, frame.size.height);
        
        
        [self addSubview:self.view];
        
        
        
    }
    return self;
}


- (void) setUpdateData:(NSDictionary *)updateData
{
    [super setUpdateData:updateData];
	[self createGeofenceView];
	self.messageLabel.selectable = NO;//XCODE BUG! Read this: http://stackoverflow.com/questions/19049917/uitextview-font-is-being-reset-after-settext
	if([self.messageLabel.text containsString:@"USERNAME"]){
		self.messageLabel.text = [self.messageLabel.text stringByReplacingOccurrencesOfString:@"USERNAME" withString:[updateData valueForKey:@"requester"]];}
}

- (void) createGeofenceView
{
	MapPinView* pinView = (MapPinView*)[self.mapVC getMapAnnotationForGeofenceIdentifier:[[self.updateData valueForKey:@"geofence"] valueForKey:@"userKnownIdentifier"] orData:[self.updateData valueForKey:@"geofence"]];
	
	if(!pinView)
	{
		[self.delegate couldNotResolveUpdate:self.updateID];
		return;
	}
	//pinView.calloutView.frame = self.viewForGeofence.frame;
	
	//position the calloutView centered between the toolbar and the text bubble
	
	
	pinView.calloutView.pendingLabel.hidden = YES;//we know it's pending if its in this update... - better to show user the full address
	pinView.calloutView.userInteractionEnabled = NO;
	
	//self.messageLabel.backgroundColor = [UIColor orangeColor];
	[self.view addSubview:pinView.calloutView];
	pinView.calloutView.alpha = 1;
	[self.viewForGeofence removeFromSuperview];
	self.viewForGeofence = pinView.calloutView;
	
	customCalloutView* ccV = pinView.calloutView;
	CGPoint centerPoint = CGPointMake(self.view.center.x, self.messageLabel.frame.origin.y + self.messageLabel.frame.size.height + 8 + ccV.frame.size.height/2);
	CGRect ccVRect = CGRectMake(centerPoint.x - ccV.frame.size.width/2, centerPoint.y - ccV.frame.size.height/2, ccV.frame.size.width, ccV.frame.size.height);
	ccV.frame = ccVRect;
	//ccV.backgroundColor = [UIColor orangeColor];
	
	//now verify that we fit:
	int permittedHeight = self.frame.size.height - self.toolbar.frame.size.height - (self.messageLabel.frame.origin.y + self.messageLabel.frame.size.height) - 8*2;
	
	if(ccV.frame.size.height>permittedHeight)
	{
		CGFloat heightScale = permittedHeight/ccV.frame.size.height;
		//float scale = heightScale;
		CGAffineTransform transform =CGAffineTransformScale(ccV.transform, heightScale, heightScale);
		//ccV.view.transform = transform;
		//[ccV removeConstraints:ccV.constraints];
		for(UIView* view in ccV.view.subviews)
		{
			//view.transform = transform;
			//[view removeConstraints:view.constraints];
		}
		
		
		//ccV.translatesAutoresizingMaskIntoConstraints = YES;
		int width =ccV.bounds.size.width*heightScale;//*heightScale;
		ccV.bounds = CGRectMake(0, 0, width*heightScale, ccV.bounds.size.height*heightScale);
		ccV.frame = CGRectMake((self.frame.size.width-width)/2, self.messageLabel.frame.origin.y + self.messageLabel.frame.size.height+8, width, permittedHeight);
		//ccV.transform = CGAffineTransformMakeScale(heightScale, heightScale);
		[ccV.deleteButton removeFromSuperview];
		[ccV.createButton removeFromSuperview];
		[ccV.editButton removeFromSuperview];
		ccV.tableView.frame = CGRectMake(ccV.tableView.frame.origin.x, ccV.frame.origin.y, ccV.tableView.frame.size.width, ccV.tableView.frame.size.height-30);
		for(UIView* view in ccV.view.subviews)
		{
			if(view.frame.origin.y > ccV.tableView.frame.origin.y)
			{
				view.frame = CGRectMake(view.frame.origin.x, view.frame.origin.y-30, view.frame.size.width, view.frame.size.height);
			}
		}
		
	}
	
	//[ccV setNeedsDisplay];

	
	//If the fence isn't pending, then say that we finished the update -
	//there is no use to continue with this popup if the fence we are talking about isn't
	//pending...
	if(![pinView.annotation.fence.requestApproved isEqualToString:@"Pending"])
	{
		[self.delegate finishedWithUpdate:self.updateID];
	}
}


- (IBAction)acceptClicked:(id)sender
{
	
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSString* userUUID = [defaults valueForKey:userUUIDDefaultsURL];
	[((AppDelegate*)[[UIApplication sharedApplication] delegate]).socketDealer sendEvent:@"/itrack/acceptgeofence" withData:@{@"userUUID":userUUID, @"geofenceID":[[self.updateData valueForKey:@"geofence"] valueForKey:@"_id"]}];
	
	[self.delegate finishedWithUpdate:self.updateID];
}

- (IBAction)declineClicked:(id)sender
{
	
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSString* userUUID = [defaults valueForKey:userUUIDDefaultsURL];
	[((AppDelegate*)[[UIApplication sharedApplication] delegate]).socketDealer sendEvent:@"/itrack/declinegeofence" withData:@{@"userUUID":userUUID, @"geofenceID":[[self.updateData valueForKey:@"geofence"] valueForKey:@"_id"]}];
	
	[self.delegate finishedWithUpdate:self.updateID];
}
@end
