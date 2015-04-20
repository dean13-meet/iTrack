//
//  updateDealerPopup.m
//  iTrack5
//
//  Created by Dean Leitersdorf on 4/12/15.
//  Copyright (c) 2015 Dean Leitersdorf. All rights reserved.
//

#import "updateDealerPopup.h"

@implementation updateDealerPopup

- (void) present
{
	self.view.frame = [updateDealerPopup presentFrameWithMapVC:self.mapVC];
	self.view.center = self.mapVC.view.center;
	self.view.transform = CGAffineTransformMakeScale(2, 2);
	[self.mapVC.view addSubview:self.view];
	
	
	[UIView animateWithDuration:.2 animations:^{
		self.view.transform = CGAffineTransformMakeScale(1, 1);
	}];

	
	
}

+ (CGRect) presentFrameWithMapVC:(mapViewController*)mapVC
{
	CGRect mapVCFrame = mapVC.view.frame;
	return CGRectMake(0, 0, mapVCFrame.size.width*.9, mapVCFrame.size.height*.9);;
}

- (void) dismiss
{
	[UIView animateWithDuration:.1
					 animations:^{
						 self.view.transform = CGAffineTransformMakeScale(.1, .1);
					 } completion:^(BOOL finished) {
						 [self.view removeFromSuperview];
					 }];
}

@end
