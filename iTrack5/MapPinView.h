//
//  MapPinView.h
//  iTrack5
//
//  Created by Dean Leitersdorf on 2/17/15.
//  Copyright (c) 2015 Dean Leitersdorf. All rights reserved.
//

#import <MapKit/MapKit.h>
#import <UIKit/UIKit.h>
#import "customCalloutView.h"
#import "mapViewController.h"




@interface MapPinView : MKPinAnnotationView <customCalloutViewDelegate>

@property (strong, nonatomic) customCalloutView* calloutView;
@property (nonatomic) mapViewController* mapVC;
@property (strong, nonatomic) MKCircle* circle;

@property (nonatomic) BOOL forceCircleUpdate;

- (void) repositionCalloutView;
@end
