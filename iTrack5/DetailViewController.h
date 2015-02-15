//
//  DetailViewController.h
//  iTrack5
//
//  Created by Dean Leitersdorf on 2/15/15.
//  Copyright (c) 2015 Dean Leitersdorf. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DetailViewController : UIViewController

@property (strong, nonatomic) id detailItem;
@property (weak, nonatomic) IBOutlet UILabel *detailDescriptionLabel;

@end

