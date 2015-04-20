//
//  signInPopup.m
//  iTrack5
//
//  Created by Dean Leitersdorf on 4/9/15.
//  Copyright (c) 2015 Dean Leitersdorf. All rights reserved.
//

#import "signInPopup.h"
#import "login.h"
#import "signUp.h"

@implementation signInPopup

- (instancetype) initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if(self)
    {
        
        [[NSBundle mainBundle] loadNibNamed:@"signInPopup" owner:self options:nil];
        
        self.frame = frame;
        self.view.frame = CGRectMake(0, 0, frame.size.width, frame.size.height);
        
        
        [self addSubview:self.view];
        
        [self addTouchesForButtons];
        
        
    }
    return self;
}

//make logIn/signUp views dim when tap down

- (void) touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch* touch = [touches anyObject];//its fine to use any object, b/c there will always be just 1 object since disabled multiple touches
    CGPoint locInView = [touch locationInView:self.logInView];
    if(locInView.x > 0 && locInView.y
        >0 && locInView.x < self.logInView.frame.size.width && locInView.y < self.logInView.frame.size.height)
    {
        self.logInView.alpha = .5;
    }
    else
    {
        locInView = [touch locationInView:self.signUpView];
        if(locInView.x > 0 && locInView.y
           >0 && locInView.x < self.signUpView.frame.size.width && locInView.y < self.signUpView.frame.size.height)
        {
            self.signUpView.alpha = .5;
        }
    }
}

- (void) touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    self.logInView.alpha = self.signUpView.alpha = 1;
}

- (void) touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    self.logInView.alpha = self.signUpView.alpha = 1;
}

- (void) addTouchesForButtons
{
    UITapGestureRecognizer* gest = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(logInTapped)];
    [self.logInView addGestureRecognizer:gest];
    UITapGestureRecognizer* gest2 = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(signInTapped)];
    [self.signUpView addGestureRecognizer:gest2];
    
    
}

- (void) logInTapped
{
	login* popupLogin = [[login alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, self.frame.size.height)];
	[self addSubview: popupLogin];
}

- (void) signInTapped
{
	signUp* popupSignUp = [[signUp alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, self.frame.size.height)];
	[self addSubview: popupSignUp];
}

@end
