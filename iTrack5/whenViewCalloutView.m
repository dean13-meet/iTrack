//
//  whenViewCalloutView.m
//  iTrack5
//
//  Created by Dean Leitersdorf on 3/2/15.
//  Copyright (c) 2015 Dean Leitersdorf. All rights reserved.
//

#import "whenViewCalloutView.h"

@implementation whenViewCalloutView



- (instancetype) initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if(self)
    {
        
        [[NSBundle mainBundle] loadNibNamed:@"whenViewView" owner:self options:nil];
        
        self.bounds = self.view.bounds;
        
        [self addSubview:self.view];
        
        
    }
    return self;
}
/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/


- (IBAction)clickedNext:(id)sender
{
    [super clickedNext];
}

- (IBAction)backClicked:(id)sender
{
    [super backClicked];
}
- (IBAction)cancelEdit:(id)sender {
	[self.delegate cancelEdit];
}
@end
