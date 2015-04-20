//
//  keyboardComplexView.h
//  iTrack5
//
//  Created by Dean Leitersdorf on 3/16/15.
//  Copyright (c) 2015 Dean Leitersdorf. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "keyboardNumberPad.h"
#import "keyboardContacts.h"

@protocol keyboardComplexViewDelegate <NSObject>

- (void) keyTapped:(NSString*)key;
- (void) backspaceTapped;
- (void) addObjectToRecipients:(id)object;
- (void) setTextBoxText:(NSString *)string;

@end

@interface keyboardComplexView : UIView <UIInputViewAudioFeedback, numberPadDelegate, keyboardContactsDelegate>
@property (weak, nonatomic) IBOutlet UIView *viewForKeyboard;
@property (strong, nonatomic) keyboardNumberPad* originalKeypad;
@property (strong, nonatomic) keyboardContacts* contactsKeyboard;
- (IBAction)switchToKeypad:(UIBarButtonItem *)sender;
- (IBAction)switchToContacts:(UIBarButtonItem *)sender;
@property (weak, nonatomic) IBOutlet UIToolbar *toolbar;
@property (strong, nonatomic) IBOutlet UIView *view;

- (void) keyTapped:(NSString*)key;
- (void) backspaceTapped;
- (void) setTextBoxText:(NSString *)string;
- (void) addObjectToRecipients:(id)object;

@property (strong, nonatomic) id<keyboardComplexViewDelegate> delegate;
@end
