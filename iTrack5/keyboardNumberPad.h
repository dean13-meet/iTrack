//
//  keyboardNumberPad.h
//  iTrack5
//
//  Created by Dean Leitersdorf on 3/17/15.
//  Copyright (c) 2015 Dean Leitersdorf. All rights reserved.
//

#import <UIKit/UIKit.h>


@protocol numberPadDelegate <NSObject> //sends user inputted taps

- (void) keyTapped:(NSString*)key;
- (void) backspaceTapped;

@end

@interface keyboardNumberPad : UIView
@property (strong, nonatomic) IBOutlet UIView *view;

- (IBAction)buttonClicked:(UIButton *)sender;
- (void) positionButtons;
@property (strong, nonatomic) IBOutletCollection(UIButton) NSArray *buttons;


@property (strong, nonatomic) id<numberPadDelegate> delegate;
@end
