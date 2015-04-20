//
//  personNumbersView.h
//  iTrack5
//
//  Created by Dean Leitersdorf on 3/23/15.
//  Copyright (c) 2015 Dean Leitersdorf. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface personNumbersView : UIView <UITableViewDataSource, UITableViewDelegate>
@property (strong, nonatomic) IBOutlet UIView *view;
@property (weak, nonatomic) NSObject* person;
@property (weak, nonatomic) IBOutlet UITableView *tableview;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;

@property (nonatomic) BOOL disableMultipleSelection;

@property (nonatomic) BOOL disableSelection;//e.g. just viewing the person's numbers, no ability to select/deselect
@end
