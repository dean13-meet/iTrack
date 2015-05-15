//
//  LocationFactory.m
//  iTrack5
//
//  Created by Dean Leitersdorf on 5/4/15.
//  Copyright (c) 2015 Dean Leitersdorf. All rights reserved.
//

#import "LocationFactory.h"
#import "mapViewController.h"
#import "AppDelegate.h"
#import "sendOrAsk.h"
#import "LocationFactoryView.h"
#import "vToView.h"
#import "vRequestFrom.h"
#import "obtainLocation.h"

@interface LocationFactory()



/*
typedef enum {
	vSendOrAsk,
	vToView,
	requestFrom,
	whenView,
	sizeView
} ViewNumber;

//IMPORTANT: location of views in views array must match the ordering above!
*/

@property (strong, nonatomic) NSMutableArray* views;
@property (strong, nonatomic) mapViewController* mapVC;
@property (weak, nonatomic) LocationFactoryView* currentView;

@end

@implementation LocationFactory

- (instancetype) init
{
	self = [super init];
	if(self)
	{
		[self switchToViewIndex:0];
		[self disableMap];
	}
	return self;
}


- (NSMutableArray*) views
{
	if(!_views)
	{
		_views = @[[[sendOrAsk alloc]init], [[vToView alloc]init], [[vRequestFrom alloc]init], [[obtainLocation alloc]init]].mutableCopy;
		for(LocationFactoryView* view in _views)
		{
			view.locFactory = self;
		}
	}
	return _views;
}

- (mapViewController*)mapVC
{
	return (mapViewController*)((AppDelegate*)[UIApplication sharedApplication].delegate).mapVC;
}

- (void) switchToViewIndex:(int)index
{
	if(index < 0 || index >= self.views.count)return;
	BOOL isFirstTimeWeAreShowingAView = self.currentView==nil;
	[self.currentView removeFromSuperview];
	[self.currentView onDepresent];
	self.currentView = self.views[index];
	[self.mapVC.view addSubview:self.currentView];
	if(!isFirstTimeWeAreShowingAView)
		self.currentView.center = self.mapVC.view.center;
	else
	{
		self.currentView.alpha = 0;
		CGRect prevFrame = self.currentView.frame;
		self.currentView.frame = CGRectMake(prevFrame.origin.x, prevFrame.origin.y, prevFrame.size.width, 1);
		self.currentView.center = self.mapVC.view.center;
		[UIView animateWithDuration:.2 animations:^{
			self.currentView.frame = prevFrame;
			self.currentView.center = self.mapVC.view.center;
			self.currentView.alpha = 1;
		}];
	}
	[self.currentView onPresent];
	
}


- (void) nextWithSender:(id)sender
{
	
	if(![sender isEqual:self.currentView])//if you are not the current view being shown, don't ask us to move to next view -_-
	{
		return;
	}
	
	
	int index = [[NSNumber numberWithLong:[self.views indexOfObject:sender] ] intValue];
	
	if(index == 0)//the view where we choose btwn ask/send
	{
		index += (!self.mode ? 0 : 1);//if "ask" then increment index
	}
	
	if(index == 1)
	{
		index += (!self.mode ? 1 : 0);//if "send" then increment index
	}
	
	[self switchToViewIndex:index+1];
	
	/*
	if(index == [self.views count]-1)
	{
		//TODO
		//[self createClicked];
		return;
	}
	
	self.currentView = self.views[index+1];*/
	
	
}

- (void) backWithSender:(id)sender
{
	if(![sender isEqual:self.currentView])//if you are not the current view being shown, don't ask us to move to previous view -_-
	{
		return;
	}
	int index = [[NSNumber numberWithLong:[self.views indexOfObject:sender] ] intValue];
	
	if(index == 2)//the view where we choose btwn ask/send
	{
		index -= (!self.mode ? 0 : 1);//if "ask" then decrement index
	}
	else if (index==3)
	{
		index -= (!self.mode ? 1 : 0);//if "send" then decrement index
	}
	
	[self switchToViewIndex:index-1];
}



- (void) dealloc
{
	[self.currentView removeFromSuperview];
	[self enableMap];
}

- (void) disableMap
{
	[((AppDelegate*)[UIApplication sharedApplication].delegate) setMapEnabled:NO excluding:@[@"plus"]];
}
- (void) enableMap
{
	[((AppDelegate*)[UIApplication sharedApplication].delegate) setMapEnabled:YES excluding:@[]];
}

@end
