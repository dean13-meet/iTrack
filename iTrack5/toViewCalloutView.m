//
//  toViewCalloutView.m
//  iTrack5
//
//  Created by Dean Leitersdorf on 3/2/15.
//  Copyright (c) 2015 Dean Leitersdorf. All rights reserved.
//

#import "toViewCalloutView.h"
#import "Person.h"
#import "personNumbersView.h"




@interface toViewCalloutView()

@property (strong, nonatomic) keyboardComplexView* keyboard;

@property (nonatomic) BOOL mode; //false = keypad, true = contacts;

@end

@implementation toViewCalloutView

- (instancetype) initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if(self)
    {
        
        [[NSBundle mainBundle] loadNibNamed:@"toViewView" owner:self options:nil];
        
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
	self.mode = NO;
    if(self.toBox.text.length<=0)return;
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


- (IBAction)addRec:(id)sender
{
    if([self.toBox.text isEqualToString:@""])return;
    if(!self.mode)//keypad
        [self addObjectToRecipients:self.toBox.text];
    else
        [self.keyboard.contactsKeyboard buttonClicked:nil];//will tell contacts keyboard to add selected row
    
}

- (void) addObjectToRecipients:(id)object
{
    if([self.recipients containsObject:object])return;
    [self.recipients insertObject:object atIndex:0];
    [self updateTableView];
    self.toBox.text = @"";
}

- (NSMutableArray*)recipients
{
    if(!_recipients)
    {
        _recipients = [[NSMutableArray alloc] init];
    }
    return _recipients;
}
- (void) updateTableView
{
    [self.tableView reloadData];
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.recipients count];
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
    id recipient = self.recipients[indexPath.row];
    if([recipient isKindOfClass:[Person class]])
    {
        Person* person = recipient;
        cell.titleLabel.text = person.name;
        cell.accessoryType = UITableViewCellAccessoryDetailButton;
        
        
    }else{
        cell.titleLabel.text = recipient;
        }
    cell.delegate = self;
    return cell;
}

- (void) tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath
{
    personNumbersView* popup = ((Person*)self.recipients[indexPath.row]).popup;
    popup.frame = CGRectMake(0, 0, self.window.frame.size.width*.90, self.window.frame.size.height*.90);
    CGRect targetFrame = CGRectMake((self.window.frame.size.width - popup.frame.size.width)/2, (self.window.frame.size.height-popup.frame.size.height)/2, popup.frame.size.width, popup.frame.size.height);
    
    popup.frame = targetFrame;
    popup.transform = CGAffineTransformMakeScale(.2, .2);
	[self.window addSubview:popup];
    [UIView animateWithDuration:.2 animations:^{
        popup.transform = CGAffineTransformMakeScale(1, 1);
    }];
	
    [self.toBox endEditing:YES];
}
- (BOOL)tableView:(UITableView *)tableView shouldHighlightRowAtIndexPath:(NSIndexPath *)indexPath
{
	return NO;
}

- (void) deleteSelfWithSender:(id)sender
{
    NSIndexPath* index = [self.tableView indexPathForCell:sender];
    [self.recipients removeObjectAtIndex:index.row];
    [self.tableView reloadData];
}
- (IBAction)cancelEdit:(id)sender {
    [self.delegate cancelEdit];
}

@end
