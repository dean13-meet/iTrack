//
//  insertNumber.m
//  iTrack5
//
//  Created by Dean Leitersdorf on 4/9/15.
//  Copyright (c) 2015 Dean Leitersdorf. All rights reserved.
//

#import "insertNumber.h"
#import "AppDelegate.h"
#import "socketDealer.h"
#import "verifyNumber.h"

@interface insertNumber()

@property (nonatomic) BOOL proceedDisabled;//after sending to server, disable button to not allow continous resends

@end

@implementation insertNumber



- (instancetype) initWithFrame:(CGRect)frame
{
	self = [super initWithFrame:frame];
	if(self)
	{
		
		[[NSBundle mainBundle] loadNibNamed:@"insertNumber" owner:self options:nil];
		
		self.frame = frame;
		self.view.frame = CGRectMake(0, 0, frame.size.width, frame.size.height);
		
		
		[self addSubview:self.view];
		
		[self addTouchesForButtons];
		//listen to server
		[((AppDelegate*)[[UIApplication sharedApplication] delegate]).socketDealer signUpForEvent:@"setPhoneNumber" sender:self withSelector:@selector(gotResponse:)];
		
		self.activityIndicator.alpha= self.invalidNumberView.alpha = 0;
		
		
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
	if(self.proceedDisabled)return;
	
	if([self validateNumber:self.textView.text])
	{
		
		[((AppDelegate*)[[UIApplication sharedApplication] delegate]).socketDealer sendEvent:@"/itrack/setphonenumberforusername" withData:@{@"name":self.name, @"number":self.textView.text, @"shouldAutoCallForVerification":[NSNumber numberWithBool:YES]}];
		self.activityIndicator.alpha = 1;
		[self.activityIndicator startAnimating];
		self.proceedDisabled = YES;
		self.textView.enabled = NO;
		self.proceedView.alpha = .5;//disabled
		self.invalidNumberView.alpha = 0;

	}
	else{
		self.invalidNumberView.alpha = 1;
	}
	
	
}

- (void) gotResponse:(NSNotification*)notification
{
	NSDictionary* desc = [notification userInfo];
	
	self.activityIndicator.alpha = 0;
	[self.activityIndicator stopAnimating];
	/* -- Don't want that: we can only set phone number once!
	self.proceedDisabled = NO;
	self.textView.enabled = YES;
	self.proceedView.alpha = 1;//enabled
	 */
	 
	
	if(![[desc valueForKey:@"success"] boolValue])
	{	//FATAL ERROR::
		//For now, whenever there is an error in setting phone number, treat it as fatal and return to previous view.
		//UNLESS, that error includes "reason":"number_taken"-- that means that some other user has this number, and please
		//choose a new one.
		
		if( [[desc valueForKey:@"reason"] isEqualToString:@"number_taken"])
		{
			UIAlertView * alert =[[UIAlertView alloc ] initWithTitle:@"Error: Number Taken"
															 message:@"Someone else already has this phone number registered! Please enter a different number."
															delegate:self
												   cancelButtonTitle:@"OK"
												   otherButtonTitles: nil];
			
			[alert show];
			
			//enable editing again:
			self.proceedDisabled = NO;
			self.textView.enabled = YES;
			self.proceedView.alpha = 1;//enabled
		}
		else{
		[self backTapped:nil];
		UIAlertView * alert =[[UIAlertView alloc ] initWithTitle:@"Error"
														 message:@"An error occured when setting the number. Please choose another username instead."
														delegate:self
											   cancelButtonTitle:@"OK"
											   otherButtonTitles: nil];
		
			[alert show];}
		
	}
	else{
		verifyNumber* popup = [[verifyNumber alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, self.frame.size.height)];
		[self addSubview: popup];
		popup.name = self.name;
		popup.last4DigitsString = [self.textView.text substringFromIndex:self.textView.text.length-4];
	}
}
- (void) unregisterUsernameEntered
{
	[((AppDelegate*)[[UIApplication sharedApplication] delegate]).socketDealer resignEvent:@"setPhoneNumber" sender:self];
}
- (void) dealloc
{
	[self unregisterUsernameEntered];
}

- (IBAction)backTapped:(id)sender
{
	[self removeFromSuperview];
}




#define NUMBERLENGTH 10
- (BOOL)textField:(UITextField *) textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
	
	NSUInteger oldLength = [textField.text length];
	NSUInteger replacementLength = [string length];
	NSUInteger rangeLength = range.length;
	
	NSUInteger newLength = oldLength - rangeLength + replacementLength;
	
	BOOL returnKey = [string rangeOfString: @"\n"].location != NSNotFound;
	
	if(newLength==NUMBERLENGTH)
	{//enable proceed
		self.proceedDisabled = NO;
		self.proceedView.alpha = 1;
	}
	else
	{
		self.proceedDisabled = YES;//lets first wait till 4 digits are in!!!
		self.proceedView.alpha = .5;
		
	}
	return newLength <= NUMBERLENGTH || returnKey;
}

//from:
- (BOOL)validateNumber:(NSString*)number
{
    if(number.length!=NUMBERLENGTH)return false;
 NSString *digits = @"[0-9]{10}";
 NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", digits];
 return[predicate evaluateWithObject:number];
}

@end
