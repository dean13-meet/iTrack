//
//  vRequestFrom.h
//  iTrack5
//
//  Created by Dean Leitersdorf on 5/12/15.
//  Copyright (c) 2015 Dean Leitersdorf. All rights reserved.
//

#import "LocationFactoryView.h"
#import "keyboardComplexView.h"

@interface vRequestFrom : LocationFactoryView <keyboardComplexViewDelegate>
@property (strong, nonatomic) IBOutlet UIView *view;

@property (weak, nonatomic) IBOutlet UITextField *toBox;
@property (weak, nonatomic) IBOutlet UILabel *resultLabel;
- (IBAction)searchButtonClicked:(id)sender;


@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (weak, nonatomic) IBOutlet UIButton *searchButton;


@end
