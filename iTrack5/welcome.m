//
//  welcome.m
//  iTrack5
//
//  Created by Dean Leitersdorf on 4/21/15.
//  Copyright (c) 2015 Dean Leitersdorf. All rights reserved.
//

#import "welcome.h"
#import "urls.m"

@implementation welcome


- (instancetype) initWithFrame:(CGRect)frame
{
	self = [super initWithFrame:frame];
	if(self)
	{
		
		[[NSBundle mainBundle] loadNibNamed:@"welcome" owner:self options:nil];
		
		self.bounds = self.view.bounds;
				
		[self addSubview:self.view];
		
		NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
		NSString* username = [defaults valueForKey:usernameDefaultsURL];
		self.nameLabel.text = [self.nameLabel.text stringByReplacingOccurrencesOfString:@"USERNAME" withString:username];
		
		
	}
	return self;
}


- (IBAction)enterClicked:(id)sender
{
	[UIView animateWithDuration:.2
					 animations:^{
						 //self.frame = CGRectMake(self.center.x - 350, self.center.y - 350, 700,700);
						 //self.transform = CGAffineTransformMakeScale(.1, .1);
						 self.alpha = 0;
					 } completion:^(BOOL finished) {
						 //self.transform = CGAffineTransformMakeScale(1, 1);
						 [self removeFromSuperview];
					 }];
}
@end
