//
//  customCalloutView.h
//  iTrack5
//
//  Created by Dean Leitersdorf on 2/17/15.
//  Copyright (c) 2015 Dean Leitersdorf. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Geofence.h"

#import "calloutViewManager.h"



@protocol customCalloutViewDelegate <NSObject>

-(void)radiusValueChanged;

@end

@interface customCalloutView : UIView <calloutViewManagerDelegate>

@property (strong, nonatomic) IBOutlet UIView *view;

@property (weak, nonatomic) IBOutlet UILabel *addressLabel;
@property (weak, nonatomic) IBOutlet UITextField *recipientField;
/*
@property (weak, nonatomic) IBOutlet UITextField *startField;
@property (weak, nonatomic) IBOutlet UITextField *endField;*/
@property (weak, nonatomic) IBOutlet UISegmentedControl *repeatControl;
@property (weak, nonatomic) IBOutlet UISlider *radiusSlider;
@property (weak, nonatomic) IBOutlet UIButton *createButton;

/*
@property (strong, nonatomic) UIDatePicker *datePicker1;
@property (strong, nonatomic) NSDate *date1;
@property (strong, nonatomic) UIToolbar *keyboardToolbar1;

@property (strong, nonatomic) UIDatePicker *datePicker2;
@property (strong, nonatomic) NSDate *date2;
@property (strong, nonatomic) UIToolbar *keyboardToolbar2;
*/
@property (weak, nonatomic) IBOutlet UISwitch *arrivalSwitch;
@property (weak, nonatomic) IBOutlet UISwitch *leaveSwitch;

- (IBAction)createClicked:(id)sender;
- (IBAction)sliderValueChanged:(id)sender;

- (void) radiusValueChanged:(float)radius;//delegate method ( from calloutViewManagerDelegate)

@property (nonatomic) id<customCalloutViewDelegate> delegate;


@property (nonatomic) BOOL editMode;


//CalloutSetting
typedef enum {
    kNew,
    kEdit,
    kMakeActive
} CalloutSetting;

/*
 Types of Titles:
 
 
 New
 */
#define newButtonTitle @"Create"/*

 Edit
 */
 #define editButtonTitle @"Save Changes"/*

 Make Active
 */
 #define makeActiveButtonTitle @"Activate"/*

*/



@property (strong, nonatomic) Geofence* fence;


@end
