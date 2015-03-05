//
//  calloutViewManager.m
//  iTrack5
//
//  Created by Dean Leitersdorf on 3/2/15.
//  Copyright (c) 2015 Dean Leitersdorf. All rights reserved.
//

#import "calloutViewManager.h"
#import "toViewCalloutView.h"
#import "whenViewCalloutView.h"
#import "sizeViewCalloutView.h"

@interface calloutViewManager()

@property (strong, nonatomic) NSArray* viewsToCycle;

@end



@implementation calloutViewManager


- (NSArray*) viewsToCycle
{
    if(!_viewsToCycle)
        
    {
        _viewsToCycle = @[[[toViewCalloutView alloc]init],[[whenViewCalloutView alloc]init],[[sizeViewCalloutView alloc]init]];
        for(calloutViewClass* view in _viewsToCycle)
        {
            view.delegate = self;
        }
        
    }
    
    return _viewsToCycle;
}

- (calloutViewClass*) viewToShow
{
    if(!_viewToShow)
    {
        _viewToShow = self.viewsToCycle[0];
    }
    return _viewToShow;
}


- (void) nextWithSender:(id)sender
{

    if(![sender isEqual:self.viewToShow])//if you are not the current view being shown, don't ask us to move to next view -_-
    {
        return;
    }
    
    
    int index = [[NSNumber numberWithLong:[self.viewsToCycle indexOfObject:sender] ] intValue];
    if(index == [self.viewsToCycle count]-1)
    {
        [self createClicked];
        return;
    }
    
    self.viewToShow = self.viewsToCycle[index+1];
    [self.delegate viewDidChange];
}

- (void) backWithSender:(id)sender
{
    if(![sender isEqual:self.viewToShow])//if you are not the current view being shown, don't ask us to move to previous view -_-
    {
        return;
    }
    int index = [[NSNumber numberWithLong:[self.viewsToCycle indexOfObject:sender] ] intValue];
    if(index == 0)return;
    self.viewToShow = self.viewsToCycle[index-1];
    [self.delegate viewDidChange];
}

- (void) createClicked
{
    
    float recurr = [self getReccurence];
    NSInteger recipient = [((toViewCalloutView*)self.viewsToCycle[0]).recipients[0] integerValue];
    float radius = ((sizeViewCalloutView*)self.viewsToCycle[2]).slider.value;
    BOOL arrival = ((whenViewCalloutView*)self.viewsToCycle[1]).arrivalSwitch.on;
    BOOL leave =((whenViewCalloutView*)self.viewsToCycle[1]).leaveSwitch.on;
    
    [self.delegate createClickedRecurr:recurr recipient:recipient radius:radius arrival:arrival leave:leave];
    
}

- (float) getReccurence
{
    
        switch (((whenViewCalloutView*)self.viewsToCycle[1]).recurr.selectedSegmentIndex) {
            case 0://Never
                return 0.0;
                
            case 1://Always
                return 1.0;
                
            default:
                return 0.0;
        }
    
}

- (void) radiusValueChanged:(float)radius
{
    [self.delegate radiusValueChanged:radius];
}

@end
