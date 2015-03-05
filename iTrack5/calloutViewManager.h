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


@protocol calloutViewManagerDelegate

- (void) viewDidChange;
- (void) radiusValueChanged:(float)radius;
- (void) createClickedRecurr:(float)recurr recipient:(NSInteger)recipient radius:(float)radius arrival:(BOOL) arrival leave:(BOOL) leave;

@end

@interface calloutViewManager : NSObject <calloutViewClassDelegate>


@property (strong, nonatomic) calloutViewClass* viewToShow;

@property (strong, nonatomic) id<calloutViewManagerDelegate> delegate;

- (void) radiusValueChanged:(float)radius;


@end
