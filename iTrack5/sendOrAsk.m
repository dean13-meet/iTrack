//
//  sendOrAsk.m
//  iTrack5
//
//  Created by Dean Leitersdorf on 5/4/15.
//  Copyright (c) 2015 Dean Leitersdorf. All rights reserved.
//

#import "sendOrAsk.h"
#import "UIView+HeightResize.h"
#import "AppDelegate.h"

@implementation sendOrAsk

- (instancetype) initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if(self)
    {
        
        [[NSBundle mainBundle] loadNibNamed:@"sendOrAsk" owner:self options:nil];
        
		[UIView resizeHeightForView:self.view];
		
        self.bounds = self.view.bounds;
        
        [self addSubview:self.view];
		
		
		
        
    }
    return self;
}



- (IBAction)sendClicked:(id)sender
{
	self.locFactory.mode = NO;
	[super next];
}

- (IBAction)askClicked:(id)sender
{
	self.locFactory.mode = YES;
	[super next];
}
@end
