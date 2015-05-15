//
//  keyboardContacts.m
//  iTrack5
//
//  Created by Dean Leitersdorf on 3/18/15.
//  Copyright (c) 2015 Dean Leitersdorf. All rights reserved.
//

#import "keyboardContacts.h"
#import <AddressBook/AddressBook.h>
#import "Person.h"

@interface keyboardContacts()

@property (strong, nonatomic) NSMutableDictionary* contacts;

@property (nonatomic) BOOL areContactsSorted;
@property (nonatomic) NSInteger prevSelectedNumber;//stores the currently selected row #

@end


@implementation keyboardContacts


- (instancetype) initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if(self)
    {
        
        [[NSBundle mainBundle] loadNibNamed:@"keyboardContacts" owner:self options:nil];
        
		self.frame = frame;
		self.view.frame = self.bounds;
		
        [self addSubview:self.view];
        
        
        //picker:
        [self loadContacts];
        self.picker.dataSource = self;
        self.picker.delegate = self;
		self.settingsButton.selected = YES;
        
        
    }
    return self;
}

-(void) loadContacts
{
    
    CFErrorRef error = NULL;
    ABAddressBookRef addressBook = ABAddressBookCreateWithOptions(NULL, &error);
    __block BOOL accessGranted = NO;
    
    if (ABAddressBookRequestAccessWithCompletion != NULL) { // We are on iOS 6
        dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
        
        ABAddressBookRequestAccessWithCompletion(addressBook, ^(bool granted, CFErrorRef error) {
            accessGranted = granted;
            dispatch_semaphore_signal(semaphore);
        });
        
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    }
	
 
	if(ABAddressBookGetAuthorizationStatus()==kABAuthorizationStatusDenied || ABAddressBookGetAuthorizationStatus()==kABAuthorizationStatusRestricted|| ABAddressBookGetAuthorizationStatus()==kABAuthorizationStatusNotDetermined || !accessGranted)
	{
		self.settingsView.hidden = NO;
		self.settingsView.userInteractionEnabled = YES;
		return;
	}
		
		
    if (addressBook != nil){
        NSLog(@"Succesful.");
        
        [self.contacts removeAllObjects];
        self.areContactsSorted = NO;
    
    
    CFArrayRef allPeople = ABAddressBookCopyArrayOfAllPeople( addressBook );
    CFIndex nPeople = ABAddressBookGetPersonCount( addressBook );
        
    
    for ( int i = 0; i < nPeople; i++ )
    {
        ABRecordRef ref = CFArrayGetValueAtIndex( allPeople, i );
        ABMultiValueRef numbers =(__bridge ABMultiValueRef)((__bridge NSString*)ABRecordCopyValue(ref, kABPersonPhoneProperty));
        if(ABMultiValueGetCount(numbers)==0)continue;
        CFStringRef firstName, lastName;
        firstName = ABRecordCopyValue(ref, kABPersonFirstNameProperty);
        lastName  = ABRecordCopyValue(ref, kABPersonLastNameProperty);
        if(firstName == nil && lastName==nil)
            continue;
        if(firstName==nil)firstName = (__bridge CFStringRef)@"";
        else if(lastName==nil)lastName = (__bridge CFStringRef)@"";
        [self.contacts setObject:CFBridgingRelease(numbers) forKey: [NSString stringWithFormat:@"%@ %@", firstName, lastName]];
    }
    }
}

// The number of columns of data
- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    return 1;
}

// The number of rows of data
- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
    return self.contacts.count;
}

// The data to return for the row and component (column) that's being passed in
- (NSString*)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    return self.sortedKeys[row];
}

- (void) sortContacts
{
    self.areContactsSorted = YES;
    [self setSortedKeys: [[self.contacts allKeys] sortedArrayUsingSelector: @selector(caseInsensitiveCompare:)]];
    [self setSortedValues:[self.contacts objectsForKeys: self.sortedKeys notFoundMarker: [NSNull null]]];
    
    [self.picker reloadAllComponents];
}

- (NSArray*)sortedKeys
{
    if(!self.areContactsSorted)
    {
        [self sortContacts];
    }
    return _sortedKeys;
}

- (NSArray*)sortedValue
{
    if(!self.areContactsSorted)
    {
        [self sortContacts];
    }
    return _sortedValues;
}

- (NSMutableDictionary*)contacts
{
    if(!_contacts)
    {
        _contacts = [[NSMutableDictionary alloc] init];
    }
    return _contacts;
}

- (IBAction)buttonClicked:(UIButton *)sender
{
    NSArray* numbers = self.sortedValues[[self.picker selectedRowInComponent:0]];
    Person* p = [[Person alloc] init];
    numbers =(__bridge NSArray*)ABMultiValueCopyArrayOfAllValues((__bridge ABMultiValueRef)(numbers));
    NSMutableDictionary* numbersToSelected = @{}.mutableCopy;
    for(id number in numbers)
    {
        [numbersToSelected setValue:[NSNumber numberWithBool:YES] forKey:[NSString stringWithFormat:@"%@", number] ];
    }
    p.numbers = numbersToSelected;
    p.name = self.sortedKeys[[self.picker selectedRowInComponent:0]];
    p.popup = [[personNumbersView alloc] initWithFrame:CGRectMake(0, 0, self.window.frame.size.width*.90, self.window.frame.size.height*.90)];
    p.popup.person = p;
    
    [self.delegate addObjectToRecipients:p];
}

- (void) pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
	if(row>=self.sortedKeys.count)return;
    [self.delegate setTextBoxText:self.sortedKeys[row]];
    self.prevSelectedNumber = row;
	[self.slider setValue:(((double)row/(self.sortedKeys.count -1))*self.slider.maximumValue) animated:YES];
}
- (IBAction)sliderChanged:(UISlider *)sender
{
    NSInteger row = (sender.value/sender.maximumValue)*(self.sortedKeys.count-1);
    if(row == self.prevSelectedNumber)return;//if sliding didn't change rows, just return. Also, I'm storing prevSelectedNumber as a property, so that I don't have to call self.pickerView selectedRow.... every time.
    //if(abs([[NSNumber numberWithInteger:row - [[NSNumber numberWithInteger:[self.picker selectedRowInComponent:0]] integerValue]] intValue])<1)return;//if the slider hasn't changed more than 10 contacts apart from current row, dont scroll.
	if(row>=self.sortedKeys.count || row < 0)return;
    [self.picker selectRow:row inComponent:0 animated:NO];
    [self pickerView:self.picker didSelectRow:row inComponent:0];
}
- (IBAction)settingsClicked:(id)sender
{
	[[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
}
@end
