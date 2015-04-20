//
//  updateDealerPopup.h
//  iTrack5
//
//  Created by Dean Leitersdorf on 4/12/15.
//  Copyright (c) 2015 Dean Leitersdorf. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "mapViewController.h"

@protocol updateDealerPopupDelegate

@required
- (void) finishedWithUpdate:(NSString*)updateID;//this says that we can dismiss this update and move on to the next one!
- (void) couldNotResolveUpdate:(NSString*)updateID;//means something happened that we couldn't resolve.
//if this happens, don't tell the server anything, the update will just come back on next login and you can try
//resolving then.

@end

@interface updateDealerPopup : UIView

@property (strong, nonatomic) NSString* updateID;
@property (strong, nonatomic) NSDictionary* updateData;
@property (weak, nonatomic)mapViewController* mapVC;//to get info about fences, etc.

@property (weak, nonatomic) id <updateDealerPopupDelegate> delegate;
- (void) present;
- (void) dismiss;
+ (CGRect) presentFrameWithMapVC:(mapViewController*)mapVC;

@property (strong, nonatomic) IBOutlet UIView* view;

@end
