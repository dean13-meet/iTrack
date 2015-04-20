//
//  geofenceAccepted.m
//  iTrack5
//
//  Created by Dean Leitersdorf on 4/14/15.
//  Copyright (c) 2015 Dean Leitersdorf. All rights reserved.
//

#import "geofenceAccepted.h"
#import "MapPinView.h"

@implementation geofenceAccepted

- (instancetype) initWithFrame:(CGRect)frame
{
	self = [super initWithFrame:frame];
	if(self)
	{
		
		[[NSBundle mainBundle] loadNibNamed:@"geofenceAccepted" owner:self options:nil];
		
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
	self.messageLabel.text = [self.messageLabel.text stringByReplacingOccurrencesOfString:@"USERNAME" withString:[[updateData valueForKey:@"geofence"] valueForKey:@"owner"]];
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
	int permittedHeight = self.toolbar.frame.origin.y - (self.messageLabel.frame.origin.y + self.messageLabel.frame.size.height) - 8*2;
	
	if(ccV.frame.size.height>permittedHeight)
	{
		CGFloat heightScale = permittedHeight/ccV.frame.size.height;
		ccV.transform = CGAffineTransformMakeScale(heightScale, heightScale);
	}

	
}


- (IBAction)okClicked
{
	[self.delegate finishedWithUpdate:self.updateID];
}


@end
