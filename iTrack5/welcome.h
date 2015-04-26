//
//  welcome.h
//  iTrack5
//
//  Created by Dean Leitersdorf on 4/21/15.
//  Copyright (c) 2015 Dean Leitersdorf. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface welcome : UIView
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
- (IBAction)enterClicked:(id)sender;
@property (strong, nonatomic) IBOutlet UIView *view;

@end
