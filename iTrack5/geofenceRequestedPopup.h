//
//  geofenceRequestedPopup.h
//  iTrack5
//
//  Created by Dean Leitersdorf on 4/12/15.
//  Copyright (c) 2015 Dean Leitersdorf. All rights reserved.
//

#import "updateDealerPopup.h"

@interface geofenceRequestedPopup : updateDealerPopup
@property (strong, nonatomic) IBOutlet UIView *view;
@property (weak, nonatomic) IBOutlet UITextView *messageLabel;
@property (weak, nonatomic) IBOutlet UIView *viewForGeofence;
- (IBAction)acceptClicked:(id)sender;
- (IBAction)declineClicked:(id)sender;

- (instancetype) initWithFrame:(CGRect)frame;

@property (weak, nonatomic) IBOutlet UIToolbar *toolbar;

@property (weak, nonatomic) IBOutlet UILabel *titleLabel;

@end
