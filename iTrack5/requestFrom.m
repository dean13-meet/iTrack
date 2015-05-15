//
//  requestFrom.m
//  iTrack5
//
//  Created by Dean Leitersdorf on 4/11/15.
//  Copyright (c) 2015 Dean Leitersdorf. All rights reserved.
//

#import "requestFrom.h"
#import "AppDelegate.h"
#import "socketDealer.h"
#import "keyboardContacts.h"
#import "Person.h"
#import <AddressBook/AddressBook.h>
#import "mapViewController.h"


@interface requestFrom()

@property (strong, nonatomic) keyboardComplexView* keyboard;
@property (strong, nonatomic) NSString* prevQuery;

@property (nonatomic) BOOL mode; //false = keypad, true = contacts;

@property (strong, nonatomic) NSMutableDictionary* queryCache;//number to username

@end

@implementation requestFrom
- (instancetype) initWithFrame:(CGRect)frame
{
	self = [super initWithFrame:frame];
	if(self)
	{
		
		[[NSBundle mainBundle] loadNibNamed:@"requestFrom" owner:self options:nil];
		
		self.bounds = self.view.bounds;
		
		[self addSubview:self.view];
		
		[self setupToBox];
		
		

	}
	return self;
}

- (void) setupToBox
{
	[self registerForKeyboardNotifications];
	self.toBox.inputView = self.keyboard;
}
- (void)registerForKeyboardNotifications
{
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(keyboardWasShown)
												 name:UIKeyboardDidShowNotification object:nil];
}

-(void)keyboardWasShown
{
	[((keyboardComplexView*)self.toBox.inputView).originalKeypad positionButtons];
}

- (keyboardComplexView*)keyboard
{
	if(!_keyboard)
	{
		_keyboard = [[keyboardComplexView alloc] init];
		_keyboard.delegate = self;
	}
	return _keyboard;
}
		

- (void) backspaceTapped
{
	if(self.toBox.text.length<=0)return;
	self.mode = NO;
	if(self.toBox.text.length<=0)return;//setting mode could have reset text
	self.toBox.text = [self.toBox.text substringToIndex:self.toBox.text.length-1];
}
- (void) keyTapped:(NSString *)key
{
	self.mode = NO;
	self.toBox.text = [self.toBox.text stringByAppendingString:key];
}

- (void) setTextBoxText:(NSString *)string
{
	self.mode = YES;
	self.toBox.text = string;
}

- (void) setMode:(BOOL)mode
{
	if(mode != _mode)
		self.toBox.text = @"";
	_mode = mode;
}
/*
 // Only override drawRect: if you perform custom drawing.
 // An empty implementation adversely affects performance during animation.
 - (void)drawRect:(CGRect)rect {
 // Drawing code
 }
 */
- (IBAction)clickedNext:(id)sender
{
	[super clickedNext];
}


- (IBAction)searchButtonClicked:(id)sender
{
		if(self.toBox.text.length!=0)
	{
		NSString* stringQuery;
		

		if(!self.mode || [self.keyboard.contactsKeyboard.picker numberOfRowsInComponent:0]==0)//we are keypad OR our contacts are empty
			stringQuery = self.toBox.text;
		else
		{
			//This created the popup for selecting from more than 1 number -- just move this somewhere and present.
			keyboardContacts* kC = self.keyboard.contactsKeyboard;
			NSArray* numbers = kC.sortedValues[[kC.picker selectedRowInComponent:0]];
			Person* p = [[Person alloc] init];
			numbers =(__bridge NSArray*)ABMultiValueCopyArrayOfAllValues((__bridge ABMultiValueRef)(numbers));
			NSMutableDictionary* numbersToSelected = @{}.mutableCopy;
			for(id number in numbers)
			{
				[numbersToSelected setValue:[NSNumber numberWithBool:NO] forKey:[NSString stringWithFormat:@"%@", number] ];
			}
			[numbersToSelected setValue:[NSNumber numberWithBool:YES] forKey:numbersToSelected.allKeys[0]];//only the first one is selected
			p.numbers = numbersToSelected;
			p.name = kC.sortedKeys[[kC.picker selectedRowInComponent:0]];
			p.popup = [[personNumbersView alloc] initWithFrame:CGRectMake(0, 0, self.window.frame.size.width*.90, self.window.frame.size.height*.90)];
			p.popup.person = p;
			
			
			for(NSString* key in p.numbers.allKeys)
			{
				if([[p.numbers valueForKey:key] boolValue])
				{
					stringQuery = key;
					break;
				}
			}
			
		}
			//[self.keyboard.contactsKeyboard buttonClicked:nil];//will tell contacts keyboard to add selected row

		if([stringQuery isEqualToString:@""])return;
		stringQuery = [[stringQuery componentsSeparatedByCharactersInSet:[[NSCharacterSet decimalDigitCharacterSet] invertedSet]] componentsJoinedByString:@""];
		
		if([self.queryCache objectForKey:stringQuery])
		{
			[self gotResponse:[self.queryCache objectForKey:stringQuery]];
			return;
		}
		
		[self unRegisterFromPrevTracker];
		[self.activityIndicator startAnimating];
		self.searchButton.alpha = self.searchButton.enabled = 0;
		
		[self signUpForTrackersOnQuery:stringQuery];
		NSNumberFormatter *f = [[NSNumberFormatter alloc] init];
		f.numberStyle = NSNumberFormatterDecimalStyle;
		NSNumber *number = [f numberFromString:stringQuery];
		[((AppDelegate*)[[UIApplication sharedApplication] delegate]).socketDealer sendEvent:@"/itrack/usernamefromquery" withData:@{@"number":number}];
	}
}

- (void) signUpForTrackersOnQuery:(NSString*)query
{
	[((AppDelegate*)[[UIApplication sharedApplication] delegate]).socketDealer signUpForEvent:[NSString stringWithFormat: @"userNameFromQuery:%@", query] sender:self withSelector:@selector(gotResponse:)];
}
- (void) gotResponse:(NSNotification*)notification
{
	NSDictionary* desc = [notification userInfo];
	NSString* query = [[desc valueForKey:@"eventRecieved"] stringByReplacingOccurrencesOfString:@"userNameFromQuery:" withString:@""];
	if(![self.queryCache objectForKey:query])
	{
		[self.queryCache setObject:notification forKey:query];
	}
	
	[self.activityIndicator stopAnimating];
	self.searchButton.alpha = self.searchButton.enabled = 1;
	if([[desc valueForKey:@"success"] boolValue])
	{
		self.resultLabel.text = [desc valueForKey:@"username"];
	}
	else
	{
		self.resultLabel.text = @"No person matches that!";
	}
}

- (void) unRegisterFromPrevTracker
{
	if(!self.prevQuery)return;
	[((AppDelegate*)[[UIApplication sharedApplication] delegate]).socketDealer resignEvent:[NSString stringWithFormat: @"userNameFromQuery:%@", self.prevQuery] sender:self];
	
}
- (void) dealloc
{
	[self unRegisterFromPrevTracker];
}

- (void) addObjectToRecipients:(id)object
{
    //do not - this is a depricated method from keyboard delegate. It's here just to supress warning from xcode.
}
- (IBAction)cancelEdit:(id)sender
{
    [self.delegate cancelEdit];
}
- (NSMutableDictionary*)queryCache
{
	if(!_queryCache)
	{
		_queryCache = [[NSMutableDictionary alloc] init];
	}
	return _queryCache;
}
@end
