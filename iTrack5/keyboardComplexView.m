//
//  keyboardComplexView.m
//  iTrack5
//
//  Created by Dean Leitersdorf on 3/16/15.
//  Copyright (c) 2015 Dean Leitersdorf. All rights reserved.
//

#import "keyboardComplexView.h"

@implementation keyboardComplexView

- (instancetype) initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if(self)
    {
        
        [[NSBundle mainBundle] loadNibNamed:@"keyboardComplexView" owner:self options:nil];
        
        self.bounds = self.view.bounds;
        
        [self addSubview:self.view];
        
        self.originalKeypad = [[keyboardNumberPad alloc] initWithFrame:self.viewForKeyboard.frame];
        [self.originalKeypad positionButtons];
        self.originalKeypad.delegate = self;//to make sure we recieve keyboard taps
        
        
    }
    return self;
}

- (IBAction)switchToKeypad:(UIBarButtonItem *)sender {
    [self.viewForKeyboard removeFromSuperview];
    self.viewForKeyboard = self.originalKeypad;
    [self addSubview:self.viewForKeyboard];
}

- (IBAction)switchToContacts:(UIBarButtonItem *)sender {
    [self.viewForKeyboard removeFromSuperview];
    self.viewForKeyboard = self.contactsKeyboard;
    [self addSubview:self.viewForKeyboard];
    
}

- (void) setOriginalKeypad:(keyboardNumberPad *)originalKeypad
{
    _originalKeypad = originalKeypad;
    [self switchToKeypad:nil];
    
}

- (keyboardContacts*)contactsKeyboard
{
    if(!_contactsKeyboard)
    {
        _contactsKeyboard = [[keyboardContacts alloc] initWithFrame:self.viewForKeyboard.frame];
        _contactsKeyboard.delegate = self;
    }
    return _contactsKeyboard;
}

- (BOOL) enableInputClicksWhenVisible
{
    return YES;
}

//Just keep sending it up - we only manage the keyboards, not the textfield itself. Delegate should take whatever we send and edit the textfield. OR in the case of the contacts keyboard, it must be able to add the recipeint to the table view
- (void) backspaceTapped
{
    [self.delegate backspaceTapped];
}
- (void) keyTapped:(NSString *)key
{
    [self.delegate keyTapped:key];
}
- (void) addObjectToRecipients:(id)object
{
    [self.delegate addObjectToRecipients:object];
}
- (void) setTextBoxText:(NSString *)string
{
    [self.delegate setTextBoxText:string];
}
@end
