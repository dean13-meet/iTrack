//
//  LocationFactoryView.m
//  iTrack5
//
//  Created by Dean Leitersdorf on 5/12/15.
//  Copyright (c) 2015 Dean Leitersdorf. All rights reserved.
//

#import "LocationFactoryView.h"

#import "UIView+HeightResize.h"

@implementation LocationFactoryView

- (void) next
{
	[self.locFactory nextWithSender:self];
}

- (void) back
{
	[self.locFactory backWithSender:self];
}

- (IBAction)backButtonClicked:(id)sender
{
	[self back];
}

- (IBAction)nextButtonPressed:(id)sender
{
	[self next];
}

- (void) onPresent
{
	//To be implemented in subclasses
}
- (void) onDepresent
{
	//To be implemented in subclasses
}

@end
