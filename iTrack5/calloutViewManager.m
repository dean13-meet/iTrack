//
//  calloutViewManager.m
//  iTrack5
//
//  Created by Dean Leitersdorf on 3/2/15.
//  Copyright (c) 2015 Dean Leitersdorf. All rights reserved.
//

#import "calloutViewManager.h"
#import "toViewCalloutView.h"
#import "requestFrom.h"
#import "whenViewCalloutView.h"
#import "sizeViewCalloutView.h"
#import "customCalloutView.h"
#import "MapPinView.h"
#import "Person.h"
#import "AppDelegate.h"
#import "mapViewController.h"

@interface calloutViewManager()

@property (strong, nonatomic) NSArray* viewsToCycle;
@property (nonatomic) BOOL mode;

@end



@implementation calloutViewManager

@synthesize viewToShow = _viewToShow;
- (void) resetViewToShow
{
	self.viewsToCycle = nil;
	self.viewToShow = nil;
}


- (NSArray*) viewsToCycle
{
    if(!_viewsToCycle)
        
    {
		mapViewController* mapVC = (mapViewController*)(mapVCFromAppDelegate);
		self.mode = mapVC.mode;
		_viewsToCycle = @[self.mode ? [[requestFrom alloc]init] : [[toViewCalloutView alloc]init],[[whenViewCalloutView alloc]init],[[sizeViewCalloutView alloc]init]];
        for(calloutViewClass* view in _viewsToCycle)
        {
            view.delegate = self;
        }
        
    }
    
    return _viewsToCycle;
}

- (void) setSkipFirstView:(BOOL)skipFirstView
{
	if(skipFirstView == _skipFirstView)return;
	_skipFirstView = skipFirstView;
	if(!skipFirstView)return;
	if([self.viewsToCycle indexOfObject:self.viewToShow]==0)
	{
		[self switchToViewIndex:1];
	}
	UIButton* backButtonAtView1 =((whenViewCalloutView*)self.viewsToCycle[1]).backButton;
	[backButtonAtView1 setEnabled:NO];
	[backButtonAtView1 setHidden:YES];
	[backButtonAtView1 setAlpha:0];
}

- (void) setTakeThisFence:(Geofence *)takeThisFence
{
	_takeThisFence = takeThisFence;
	
	if(!takeThisFence)return;
	
	NSArray* recs = [mapViewController recsFromFenceData:takeThisFence.recipients];
	for(calloutViewClass* view in self.viewsToCycle)
	{
		if([view isKindOfClass:[requestFrom class]])
		{
			//nothing we can do.
		}
		else if ([view isKindOfClass:[toViewCalloutView class]])
		{
			toViewCalloutView* v = view;
			v.cancelEditButton.enabled = YES;
			v.cancelEditButton.hidden = NO;
			v.recipients = recs.mutableCopy;
		}
		else if ([view isKindOfClass:[whenViewCalloutView class]])
		{
			whenViewCalloutView* v = view;
			if(self.skipFirstView){
			v.cancelEditButton.enabled = YES;
				v.cancelEditButton.hidden = NO;}
			v.arrivalSwitch.on = [takeThisFence.onArrival boolValue];
			v.leaveSwitch.on = [takeThisFence.onLeave boolValue];
			[v.recurr setSelectedSegmentIndex:[takeThisFence.recur integerValue]];
		}
		else if ([view isKindOfClass:[sizeViewCalloutView class]])
		{
			sizeViewCalloutView* v = view;
			v.slider.value = [takeThisFence.radius floatValue];
			[v.finishButton setTitle:editButtonTitle forState:UIControlStateNormal];
		}
	}
	
}
- (void) showToViewCancelButton // this is public and can be called by anyone!
{
	
	if([self.viewsToCycle[0] isKindOfClass:[toViewCalloutView class]])
	{
		toViewCalloutView* view;
		view = self.viewsToCycle[0];
		view.cancelEditButton.enabled = YES;
		view.cancelEditButton.hidden = NO;
	}
	else if ([self.viewsToCycle[0] isKindOfClass:[requestFrom class]])
	{
		requestFrom* view;
		view = self.viewsToCycle[0];
		view.cancelButton.enabled = YES;
		view.cancelButton.hidden = NO;
	}
	
}
- (void) cancelEdit
{
	[self.delegate cancelEdit];
}

- (calloutViewClass*) viewToShow
{
    if(!_viewToShow)
    {
        _viewToShow = self.viewsToCycle[0];
    }
    return _viewToShow;
}

- (void) setViewToShow:(calloutViewClass *)viewToShow
{
    _viewToShow = viewToShow;
    [self updateAddressInViewToShow];
}

- (void) addressUpdated
{
    [self updateAddressInViewToShow];
    
}
- (void) updateAddressInViewToShow
{
    self.viewToShow.addressLabel.text = ((MapPinView*)((customCalloutView*)self.delegate).delegate).annotation.address;
}
- (void) nextWithSender:(id)sender
{

    if(![sender isEqual:self.viewToShow])//if you are not the current view being shown, don't ask us to move to next view -_-
    {
        return;
    }
    
    
    int index = [[NSNumber numberWithLong:[self.viewsToCycle indexOfObject:sender] ] intValue];
    if(index == [self.viewsToCycle count]-1)
    {
        [self createClicked];
        return;
    }
    
    self.viewToShow = self.viewsToCycle[index+1];
    
    [self.delegate viewDidChange];
}

- (void) backWithSender:(id)sender
{
    if(![sender isEqual:self.viewToShow])//if you are not the current view being shown, don't ask us to move to previous view -_-
    {
        return;
    }
    int index = [[NSNumber numberWithLong:[self.viewsToCycle indexOfObject:sender] ] intValue];
	[self switchToViewIndex:index-1];
}

- (void) switchToViewIndex:(int)index
{
	if(index < 0 || (self.skipFirstView && index <1))return;
	self.viewToShow = self.viewsToCycle[index];
	[self.delegate viewDidChange];
}

- (void) createClicked
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSString* username = [defaults valueForKey:usernameDefaultsURL];
	
	
    float recurr = [self getReccurence];
	NSMutableArray* recipients;
	NSString* requestingFrom;
	if(self.mode)
	{
		if(self.skipFirstView && self.takeThisFence)
		{
			requestingFrom = self.takeThisFence.owner;
		}
		else{
		
		requestFrom* view = self.viewsToCycle[0];
		requestingFrom =view.resultLabel.text;
		if([requestingFrom isEqualToString:@"No Results Yet!"] || [requestingFrom isEqualToString:@"No person matches that!"])
		{
			[self switchToViewIndex:0];
			UIAlertView * alert =[[UIAlertView alloc ] initWithTitle:@"Error: Missing Info"
															 message:@"You did not enter who to request from! Please enter below."
															delegate:self
												   cancelButtonTitle:@"OK"
												   otherButtonTitles: nil];
			
			[alert show];
			return;
		}
		else if ([requestingFrom isEqualToString:username])
		{
			[self switchToViewIndex:0];
			UIAlertView * alert =[[UIAlertView alloc ] initWithTitle:@"Error: Self-Request"
															 message:@"You cannot request yourself to notify yourself!"
															delegate:self
												   cancelButtonTitle:@"OK"
												   otherButtonTitles: nil];
			
			[alert show];
			return;
		}
		
	}
	}
	else{
		recipients = [[NSMutableArray alloc] init];
    for(id rec in ((toViewCalloutView*)self.viewsToCycle[0]).recipients)
    {
        if([rec isKindOfClass:[Person class]])
        {
            Person* recPerson = rec;
			/*
            NSNumberFormatter *f = [[NSNumberFormatter alloc] init];
            f.numberStyle = NSNumberFormatterDecimalStyle;
            for(NSString* number in recPerson.numbers.allKeys)
            {
                if([[recPerson.numbers valueForKey:number] boolValue])
                {
                    [recipients addObject:[f numberFromString:[[number componentsSeparatedByCharactersInSet:[[NSCharacterSet decimalDigitCharacterSet] invertedSet]] componentsJoinedByString:@""]]];//use only numbers 0-9 (including arabic/hindi numbering systems) (NOTE: Excludes "+")
                }
                
            }*/
			[recipients addObject:recPerson];
			 
			 }
        else{
            [recipients addObject:rec];}
        }
    
	}
	if(!requestingFrom && recipients.count == 0)
	{
		[self switchToViewIndex:0];
		UIAlertView * alert =[[UIAlertView alloc ] initWithTitle:@"Error: Missing Info"
														 message:@"You did not enter who to send the notifications to! Please do so below."
														delegate:self
											   cancelButtonTitle:@"OK"
											   otherButtonTitles: nil];
		
		[alert show];
		return;

	}
    float radius = ((sizeViewCalloutView*)self.viewsToCycle[2]).slider.value;
    BOOL arrival = ((whenViewCalloutView*)self.viewsToCycle[1]).arrivalSwitch.on;
    BOOL leave =((whenViewCalloutView*)self.viewsToCycle[1]).leaveSwitch.on;
    
	[self.delegate createClickedRecurr:recurr recipients:recipients?recipients:[mapViewController recsFromFenceData:self.takeThisFence.recipients] radius:radius arrival:arrival leave:leave shouldUpdateSetting:YES requestingFrom:requestingFrom];
    if(requestingFrom)
	{
		UIAlertView * alert =[[UIAlertView alloc ] initWithTitle:@"Success!"
														 message:@"Your changes have been saved! However, the person you requested the location notification from will have to accept your request before it can be activated!"
														delegate:self
											   cancelButtonTitle:@"OK"
											   otherButtonTitles: nil];
		
		[alert show];
	}
}

- (float) getReccurence
{
    
        switch (((whenViewCalloutView*)self.viewsToCycle[1]).recurr.selectedSegmentIndex) {
            case 0://Never
                return 0.0;
                
            case 1://Always
                return 1.0;
                
            default:
                return 0.0;
        }
    
}

- (void) radiusValueChanged:(float)radius
{
    [self.delegate radiusValueChanged:radius];
}

@end
