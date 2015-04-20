//
//  customCalloutView.m
//  iTrack5
//
//  Created by Dean Leitersdorf on 2/17/15.
//  Copyright (c) 2015 Dean Leitersdorf. All rights reserved.
//

#import "customCalloutView.h"
#import "mapViewController.h"
#import "MapPinView.h"
#import "MapPin.h"
#import "UTCtoHumanTime.h"
#import "urls.m"
#import "recCell.h"
#import "Person.h"
#import "AppDelegate.h"



@interface customCalloutView()

@property (strong, nonatomic) calloutViewManager* calloutViewManager;
@property (weak, nonatomic) IBOutlet UILabel *addressLabel;

@property (strong, nonatomic) NSArray* recs;


@property (nonatomic) double lastCircleChangeTime;


@end


@implementation customCalloutView

- (instancetype) initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if(self)
    {
        
        [[NSBundle mainBundle] loadNibNamed:@"customCalloutXIB2" owner:self options:nil];
        
        self.bounds = self.view.bounds;
        
        [self addSubview:self.view];
        
        [self createDatePickers];
		
		[self updateTableView];
        
        
    }
    return self;
}


- (void) setFence:(Geofence *)fence
{
    _fence = fence;
    if(fence)
    {
        if([fence.setting isEqualToNumber:[NSNumber numberWithInt:kActive]])
		{
            [self.createButton setTitle:deactivateButtonTitle forState:UIControlStateNormal];
			self.editButton.hidden = NO;
			[self.editButton setEnabled:YES];
			self.editButton.alpha = 1;
		}
        else
		{
            [self.createButton setTitle:makeActiveButtonTitle forState:UIControlStateNormal];
			self.editButton.hidden = YES;
			[self.editButton setEnabled:NO];
			self.editButton.alpha = 0;
    
		}
		
        //Pending label:
        if(![fence.requestApproved isEqualToString:@"Pending"])
        {
			self.pendingLabel.alpha = 0;
        }
		
		[self updateTableView];
    
    }
    
}
- (IBAction)createClicked:(id)sender //if sender == [NSNumber numberWithInt:234567] settings will not update!
{
	BOOL needSave;
    if([self.createButton.titleLabel.text isEqualToString:deactivateButtonTitle])
	{
		self.fence.setting = [NSNumber numberWithInt:kCompleted];
		self.editButton.hidden = YES;
		[self.editButton setEnabled:NO];
		self.editButton.alpha = 0;
		needSave = YES;
	}
	else if([self.createButton.titleLabel.text isEqualToString:makeActiveButtonTitle])
	{
		self.fence.setting = [NSNumber numberWithInt:kActive];
		self.editButton.hidden = NO;
		[self.editButton setEnabled:YES];
		self.editButton.alpha = 1;
		needSave = YES;
		
		
		NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
		NSString* username = [defaults valueForKey:usernameDefaultsURL];
		if(![self.fence.owner isEqualToString:username])
		{
			UIAlertView * alert =[[UIAlertView alloc ] initWithTitle:@"Success!"
															 message:@"Your changes have been saved! However, the person you requested the location notification from will have to accept your request before it can be activated!"
															delegate:self
												   cancelButtonTitle:@"OK"
												   otherButtonTitles: nil];
			
			[alert show];
		}
	}
	if(needSave && !([sender isKindOfClass:[NSNumber class]] && [[NSNumber numberWithInt:234567] isEqualToNumber:sender]))
	{
		mapViewController* mapVC = (mapViewController*) mapVCFromAppDelegate;
		[mapVC save];
	}
    //[self createClickedRecurr:[self getReccurence] recipients:[self.recipientField.text componentsSeparatedByString:@", "] radius:self.radiusSlider.value arrival:self.arrivalSwitch.on leave:self.leaveSwitch.on shouldUpdateSetting:!([sender isKindOfClass:[NSNumber class]] && [[NSNumber numberWithInt:234567] isEqualToNumber:sender]) requestingFrom:nil];
    
}
- (void) cancelEdit
{
	MapPinView* pin = (MapPinView*)self.delegate;
	mapViewController* map = pin.mapVC;
	if([map.mapSettingEnums[kSearch] boolValue])
	{
		//if it's on search mode, and we got "cancelEdit", it means destroy the current pin and turn off search mode
		[map destoryDraggedSearchPin];
	}
	else
		self.editMode = NO;
}

- (void) createClickedRecurr:(float)recurr recipients:(NSArray*)recs radius:(float)radius arrival:(BOOL)arrival leave:(BOOL)leave shouldUpdateSetting:(BOOL)shouldUpdateSetting requestingFrom:(NSString*)requestingFrom
{
    MapPinView* pin = (MapPinView*)self.delegate;
    mapViewController* map = pin.mapVC;
    if(shouldUpdateSetting&& [map.currentlyDraggedAnnotation isEqual:pin.annotation])//if shouldUpdateSetting, then the pin becomes active. If setting shouldn't be updated, it means we are dragging the pin around and address was changed
    {
        [map.additionalAnnotationsToShow removeObject:pin.annotation];
        map.currentlyDraggedAnnotation = nil;
    }
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSString* username = [defaults valueForKey:usernameDefaultsURL];
	NSString* userUUID = [defaults valueForKey:userUUIDDefaultsURL];
	[map addFenceWithLong:pin.annotation.coordinate.longitude lat:pin.annotation.coordinate.latitude recurr:recurr recipients:recs address:((MapPin*)pin.annotation).address radius:radius givenFence:self.fence arrival:arrival leave:leave shouldChangeMapSetting:shouldUpdateSetting optionalIdentifier:nil arrivalMessage:nil leaveMessage:nil arrivalsSent:nil leavesSent:nil forceSave:YES optionalSetSetting:nil owner:requestingFrom ? requestingFrom:username requester:requestingFrom?userUUID:nil optionalRequestApproved:nil fenceWasSyncedDownFromServer:NO];
    if(shouldUpdateSetting)
        self.editMode = NO;
}

- (void) setEditMode:(BOOL)editMode
{
    if(_editMode==editMode)
        return;
    _editMode = editMode;
    
    
    
    if(editMode)
    {
		BOOL should = self.fence.requester && ![self.fence.requester isEqualToString:@""];
		self.calloutViewManager.skipFirstView = should;
		self.calloutViewManager.takeThisFence = self.fence;
		MapPinView* pin = (MapPinView*) self.delegate;
		pin.draggable = YES;
        [self showView:self.calloutViewManager.viewToShow];
		
    }
    
    else
    {
		MapPinView* pin = (MapPinView*) self.delegate;
		pin.draggable = NO;
		[self.calloutViewManager resetViewToShow];
        [self showView:self.view];
		
    }
    
}

- (void) viewDidChange
{
    if(!self.editMode)
        return;
    [self showView:self.calloutViewManager.viewToShow];
    
}

- (void) showView:(UIView*)view
{
    for(UIView* view2 in self.subviews)
    {
        [view2 removeFromSuperview];
    }
    
	
	CGRect target = view.bounds;
	self.bounds = target;
	CGRect target1 = CGRectMake(0, 0, view.frame.size.width, view.frame.size.height);;
	view.frame = target1;
	view.bounds = target1;
	self.clipsToBounds = YES;
	[self addSubview:view];
    MapPinView* pin = (MapPinView*)self.delegate;
    [pin repositionCalloutView];

}

- (calloutViewManager*) calloutViewManager
{
    if(!_calloutViewManager)
    {
        _calloutViewManager = [[calloutViewManager alloc] init];
        _calloutViewManager.delegate = self;
    }
    return _calloutViewManager;
}

- (float) getReccurence
{
    switch (self.repeatControl.selectedSegmentIndex) {
        case 0://Never
            return 0.0;
            
        case 1://Daily
            return 1.0;
        
        default:
            return 0.0;
    }
}

- (IBAction)sliderValueChanged:(id)sender {
    
    [self.delegate updateCircle];
}

@synthesize radius = _radius;
- (float)radius
{
	[self verifyRadius];
	
	return _radius;
}


- (void) verifyRadius
{
	if(_radius == 0)_radius = 50;//default start value
	if(_radius < 10)_radius = 10;//min value
	if(_radius>1000)_radius = 1000;//max value
}

- (void) createDatePickers
{/*
    if (self.keyboardToolbar1 == nil) {
        self.keyboardToolbar1 = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 44)];
        [self.keyboardToolbar1 setBarStyle:UIBarStyleBlackTranslucent];
        
        UIBarButtonItem *extraSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
        
        UIBarButtonItem *accept = [[UIBarButtonItem alloc] initWithTitle:@"Done" style:UIBarButtonItemStyleDone target:self action:@selector(closeKeyboard)];
        
        [self.keyboardToolbar1 setItems:[[NSArray alloc] initWithObjects: extraSpace, accept, nil]];
    }
    
    self.startField.inputAccessoryView = self.keyboardToolbar1;
    
    self.datePicker1 = [[UIDatePicker alloc] init];
    self.datePicker1.datePickerMode = UIDatePickerModeDateAndTime;
    [self.datePicker1 addTarget:self action:@selector(datePickerValueChanged:) forControlEvents:UIControlEventValueChanged];
    
    self.startField.inputView = self.datePicker1;
    
    if (self.keyboardToolbar2 == nil) {
        self.keyboardToolbar2 = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 44)];
        [self.keyboardToolbar2 setBarStyle:UIBarStyleBlackTranslucent];
        
        UIBarButtonItem *extraSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
        
        UIBarButtonItem *accept = [[UIBarButtonItem alloc] initWithTitle:@"Done" style:UIBarButtonItemStyleDone target:self action:@selector(closeKeyboard)];
        
        [self.keyboardToolbar2 setItems:[[NSArray alloc] initWithObjects: extraSpace, accept, nil]];
    }
    
    self.endField.inputAccessoryView = self.keyboardToolbar2;
    
    self.datePicker2 = [[UIDatePicker alloc] init];
    self.datePicker2.datePickerMode = UIDatePickerModeDateAndTime;
    [self.datePicker2 addTarget:self action:@selector(datePickerValueChanged:) forControlEvents:UIControlEventValueChanged];
    
    self.endField.inputView = self.datePicker2;
 */
}

- (void)datePickerValueChanged:(id)sender{
    /*
    if([sender isEqual:self.datePicker1])
    {
        self.date1 = self.datePicker1.date;
    }
    else if([sender isEqual:self.datePicker2])
    {
        self.date2 = self.datePicker2.date;
    }
    */
}
- (IBAction)doneEditing:(UITextField *)sender
{/*
    if([sender isEqual:self.startField])
    {
        self.date1 = self.datePicker1.date;
    }
    else if([sender isEqual:self.endField])
    {
        self.date2 = self.datePicker2.date;
    }*/
}
/*
- (void) setDate1:(NSDate *)date1
{
    _date1 = date1;
    
    [self.startField setText:[UTCtoHumanTime secToLocalTime:date1.timeIntervalSince1970]];
    self.datePicker1.date = date1;
}

- (void) setDate2:(NSDate *)date2
{
    _date2 = date2;
    
    [self.endField setText:[UTCtoHumanTime secToLocalTime:date2.timeIntervalSince1970]];
    self.datePicker2.date = date2;
}*/


- (void) closeKeyboard
{
    [self.view endEditing:YES];
}


- (void) radiusValueChanged:(float)radius
{
    //self.radiusSlider.value = radius;
	if(abs(_radius-radius)<20)return;
	//double currentTime = [[NSDate date] timeIntervalSince1970];
	//if(currentTime-self.lastCircleChangeTime<.3)return;
	//self.lastCircleChangeTime = currentTime;
	_radius = radius;
	[self verifyRadius];
    [self.delegate updateCircle];
}
- (void) setAddresLabelText:(NSString*)text
{
    self.addressLabel.text = text;
    [self.calloutViewManager addressUpdated];
}

/*
 Alert tags
 
 1 == Delete alert
 */
- (IBAction)deleteClicked
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Delete Location" message:@"Are you sure you want to stop monitoring this location?" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:nil];
    // optional - add more buttons:
    [alert addButtonWithTitle:@"Yes"];
    [alert setTag:1];
    [alert show];
}
- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if ([alertView tag] == 1) {    // Delete alert
        if (buttonIndex == 1) {     // YES
            [((MapPinView*)self.delegate).mapVC deleteFence:((MapPinView*)self.delegate).annotation.fence notifyServer:YES];
        }
    }
}



#pragma mark recs

- (NSArray*)recs
{
	if(!_recs)
	{
		_recs = [mapViewController recsFromFenceData:self.fence.recipients];
		for(id rec in _recs)
		{
			if([rec isKindOfClass:[Person class]])
			{
				Person* p = rec;
				p.popup = [[personNumbersView alloc] initWithFrame:CGRectMake(0, 0, self.window.frame.size.width*.90, self.window.frame.size.height*.90)];
				p.popup.person = p;
				p.popup.disableSelection = YES;
			}
		}
	}
	return _recs;
}

- (void) updateTableView
{
	[self.tableView reloadData];
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return [self.recs count];
}
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return 1;
}
- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	NSString *CellIdentifier = @"recCell2";
	recCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
	if(!cell || (![cell isKindOfClass: recCell.class]))
	{/*
	  NSArray *nib = [[NSBundle mainBundle] loadNibNamed:CellIdentifier owner:self options:nil];
	  cell = [nib objectAtIndex:0];*/
		
		[tableView registerNib:[UINib nibWithNibName:CellIdentifier bundle:nil] forCellReuseIdentifier:CellIdentifier];
		cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
	}
	id recipient = self.recs[indexPath.row];
	if([recipient isKindOfClass:[Person class]])
	{
		Person* person = recipient;
		cell.titleLabel.text = person.name;
		cell.accessoryType = UITableViewCellAccessoryDetailButton;
		
		
	}else{
		cell.titleLabel.text = recipient;
	}
	
	[cell disableX];
	
	return cell;
}

- (void) tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath
{
	personNumbersView* popup = ((Person*)self.recs[indexPath.row]).popup;
	popup.frame = CGRectMake(0, 0, self.window.frame.size.width*.90, self.window.frame.size.height*.90);
	CGRect targetFrame = CGRectMake((self.window.frame.size.width - popup.frame.size.width)/2, (self.window.frame.size.height-popup.frame.size.height)/2, popup.frame.size.width, popup.frame.size.height);
	
	popup.frame = targetFrame;
	popup.transform = CGAffineTransformMakeScale(.2, .2);
	[self.window addSubview:popup];
	[UIView animateWithDuration:.2 animations:^{
		popup.transform = CGAffineTransformMakeScale(1, 1);
	}];
	
}
- (IBAction)editClicked:(id)sender
{
	self.editMode = YES;
}
- (void) showToViewCancelButton
{
	[self.calloutViewManager showToViewCancelButton];
}
@end
