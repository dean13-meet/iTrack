//
//  recCell.m
//  iTrack5
//
//  Created by Dean Leitersdorf on 3/7/15.
//  Copyright (c) 2015 Dean Leitersdorf. All rights reserved.
//

#import "recCell.h"

@implementation recCell

- (void)awakeFromNib {
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}
- (IBAction)deleteClicked:(id)sender
{
    [self.delegate deleteSelfWithSender:self];
}
- (void) disableX
{
	[self.xButton setEnabled:NO];
	[self.xButton setHidden:YES];
}
@end
