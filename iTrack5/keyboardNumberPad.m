//
//  keyboardNumberPad.m
//  iTrack5
//
//  Created by Dean Leitersdorf on 3/17/15.
//  Copyright (c) 2015 Dean Leitersdorf. All rights reserved.
//

#import "keyboardNumberPad.h"

@implementation keyboardNumberPad

- (instancetype) initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if(self)
    {
        
        [[NSBundle mainBundle] loadNibNamed:@"keyboardNumberPad" owner:self options:nil];
        
        self.bounds = self.view.bounds;
        
        [self addSubview:self.view];
        
        
    }
    return self;
}

- (IBAction)buttonClicked:(UIButton *)sender
{
    [[UIDevice currentDevice] playInputClick];
    NSString* btnTitle = sender.titleLabel.text;
    [btnTitle isEqualToString:@"Delete"] ? [self.delegate backspaceTapped] : [self.delegate keyTapped:btnTitle];
}

- (void) positionButtons
{/*
#define numRows 4
#define numCols 3
    int cellWidth = self.frame.size.width/numCols;
    int cellHeight = self.frame.size.height/numRows;
    
    for(int i = 0; i < numRows; i++)
    {
        for(int j = 0; j < numCols; j++)
        {
            ((UIButton*)self.buttons[i*numCols+j]).frame = CGRectMake(j*cellWidth + self.bounds.origin.x, i*cellHeight + self.bounds.origin.y, cellWidth, cellHeight);
            ((UIButton*)self.buttons[i*numCols+j]).bounds = CGRectMake(0, 0, cellWidth, cellHeight);
        }
    }*/
}

@end
