//
//  Person.h
//  iTrack5
//
//  Created by Dean Leitersdorf on 3/18/15.
//  Copyright (c) 2015 Dean Leitersdorf. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "personNumbersView.h"

@interface Person : NSObject

@property (strong, nonatomic) NSString* name;
@property (nonatomic) NSDictionary* numbers;//numbers to selected
@property (strong, nonatomic) personNumbersView* popup;

- (BOOL)isEqual:(id)other;
- (NSDictionary*)dicForm;
- (void) setInfoToMatchDic:(NSDictionary*)dic;
@end
