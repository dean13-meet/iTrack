//
//  keyboardContacts.h
//  iTrack5
//
//  Created by Dean Leitersdorf on 3/18/15.
//  Copyright (c) 2015 Dean Leitersdorf. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol keyboardContactsDelegate <NSObject>

- (void) addObjectToRecipients:(id)object;
- (void) setTextBoxText:(NSString*)string;

@end

@interface keyboardContacts : UIView <UIPickerViewDataSource, UIPickerViewDelegate>
@property (strong, nonatomic) IBOutlet UIView *view;
@property (weak, nonatomic) IBOutlet UIPickerView *picker;
- (IBAction)buttonClicked:(UIButton *)sender;
@property (weak, nonatomic) IBOutlet UISlider *slider;

@property (strong, nonatomic) id<keyboardContactsDelegate> delegate;
@property (strong, nonatomic) NSArray* sortedKeys;//first last name
@property (strong, nonatomic) NSArray* sortedValues;//phone numbers
@property (weak, nonatomic) IBOutlet UIView *settingsView;
@property (weak, nonatomic) IBOutlet UIButton *settingsButton;
- (IBAction)settingsClicked:(id)sender;

@end
