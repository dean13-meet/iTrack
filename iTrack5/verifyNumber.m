//
//  verifyNumber.m
//  iTrack5
//
//  Created by Dean Leitersdorf on 4/9/15.
//  Copyright (c) 2015 Dean Leitersdorf. All rights reserved.
//

#import "verifyNumber.h"
#import "AppDelegate.h"
#import "socketDealer.h"
#import "mapViewController.h"
#import "urls.m"

@interface verifyNumber()

@property (nonatomic) BOOL proceedDisabled;//after sending to server, disable button to not allow continous resends

@property (nonatomic) BOOL hardDisableRetry;//prevents retry button from re-enabling when nstimer from - (void) retrySending.

@end


@implementation verifyNumber


#define AUTHLENGTH 4
- (BOOL)textField:(UITextField *) textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
	
	NSUInteger oldLength = [textField.text length];
	NSUInteger replacementLength = [string length];
	NSUInteger rangeLength = range.length;
	
	NSUInteger newLength = oldLength - rangeLength + replacementLength;
	
	BOOL returnKey = [string rangeOfString: @"\n"].location != NSNotFound;
	
	if(newLength==AUTHLENGTH)
	{//enable proceed
		self.proceedDisabled = NO;
		self.proceedView.alpha = 1;
	}
	else
	{
		self.proceedDisabled = YES;//lets first wait till 4 digits are in!!!
		self.proceedView.alpha = .5;

	}
	return newLength <= AUTHLENGTH || returnKey;
}
- (void) setLast4DigitsString:(NSString *)last4DigitsString
{
    _last4DigitsString = last4DigitsString;
    self.last4Digits.text = [NSString stringWithFormat: @"(###) ### - %@", last4DigitsString];
}

- (instancetype) initWithFrame:(CGRect)frame
{
	self = [super initWithFrame:frame];
	if(self)
	{
		
		[[NSBundle mainBundle] loadNibNamed:@"verifyNumber" owner:self options:nil];
		
		self.frame = frame;
		self.view.frame = CGRectMake(0, 0, frame.size.width, frame.size.height);
		
		
		[self addSubview:self.view];
		
		[self addTouchesForButtons];
		
		//connect to server
		[((AppDelegate*)[[UIApplication sharedApplication] delegate]).socketDealer signUpForEvent:@"verifyAuthForUserName" sender:self withSelector:@selector(gotResponse:)];
		self.activityIndicator.alpha = self.wrongAuth.alpha =self.goodAuth.alpha= 0;
		self.proceedDisabled = YES;//lets first wait till 4 digits are in!!!
		self.proceedView.alpha = .5;
		
		
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
	if(self.proceedDisabled || self.textField.text.length != AUTHLENGTH)return;
	[((AppDelegate*)[[UIApplication sharedApplication] delegate]).socketDealer sendEvent:@"/itrack/verifyauthforusername" withData:@{@"name":self.name, @"auth" : self.textField.text}];
	self.activityIndicator.alpha = 1;
	[self.activityIndicator startAnimating];
	self.proceedDisabled = YES;
	self.proceedView.alpha = .5;//disabled
	self.wrongAuth.alpha = 0;
    self.retrySendingButton.enabled = NO;
	self.hardDisableRetry = YES;
	self.textField.enabled = NO;
	[self.textField endEditing:YES];
}

- (void) gotResponse:(NSNotification*)notification
{
	NSDictionary* desc = [notification userInfo];
	
	self.activityIndicator.alpha = 0;
	[self.activityIndicator stopAnimating];
	
	
	if(![[desc valueForKey:@"success"] boolValue])
	{
		self.wrongAuth.alpha = 1;
		
		//its ok to put all this here, b/c we have the 2 second wait if it does succeed (see timer below), so we don't want these enabled. NOTE: DO NOT do the same with the prev popup - that popup isnt the last one, so if you do not always re-enable, if someone presses back from here then they wont be able to use prev popup.
		self.proceedDisabled = NO;
		self.retrySendingButton.enabled = YES;
		self.hardDisableRetry = NO;
		self.textField.enabled = YES;
		self.proceedView.alpha = 1;//enabled
	}
	else{
		self.goodAuth.alpha = 1;
		NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
		[defaults setObject:[desc valueForKey:@"userUUID"] forKey:userUUIDDefaultsURL];
		[defaults setObject:[desc valueForKey:@"username"] forKey:usernameDefaultsURL];
		[defaults synchronize];

		[NSTimer scheduledTimerWithTimeInterval:1.0
										 target:self
									   selector:@selector(close)
									   userInfo:nil
										repeats:NO];
		//[self unregisterUsernameEntered];//unregister only if success.
	}
}

- (void) unregisterUsernameEntered
{
	[((AppDelegate*)[[UIApplication sharedApplication] delegate]).socketDealer resignEvent:@"verifyAuthForUserName" sender:self];
}
- (void) dealloc
{
	[self unregisterUsernameEntered];
}

- (IBAction)backTapped:(id)sender
{
	[self removeFromSuperview];
}

- (IBAction)retrySending:(id)sender
{
    [((AppDelegate*)[[UIApplication sharedApplication] delegate]).socketDealer sendEvent:@"/itrack/retryvalidation" withData:@{@"name":self.name}];
	self.retrySendingButton.enabled = NO;
	[NSTimer scheduledTimerWithTimeInterval:5.0
									 target:self
								   selector:@selector(reEnableRefresh)
								   userInfo:nil
									repeats:NO];
}
- (void) reEnableRefresh
{
	if(!self.hardDisableRetry)
		self.retrySendingButton.enabled = YES;
	//Yeah, yeah - the above can be simplified, but this is more understandable...
}
- (void) close
{
	[((mapViewController*)mapVCFromAppDelegate) dismissSignInPopup];
}

@end
