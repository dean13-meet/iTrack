//
//  obtainLocation.m
//  iTrack5
//
//  Created by Dean Leitersdorf on 5/14/15.
//  Copyright (c) 2015 Dean Leitersdorf. All rights reserved.
//

#import "obtainLocation.h"
#import "UIView+HeightResize.h"
#import "AppDelegate.h"
#import "mapViewController.h"

@implementation obtainLocation

- (instancetype) initWithFrame:(CGRect)frame
{
	self = [super initWithFrame:frame];
	if(self)
	{
		
		[[NSBundle mainBundle] loadNibNamed:@"obtainLocation" owner:self options:nil];
		
		[UIView resizeHeightForView:self.view];
		
		self.bounds = self.view.bounds;
		
		[self addSubview:self.view];
		
		[self loadSearchBar];
		
		
	}
	return self;
}

- (void) loadSearchBar
{
	UIView* topView = ((mapViewController*)((AppDelegate*)[UIApplication sharedApplication].delegate).mapVC).topBar;
	
	[self.viewForSearchBar addSubview:topView];
	topView.frame = CGRectMake(0, 0, self.viewForSearchBar.frame.size.width, self.viewForSearchBar.frame.size.height);
	//topView.center = self.viewForSearchBar.center;
	topView.bounds = CGRectMake(0, 0, self.viewForSearchBar.frame.size.width, self.viewForSearchBar.frame.size.height);
	
}

- (void) onPresent
{
	[self.locFactory enableMap];
}

- (void) onDepresent
{
	[self.locFactory disableMap];
}


@end
