//
//  geofenceAccepted.h
//  iTrack5
//
//  Created by Dean Leitersdorf on 4/14/15.
//  Copyright (c) 2015 Dean Leitersdorf. All rights reserved.
//

#import "updateDealerPopup.h"

@interface geofenceAccepted : updateDealerPopup

@property (strong, nonatomic) IBOutlet UIView *view;
@property (weak, nonatomic) IBOutlet UITextView *messageLabel;
@property (weak, nonatomic) IBOutlet UIView *viewForGeofence;
- (IBAction)okClicked;

- (instancetype) initWithFrame:(CGRect)frame;

@property (weak, nonatomic) IBOutlet UIToolbar *toolbar;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;

@end
