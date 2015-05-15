//
//  vToView.h
//  iTrack5
//
//  Created by Dean Leitersdorf on 5/12/15.
//  Copyright (c) 2015 Dean Leitersdorf. All rights reserved.
//

#import "LocationFactoryView.h"


#import <UIKit/UIKit.h>
#import "keyboardComplexView.h"
#import "recCell.h"



@interface vToView : LocationFactoryView<UITableViewDataSource, UITableViewDelegate, recCellDelegate, keyboardComplexViewDelegate>
@property (strong, nonatomic) IBOutlet UIView *view;

@property (strong, nonatomic) NSMutableArray* recipients;
@property (weak, nonatomic) IBOutlet UITextField *toBox;
@property (weak, nonatomic) IBOutlet UITableView *tableView;

- (void) deleteSelfWithSender:(id)sender;
- (void) addObjectToRecipients:(id)object;

//@property (weak, nonatomic) IBOutlet UIButton *cancelEditButton;
@end