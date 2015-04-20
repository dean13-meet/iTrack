//
//  takeCareOfUserUpdates.h
//  iTrack5
//
//  Created by Dean Leitersdorf on 4/12/15.
//  Copyright (c) 2015 Dean Leitersdorf. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "mapViewController.h"
#import "updateDealerPopup.h"

@interface takeCareOfUserUpdates : NSObject <updateDealerPopupDelegate>

@property (strong, nonatomic) mapViewController* mapVC;//to present popup in
@property (strong, nonatomic) updateDealerPopup* currentPopup;
@property (strong, nonatomic) NSMutableDictionary* updates;
@property (strong, nonatomic) NSMutableArray* updatesDealtWith;//sometimes updates get synced back from server in the time between the user has already dealt with them and the time the server receives that the update was dealt with. Therefore, we have to make sure that we keep track of the updates the user already saw so that we do not so the same update twice.

- (instancetype) init;

@end
