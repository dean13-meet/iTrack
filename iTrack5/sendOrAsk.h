//
//  sendOrAsk.h
//  iTrack5
//
//  Created by Dean Leitersdorf on 5/4/15.
//  Copyright (c) 2015 Dean Leitersdorf. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LocationFactoryView.h"

@interface sendOrAsk : LocationFactoryView
@property (strong, nonatomic) IBOutlet UIView *view;

- (IBAction)sendClicked:(id)sender;

- (IBAction)askClicked:(id)sender;

@end
