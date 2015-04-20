//
//  calloutViewManager.h
//  iTrack5
//
//  Created by Dean Leitersdorf on 3/2/15.
//  Copyright (c) 2015 Dean Leitersdorf. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "calloutViewClass.h"
#import "Geofence.h"


@protocol calloutViewManagerDelegate

- (void) viewDidChange;
- (void) radiusValueChanged:(float)radius;
- (void) createClickedRecurr:(float)recurr recipients:(NSArray*)recs radius:(float)radius arrival:(BOOL)arrival leave:(BOOL)leave shouldUpdateSetting:(BOOL)shouldUpdateSetting requestingFrom:(NSString*)requestingFrom;
- (void) cancelEdit;

@end

@interface calloutViewManager : NSObject <calloutViewClassDelegate>


@property (strong, nonatomic) calloutViewClass* viewToShow;
- (void) resetViewToShow;

@property (strong, nonatomic) id<calloutViewManagerDelegate> delegate;

- (void) radiusValueChanged:(float)radius;

- (void) addressUpdated;

@property (strong, nonatomic) Geofence* takeThisFence;//when given to the calloutViewManager, it auto updates its data

@property (nonatomic) BOOL skipFirstView;//in case of editing a requested fence, we CANNOT edit the first view which contains who is requesting from who. To request from a different person, you must create a new requested fence.

- (void) showToViewCancelButton;
@end
