//
//  MapPinView.m
//  iTrack5
//
//  Created by Dean Leitersdorf on 2/17/15.
//  Copyright (c) 2015 Dean Leitersdorf. All rights reserved.
//

#import "MapPinView.h"


@implementation MapPinView

- (instancetype) initWithAnnotation:(id<MKAnnotation>)annotation reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithAnnotation:annotation reuseIdentifier:reuseIdentifier];
    if(self)
    {
        self.canShowCallout = NO;
    }
    return self;
}

- (UIView*)hitTest:(CGPoint)point withEvent:(UIEvent*)event
{
    {
        //test touched point in map view
        //when hit test return nil callout close immediately by default
        UIView* hitView = [super hitTest:point withEvent:event];
        // if hittest return nil test touch point
        if (hitView == nil){
            //dig view to find custom touchable view lately added by us
            for(UIView *firstView in self.subviews){
                if([firstView isKindOfClass:[NSClassFromString(@"UICalloutView") class]]){
                    for(UIView *touchableView in firstView.subviews){
                        if([touchableView isKindOfClass:[UIView class]]){ //this is our touchable view class
                            //define touchable area
                            CGRect touchableArea = CGRectMake(firstView.frame.origin.x, firstView.frame.origin.y, touchableView.frame.size.width, touchableView.frame.size.height);
                            //test touch point if in touchable area
                            if (CGRectContainsPoint(touchableArea, point)){
                                //if touch point is in touchable area return touchable view as a touched view
                                hitView = touchableView;
                            }
                        }
                    }
                }
            }
        }
        
        
        return hitView;
    }
}



- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent*)event
{
    CGRect rect = self.bounds;
    BOOL isInside = CGRectContainsPoint(rect, point);
    if(!isInside)
    {
        for (UIView *view in self.subviews)
        {
            isInside = CGRectContainsPoint(view.frame, point);
            if(isInside)
                break;
        }
    }
    return isInside;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
    [self.mapVC setSearchBarShown:!selected];
    [self updateCircle];
    // Get the custom callout view.
    UIView *calloutView = self.calloutView;
    if (selected) {
        
        [self repositionCalloutView];
        calloutView.alpha = 0.0;
        
        [self.mapVC.view addSubview:calloutView];
        [self.mapVC.view bringSubviewToFront:calloutView];
        [UIView animateWithDuration:0.15
                         animations:^{calloutView.alpha = 1.0;}
                         completion:nil];
        
    } else {
        [UIView animateWithDuration:0.15
                         animations:^{calloutView.alpha = 0.0;}
                         completion:^(BOOL finished){ [calloutView removeFromSuperview]; }];
    }

    [self repositionCalloutView];
    
}

- (void) repositionCalloutView
{
    UIView *calloutView = self.calloutView;
    CGRect calloutViewFrame = calloutView.frame;
    CGRect viewFrom = self.mapVC.view.frame;
    //center x:
    int xOrigin = (viewFrom.size.width - calloutViewFrame.size.width)/2;
    //line up to top:
    int yOrigin = 27;//viewFrom.size.height - calloutViewFrame.size.height - 7;
    
    calloutView.frame = CGRectMake(xOrigin, yOrigin, calloutViewFrame.size.width, calloutViewFrame.size.height);
}

- (MKCircle*)circle
{
    if(!_circle || self.forceCircleUpdate)
    {
        if(_circle)
        {
            [self.mapVC.mapView removeOverlay:_circle];
        }
        _circle = [MKCircle circleWithCenterCoordinate:self.annotation.coordinate radius:self.calloutView.radius];
        self.forceCircleUpdate = NO;
    }
    return _circle;
}


- (customCalloutView*) calloutView
{
    if(!_calloutView)
    {
        _calloutView = [[customCalloutView alloc]init];
        _calloutView.delegate = self;
    }
    return _calloutView;
}

- (void) updateCircle
{
    if(self.isSelected)
    {
        [self radiusValueChanged];
    }
    else
    {
        [self.mapVC.mapView removeOverlay:self.circle];
    }
}

- (void) radiusValueChanged
{
    
    [self.mapVC.mapView removeOverlay:self.circle];
    self.forceCircleUpdate = YES;
    [self.mapVC.mapView addOverlay:self.circle];
}

- (void) updateCalloutView:(BOOL)force;//force dictates whether to fetch info from annotation.fence
{
    MapPinView* pinView = self;
    MapPin* annotation = self.annotation;
    
    [pinView.calloutView setAddresLabelText:annotation.address];
    if(force){
    if(annotation.fence)
    {
        Geofence* fence = annotation.fence;
        
        
        switch ([fence.recur intValue]) {
            case 0:
                pinView.calloutView.repeat = NO;
                break;
                
            case 1:
				pinView.calloutView.repeat = YES;
                break;
                
            default:
                break;
        }
        
		pinView.calloutView.radius = [fence.radius floatValue];
        //NSArray* recs = [NSKeyedUnarchiver unarchiveObjectWithData:fence.recipients];
        
        pinView.calloutView.fence = fence;
        
        pinView.calloutView.leave = [fence.onLeave boolValue];
        pinView.calloutView.arrival = [fence.onArrival boolValue];
    }
    else
    {
        pinView.calloutView.editMode = YES;
    }
    }
    [self.calloutView setNeedsDisplay];
    [self updateCircle];
}

- (void) saveFence
{
    [self.calloutView createClicked:[NSNumber numberWithInt:234567]];
    
}
- (void) showToViewCancelButton
{
	[self.calloutView showToViewCancelButton];
}

@end
