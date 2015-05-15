//
//  requestFrom.h
//  iTrack5
//
//  Created by Dean Leitersdorf on 4/11/15.
//  Copyright (c) 2015 Dean Leitersdorf. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "calloutViewClass.h"
#import "keyboardComplexView.h"

@interface requestFrom : calloutViewClass<keyboardComplexViewDelegate>
@property (strong, nonatomic) IBOutlet UIView *view;

@property (weak, nonatomic) IBOutlet UITextField *toBox;
@property (weak, nonatomic) IBOutlet UILabel *resultLabel;
- (IBAction)searchButtonClicked:(id)sender;
@property (weak, nonatomic) IBOutlet UIButton *cancelButton;
@property (weak, nonatomic) IBOutlet UILabel *addressLabel;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (weak, nonatomic) IBOutlet UIButton *searchButton;

@end
