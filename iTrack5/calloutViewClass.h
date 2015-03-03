//
//  calloutViewClass.h
//  iTrack5
//
//  Created by Dean Leitersdorf on 3/2/15.
//  Copyright (c) 2015 Dean Leitersdorf. All rights reserved.
//

#import <UIKit/UIKit.h>



@protocol calloutViewClassDelegate

- (void) nextWithSender:(id)sender;
- (void) backWithSender:(id)sender;

@end


@interface calloutViewClass : UIView

@property (strong, nonatomic) id<calloutViewClassDelegate> delegate;

- (void) clickedNext;
- (void) backClicked;

@end
