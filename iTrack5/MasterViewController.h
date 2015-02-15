//
//  MasterViewController.h
//  iTrack5
//
//  Created by Dean Leitersdorf on 2/15/15.
//  Copyright (c) 2015 Dean Leitersdorf. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>

@interface MasterViewController : UITableViewController <NSFetchedResultsControllerDelegate>

@property (strong, nonatomic) NSFetchedResultsController *fetchedResultsController;
@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;


@end

