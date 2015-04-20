//
//  login.m
//  iTrack5
//
//  Created by Dean Leitersdorf on 4/9/15.
//  Copyright (c) 2015 Dean Leitersdorf. All rights reserved.
//

#import "login.h"
#import "socketDealer.h"
#import "AppDelegate.h"
#import "verifyNumber.h"
#import "insertNumber.h"

@interface login()

@property (nonatomic) BOOL proceedDisabled;//after sending to server, disable button to not allow continous resends

@end


@implementation login

- (instancetype) initWithFrame:(CGRect)frame
{
	self = [super initWithFrame:frame];
	if(self)
	{
		
		[[NSBundle mainBundle] loadNibNamed:@"login" owner:self options:nil];
		
		self.frame = frame;
		self.view.frame = CGRectMake(0, 0, frame.size.width, frame.size.height);
		
		
		[self addSubview:self.view];
		
		[self addTouchesForButtons];
        
        //connect to server
        [((AppDelegate*)[[UIApplication sharedApplication] delegate]).socketDealer signUpForEvent:@"usernameEntered" sender:self withSelector:@selector(gotResponse:)];
		
		self.activityIndicator.alpha = self.wrongUserNameView.alpha = 0;
		
		
	}
	return self;
}


- (void) touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
	if(self.proceedDisabled)return;
	UITouch* touch = [touches anyObject];//its fine to use any object, b/c there will always be just 1 object since disabled multiple touches
	CGPoint locInView = [touch locationInView:self.proceedView];
	if(locInView.x > 0 && locInView.y
	   >0 && locInView.x < self.proceedView.frame.size.width && locInView.y < self.proceedView.frame.size.height)
	{
		self.proceedView.alpha = .5;
	}
	
}

- (void) touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
	if(self.proceedDisabled)return;
	self.proceedView.alpha = 1;
}

- (void) touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
	if(self.proceedDisabled)return;
	self.proceedView.alpha = 1;
}

- (void) addTouchesForButtons
{
	UITapGestureRecognizer* gest = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(proceedTapped)];
	[self.proceedView addGestureRecognizer:gest];
	
	
}

- (void) proceedTapped
{
	if(self.proceedDisabled || self.textView.text.length == 0)return;
    [((AppDelegate*)[[UIApplication sharedApplication] delegate]).socketDealer sendEvent:@"/itrack/usernameentered" withData:@{@"name":self.textView.text}];
	self.activityIndicator.alpha = 1;
	[self.activityIndicator startAnimating];
	self.proceedDisabled = YES;
	self.textView.enabled = NO;
	self.proceedView.alpha = .5;//disabled
	self.wrongUserNameView.alpha = 0;
}

- (void) gotResponse:(NSNotification*)notification
{
	NSDictionary* desc = [notification userInfo];
	
	self.activityIndicator.alpha = 0;
	[self.activityIndicator stopAnimating];
	self.proceedDisabled = NO;
	self.textView.enabled = YES;
	self.proceedView.alpha = 1;//enabled
    
    if(![[desc valueForKey:@"nameExists"] boolValue])
    {
        self.wrongUserNameView.alpha = 1;
    }
	else{
		
		if(![[desc valueForKey:@"last4DigitsOfNumber"] boolValue])
		{//user exists, but no phone number on record.
			insertNumber* popup = [[insertNumber alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, self.frame.size.height)];
			[self addSubview: popup];
			popup.name = self.textView.text;
		}
		else{
		verifyNumber* popup = [[verifyNumber alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, self.frame.size.height)];
		[self addSubview: popup];
		popup.name = self.textView.text;
		popup.last4DigitsString = [[NSString stringWithFormat:@"%ld", 10000 + [[desc valueForKey:@"last4DigitsOfNumber"] integerValue]] substringFromIndex:1];//ensure that we give 4 digits (e.g. if number ends in 0089, then desc will store it as 89 -- so, add 10000, turn to string, then substring from index 1 onwards.
		}
	}
}

- (void) unregisterUsernameEntered
{
    [((AppDelegate*)[[UIApplication sharedApplication] delegate]).socketDealer resignEvent:@"usernameEntered" sender:self];
}
- (void) dealloc
{
    [self unregisterUsernameEntered];
}

- (IBAction)backTapped:(id)sender
{
    [self removeFromSuperview];
}

@end
