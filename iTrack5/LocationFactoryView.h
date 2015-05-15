//
//  LocationFactoryView.h
//  iTrack5
//
//  Created by Dean Leitersdorf on 5/12/15.
//  Copyright (c) 2015 Dean Leitersdorf. All rights reserved.
//

#import "LocationFactory.h"
#import <UIKit/UIKit.h>

@interface LocationFactoryView : UIView

@property (weak, nonatomic) LocationFactory* locFactory;

- (void) next;
- (void) back;

- (IBAction)backButtonClicked:(id)sender;

//Call these to notify the view that it is being presented or replaced
- (void) onPresent;
- (void) onDepresent;

@end
