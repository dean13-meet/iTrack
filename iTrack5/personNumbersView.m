//
//  personNumbersView.m
//  iTrack5
//
//  Created by Dean Leitersdorf on 3/23/15.
//  Copyright (c) 2015 Dean Leitersdorf. All rights reserved.
//

#import "personNumbersView.h"
#import "Person.h"

@implementation personNumbersView

- (instancetype) initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if(self)
    {
        
        [[NSBundle mainBundle] loadNibNamed:@"personNumbersView" owner:self options:nil];
        
        self.frame = frame;
        self.view.frame = CGRectMake(0, 0, frame.size.width, frame.size.height);
        
        
        [self addSubview:self.view];
        
        
    }
    return self;
}


- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *CellIdentifier = @"recCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if(!cell)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"eventCell"];
    }
    
    cell.textLabel.text = [NSString stringWithFormat:@"%@",((Person*)self.person).numbers.allKeys[indexPath.row]];
    cell.accessoryType = [((Person*)self.person).numbers.allValues[indexPath.row] boolValue] ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
    
    return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [((Person*)self.person).numbers count];
}
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}


- (BOOL) tableView:(UITableView *)tableView shouldHighlightRowAtIndexPath:(NSIndexPath *)indexPath
{
	if(self.disableSelection)return NO;
	
	return YES;
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	if(self.disableSelection)return;
	
	if(!self.disableMultipleSelection){
	
    NSString* key = ((Person*)self.person).numbers.allKeys[indexPath.row];
    
    [((Person*)self.person).numbers setValue:[NSNumber numberWithBool:![[((Person*)self.person).numbers valueForKey:key] boolValue] ] forKey:key];
		
	}
	
	else
	{
		for(NSString* key in ((Person*)self.person).numbers.allKeys)
		{
			[((Person*)self.person).numbers setValue:[NSNumber numberWithBool:NO] forKey:key];
		}
		NSString* key = ((Person*)self.person).numbers.allKeys[indexPath.row];
		[((Person*)self.person).numbers setValue:[NSNumber numberWithBool:YES] forKey:key];

	}
	
    [self.tableview reloadData];
}

- (void) setPerson:(NSObject *)person
{
    _person = person;
    self.titleLabel.text = ((Person*)person).name;
}
- (IBAction)closePopup:(id)sender
{
    
    [UIView animateWithDuration:.2
                     animations:^{
                         //self.frame = CGRectMake(self.center.x - 350, self.center.y - 350, 700,700);
                         self.transform = CGAffineTransformMakeScale(.2, .2);
                     } completion:^(BOOL finished) {
						 self.transform = CGAffineTransformMakeScale(1, 1);//so that next time the view is loaded, its back to normal
                         [self removeFromSuperview];
                     }];
    
}
@end
