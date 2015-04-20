//
//  insertNumber.h
//  iTrack5
//
//  Created by Dean Leitersdorf on 4/9/15.
//  Copyright (c) 2015 Dean Leitersdorf. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface insertNumber : UIView
@property (strong, nonatomic) IBOutlet UIView *view;
@property (weak, nonatomic) IBOutlet UIView *invalidNumberView;
@property (weak, nonatomic) IBOutlet UIView *proceedView;
@property (weak, nonatomic) IBOutlet UITextField *textView;

@property (strong, nonatomic) NSString* name;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;

@end
