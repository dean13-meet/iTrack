//
//  Person.m
//  iTrack5
//
//  Created by Dean Leitersdorf on 3/18/15.
//  Copyright (c) 2015 Dean Leitersdorf. All rights reserved.
//

#import "Person.h"

@implementation Person


- (BOOL)isEqual:(id)other {
    if (!other || ![other isKindOfClass:[self class]])
        return NO;
    if (other == self)
        return YES;
    
    Person* person = (Person*)other;
    
    return [self.name isEqualToString:person.name] && [self.numbers isEqualToDictionary:person.numbers];
}

- (NSDictionary*)dicForm
{
	return @{@"name":self.name, @"numbers":self.numbers};
}
- (void) setInfoToMatchDic:(NSDictionary *)dic
{
	self.name = [dic valueForKey:@"name"];
	self.numbers = [dic valueForKey:@"numbers"];
}
@end
