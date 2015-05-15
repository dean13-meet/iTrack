//
//  LocationFactory.h
//  iTrack5
//
//  Created by Dean Leitersdorf on 5/4/15.
//  Copyright (c) 2015 Dean Leitersdorf. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LocationFactory : NSObject

- (void) nextWithSender:(id)sender;
- (void) backWithSender:(id)sender;

- (void) disableMap;
- (void) enableMap;

@property (nonatomic) BOOL mode;//0 = sending, 1 = requesting

@end
