//
//  calloutViewClass.m
//  iTrack5
//
//  Created by Dean Leitersdorf on 3/2/15.
//  Copyright (c) 2015 Dean Leitersdorf. All rights reserved.
//

#import "calloutViewClass.h"

@implementation calloutViewClass

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

- (void) clickedNext
{
    [self.delegate nextWithSender:self];
}

- (void) backClicked
{
    [self.delegate backWithSender:self];
}
@end
