//
//  whenViewCalloutView.h
//  iTrack5
//
//  Created by Dean Leitersdorf on 3/2/15.
//  Copyright (c) 2015 Dean Leitersdorf. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "calloutViewClass.h"

@interface whenViewCalloutView : calloutViewClass
@property (strong, nonatomic) IBOutlet UIView *view;

@property (weak, nonatomic) IBOutlet UISegmentedControl *recurr;
@property (weak, nonatomic) IBOutlet UISwitch *arrivalSwitch;

@property (weak, nonatomic) IBOutlet UISwitch *leaveSwitch;
@property (weak, nonatomic) IBOutlet UIButton *backButton;
@property (weak, nonatomic) IBOutlet UIButton *cancelEditButton;

@end
