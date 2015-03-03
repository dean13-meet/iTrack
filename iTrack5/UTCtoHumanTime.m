//
//  UTCtoHumanTime.m
//  Resturant App - User
//
//  Created by Dean Leitersdorf on 1/27/15.
//  Copyright (c) 2015 Dean Leitersdorf. All rights reserved.
//

#import "UTCtoHumanTime.h"

#define secondsInOneWeek 60*60*24*7

@implementation UTCtoHumanTime


+ (NSString*) msecToLocalTime:(NSTimeInterval)msec{//millisec in UTC to local time; refer to for obj-c time conversion: http://stackoverflow.com/questions/1268509/convert-utc-nsdate-to-local-timezone-objective-c
    
    
    NSTimeInterval seconds = msec/1000;
    NSDate* ts_utc = [NSDate dateWithTimeIntervalSince1970:seconds];
    
    NSDateComponents *components = [[NSCalendar currentCalendar] components:NSCalendarUnitDay | NSCalendarUnitMonth | NSCalendarUnitYear|NSCalendarUnitWeekday fromDate:ts_utc];
    NSDateComponents *componentsCurrent = [[NSCalendar currentCalendar] components:NSCalendarUnitDay | NSCalendarUnitMonth | NSCalendarUnitYear fromDate:[NSDate date]];
    NSString* formatter = @"yyyy.MM.dd G 'at' h:mm:ss a";
    if([[NSCalendar currentCalendar]isDateInToday:ts_utc])//today
    {
        formatter = @"'Today' h:mm a";
    }
    else if(fabsf([[NSDate date] timeIntervalSince1970]-seconds) < secondsInOneWeek)//this week
    {
        NSString* weekday = @"";
        switch ([components weekday]) {
            case 1:
                weekday = @"Sunday";
                break;
            case 2:
                weekday = @"Monday";
                break;
            case 3:
                weekday = @"Tuesday";
                break;
            case 4:
                weekday = @"Wednesday";
                break;
            case 5:
                weekday = @"Thursday";
                break;
            case 6:
                weekday = @"Friday";
                break;
            case 7:
                weekday = @"Saturday";
                break;
            
            default:
                break;
        }
        formatter = [NSString stringWithFormat:@"'%@', h:mm a", weekday];
    }
    else if([components year]==[componentsCurrent year])//display month/day
    {
        NSString* month = @"";
        
        switch ([components month]) {
            case 1:
                month = @"January";
                break;
            case 2:
                month = @"February";
                break;
            case 3:
                month = @"March";
                break;
            case 4:
                month = @"April";
                break;
            case 5:
                month = @"May";
                break;
            case 6:
                month = @"June";
                break;
            case 7:
                month = @"July";
                break;
            case 8:
                month = @"August";
                break;
            case 9:
                month = @"September";
                break;
            case 10:
                month = @"October";
                break;
            case 11:
                month = @"November";
                break;
            case 12:
                month = @"December";
                break;

            default:
                break;
        }
        
        formatter = [NSString stringWithFormat:@"'%ld %@', h:mm a", (long)[components day], month];
    }
    else //display year/month/day
    {
        NSString* month = @"";
        
        switch ([components month]) {
            case 1:
                month = @"January";
                break;
            case 2:
                month = @"February";
                break;
            case 3:
                month = @"March";
                break;
            case 4:
                month = @"April";
                break;
            case 5:
                month = @"May";
                break;
            case 6:
                month = @"June";
                break;
            case 7:
                month = @"July";
                break;
            case 8:
                month = @"August";
                break;
            case 9:
                month = @"September";
                break;
            case 10:
                month = @"October";
                break;
            case 11:
                month = @"November";
                break;
            case 12:
                month = @"December";
                break;
                
            default:
                break;
        }
        
        formatter = [NSString stringWithFormat:@"'%ld %@ %ld', h:mm a", (long)[components day], month, (long)[components year]];

    }
        NSDateFormatter* df_local = [[NSDateFormatter alloc] init];
    [df_local setTimeZone:[NSTimeZone localTimeZone]];
    [df_local setDateFormat:formatter];
    
    return [df_local stringFromDate:ts_utc];
    
}

+ (NSString*) secToLocalTime:(NSTimeInterval)sec
{
    return [UTCtoHumanTime msecToLocalTime:sec*1000];
}

#define baseYear 2014
+ (NSInteger) msecToDayNumber:(NSTimeInterval)msec
{
    NSTimeInterval seconds = msec/1000;
    NSDate* ts_utc = [NSDate dateWithTimeIntervalSince1970:seconds];
    
    NSDateComponents *components = [[NSCalendar currentCalendar] components:NSCalendarUnitDay | NSCalendarUnitMonth | NSCalendarUnitYear fromDate:ts_utc];
    NSInteger day = [components day];
    NSInteger month = [components month];
    NSInteger year = [components year];
    
    BOOL isLeap = [UTCtoHumanTime isLeap:year];
    
    
    
    NSInteger dayNum = day;
    //calc day# in year:
    for(int i = 1; i < month; i++)
    {
        if(month==2)//feb
        {
            dayNum += isLeap ? 29 : 28;
            continue;
        }
        else if(month==1 || month == 3 || month == 5 || month == 7 || month ==8 || month == 10 || month ==12)
        {
            dayNum+=31;
            continue;
        }
        else
        {
            dayNum+=30;
            continue;
        }
    }
    
    for(int i = baseYear; i < year; i++)
    {
        dayNum += [UTCtoHumanTime isLeap:i] ? 366 : 365;
        continue;
    }
    return dayNum;
}

+ (BOOL) isLeap:(NSInteger)year
{
    if (year%4!=0) return false;
        else
            if (year%100!=0) return true;
                else
                    if (year%400!=0) return false;
                        else return true;
    
    /*
     Wikipedia PseudoCode:
     if (year is not divisible by 4) then (it is a common year)
     else
     if (year is not divisible by 100) then (it is a leap year)
     else
     if (year is not divisible by 400) then (it is a common year)
     else (it is a leap year)
     */
}
@end


