//
//  recCell.h
//  iTrack5
//
//  Created by Dean Leitersdorf on 3/7/15.
//  Copyright (c) 2015 Dean Leitersdorf. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "personNumbersView.h"

@protocol recCellDelegate <NSObject>

- (void) deleteSelfWithSender:(id)sender;

@end
@interface recCell : UITableViewCell


@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) id<recCellDelegate> delegate;
@property (weak, nonatomic) IBOutlet UIButton *xButton;


- (void) disableX;
@end
