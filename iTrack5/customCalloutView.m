//
//  customCalloutView.m
//  iTrack5
//
//  Created by Dean Leitersdorf on 2/17/15.
//  Copyright (c) 2015 Dean Leitersdorf. All rights reserved.
//

#import "customCalloutView.h"
#import "mapViewController.h"
#import "MapPinView.h"
#import "MapPin.h"
#import "UTCtoHumanTime.h"

@interface customCalloutView()

@property (strong, nonatomic) calloutViewManager* calloutViewManager;

@end


@implementation customCalloutView

- (instancetype) initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if(self)
    {
        
        [[NSBundle mainBundle] loadNibNamed:@"customCalloutXIB" owner:self options:nil];
        
        self.bounds = self.view.bounds;
        
        [self addSubview:self.view];
        
        [self createDatePickers];
        
        
    }
    return self;
}


- (void) setFence:(Geofence *)fence
{
    _fence = fence;
    if(fence)
    {
        if([fence.setting isEqualToNumber:[NSNumber numberWithInt:2]])//2 = kActive.
            [self.createButton setTitle:editButtonTitle forState:UIControlStateNormal];
        else
            [self.createButton setTitle:makeActiveButtonTitle forState:UIControlStateNormal];
    }
}
- (IBAction)createClicked:(id)sender
{
    
    [self createClickedRecurr:[self getReccurence] recipient:[self.recipientField.text integerValue] radius:self.radiusSlider.value arrival:self.arrivalSwitch.on leave:self.leaveSwitch.on];
    
}

- (void) createClickedRecurr:(float)recurr recipient:(NSInteger)recipient radius:(float)radius arrival:(BOOL)arrival leave:(BOOL)leave
{
    MapPinView* pin = (MapPinView*)self.delegate;
    mapViewController* map = pin.mapVC;
    [map addFenceWithLong:pin.annotation.coordinate.longitude lat:pin.annotation.coordinate.latitude recurr:recurr recipient:recipient address:((MapPin*)pin.annotation).address radius:radius givenFence:self.fence arrival:arrival leave:leave];
    self.editMode = NO;
}

- (void) setEditMode:(BOOL)editMode
{
    if(_editMode==editMode)
        return;
    _editMode = editMode;
    
    
    
    if(editMode)
    {
        [self showView:self.calloutViewManager.viewToShow];
    }
    
    else
    {
        [self showView:self.view];
    }
    
}

- (void) viewDidChange
{
    if(!self.editMode)
        return;
    [self showView:self.calloutViewManager.viewToShow];
    
}

- (void) showView:(UIView*)view
{
    for(UIView* view2 in self.subviews)
    {
        [view2 removeFromSuperview];
    }
    
    [self addSubview:view];
    view.frame = CGRectMake(0, 0, view.frame.size.width, view.frame.size.height);
    self.bounds = self.frame = view.bounds;
    MapPinView* pin = (MapPinView*)self.delegate;
    [pin repositionCalloutView];

}

- (calloutViewManager*) calloutViewManager
{
    if(!_calloutViewManager)
    {
        _calloutViewManager = [[calloutViewManager alloc] init];
        _calloutViewManager.delegate = self;
    }
    return _calloutViewManager;
}

- (float) getReccurence
{
    switch (self.repeatControl.selectedSegmentIndex) {
        case 0://Never
            return 0.0;
            
        case 1://Daily
            return 1.0;
        
        default:
            return 0.0;
    }
}

- (IBAction)sliderValueChanged:(id)sender {
    
    [self.delegate radiusValueChanged];
}

- (void) createDatePickers
{/*
    if (self.keyboardToolbar1 == nil) {
        self.keyboardToolbar1 = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 44)];
        [self.keyboardToolbar1 setBarStyle:UIBarStyleBlackTranslucent];
        
        UIBarButtonItem *extraSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
        
        UIBarButtonItem *accept = [[UIBarButtonItem alloc] initWithTitle:@"Done" style:UIBarButtonItemStyleDone target:self action:@selector(closeKeyboard)];
        
        [self.keyboardToolbar1 setItems:[[NSArray alloc] initWithObjects: extraSpace, accept, nil]];
    }
    
    self.startField.inputAccessoryView = self.keyboardToolbar1;
    
    self.datePicker1 = [[UIDatePicker alloc] init];
    self.datePicker1.datePickerMode = UIDatePickerModeDateAndTime;
    [self.datePicker1 addTarget:self action:@selector(datePickerValueChanged:) forControlEvents:UIControlEventValueChanged];
    
    self.startField.inputView = self.datePicker1;
    
    if (self.keyboardToolbar2 == nil) {
        self.keyboardToolbar2 = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 44)];
        [self.keyboardToolbar2 setBarStyle:UIBarStyleBlackTranslucent];
        
        UIBarButtonItem *extraSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
        
        UIBarButtonItem *accept = [[UIBarButtonItem alloc] initWithTitle:@"Done" style:UIBarButtonItemStyleDone target:self action:@selector(closeKeyboard)];
        
        [self.keyboardToolbar2 setItems:[[NSArray alloc] initWithObjects: extraSpace, accept, nil]];
    }
    
    self.endField.inputAccessoryView = self.keyboardToolbar2;
    
    self.datePicker2 = [[UIDatePicker alloc] init];
    self.datePicker2.datePickerMode = UIDatePickerModeDateAndTime;
    [self.datePicker2 addTarget:self action:@selector(datePickerValueChanged:) forControlEvents:UIControlEventValueChanged];
    
    self.endField.inputView = self.datePicker2;
 */
}

- (void)datePickerValueChanged:(id)sender{
    /*
    if([sender isEqual:self.datePicker1])
    {
        self.date1 = self.datePicker1.date;
    }
    else if([sender isEqual:self.datePicker2])
    {
        self.date2 = self.datePicker2.date;
    }
    */
}
- (IBAction)doneEditing:(UITextField *)sender
{/*
    if([sender isEqual:self.startField])
    {
        self.date1 = self.datePicker1.date;
    }
    else if([sender isEqual:self.endField])
    {
        self.date2 = self.datePicker2.date;
    }*/
}
/*
- (void) setDate1:(NSDate *)date1
{
    _date1 = date1;
    
    [self.startField setText:[UTCtoHumanTime secToLocalTime:date1.timeIntervalSince1970]];
    self.datePicker1.date = date1;
}

- (void) setDate2:(NSDate *)date2
{
    _date2 = date2;
    
    [self.endField setText:[UTCtoHumanTime secToLocalTime:date2.timeIntervalSince1970]];
    self.datePicker2.date = date2;
}*/


- (void) closeKeyboard
{
    [self.view endEditing:YES];
}


- (void) radiusValueChanged:(float)radius
{
    self.radiusSlider.value = radius;
    [self.delegate radiusValueChanged];
}
@end
