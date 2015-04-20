//
//  verifyNumber.h
//  iTrack5
//
//  Created by Dean Leitersdorf on 4/9/15.
//  Copyright (c) 2015 Dean Leitersdorf. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface verifyNumber : UIView <UITextFieldDelegate>
@property (strong, nonatomic) IBOutlet UIView *view;
@property (weak, nonatomic) IBOutlet UITextField *textField;
@property (weak, nonatomic) IBOutlet UILabel *last4Digits;
@property (weak, nonatomic) IBOutlet UIView *proceedView;
@property (weak, nonatomic) IBOutlet UIView *wrongAuth;
@property (weak, nonatomic) IBOutlet UIView *goodAuth;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (strong, nonatomic) NSString* name;//passed on from prev popup
@property (weak, nonatomic) IBOutlet UIButton *retrySendingButton;
@property (strong, nonatomic) NSString* last4DigitsString;//passed on from prev popup
@end
