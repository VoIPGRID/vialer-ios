//
//  NSDate+RelativeDate.m
//  Vialer
//
//  Created by Reinier Wieringa on 06/11/13.
//  Copyright (c) 2014 VoIPGRID. All rights reserved.
//

#import "NSDate+RelativeDate.h"

@implementation NSDate (RelativeDate)

static NSDateFormatter *midnightDateFormatter = nil;
static NSDateFormatter *dayDateFormatter = nil;
static NSDateFormatter *utcDateFormatter = nil;

- (NSString *)relativeDayTimeString {
    if (!midnightDateFormatter) {
        midnightDateFormatter = [[NSDateFormatter alloc] init];
        [midnightDateFormatter setDateFormat:@"yyyy-MM-dd"];
    }
    if (!dayDateFormatter) {
        dayDateFormatter = [[NSDateFormatter alloc] init];
        [dayDateFormatter setDateStyle:NSDateFormatterShortStyle];
    }

	NSDate *midnight = [midnightDateFormatter dateFromString:[midnightDateFormatter stringFromDate:self]];
	NSInteger daysAgo = (NSInteger)[midnight timeIntervalSinceNow] / (60 * 60 * 24);
    NSString *day = [dayDateFormatter stringFromDate:self];
	if (daysAgo == -1) {
        day = NSLocalizedString(@"yesterday", nil);
    }
    if (daysAgo > -1) {
        NSDateFormatter *timeFormatter = [[NSDateFormatter alloc] init];
        [timeFormatter setTimeStyle:NSDateFormatterShortStyle];
        return [NSString stringWithFormat:@"%@", [timeFormatter stringFromDate:self]];
    }

    return day;
}

- (NSString *)relativeDayString {
    if (!midnightDateFormatter) {
        midnightDateFormatter = [[NSDateFormatter alloc] init];
        [midnightDateFormatter setDateFormat:@"yyyy-MM-dd"];
    }
    if (!dayDateFormatter) {
        dayDateFormatter = [[NSDateFormatter alloc] init];
        [dayDateFormatter setDateStyle:NSDateFormatterShortStyle];
    }
    
	NSDate *midnight = [midnightDateFormatter dateFromString:[midnightDateFormatter stringFromDate:self]];
	NSInteger daysAgo = (NSInteger)[midnight timeIntervalSinceNow] / (60 * 60 * 24);
    NSString *day = [dayDateFormatter stringFromDate:self];

	if (daysAgo == 0) {
        NSDateFormatter *timeFormatter = [[NSDateFormatter alloc] init];
        [timeFormatter setTimeStyle:NSDateFormatterShortStyle];
        day = [[timeFormatter stringFromDate:self] uppercaseString];
    } else if (daysAgo == -1) {
        day = [NSLocalizedString(@"yesterday", nil) capitalizedString];
    }

    return day;
}

- (BOOL)isEmpty {
    return [self timeIntervalSince1970] == 0;
}

- (NSString *)utcString {
    if (!utcDateFormatter) {
        utcDateFormatter = [[NSDateFormatter alloc] init];
    }
    [utcDateFormatter setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"UTC"]];
    [utcDateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss"];
    return [utcDateFormatter stringFromDate:self];
}

+ (NSDate *)dateFromUtcString:(NSString *)utcString {
    if (!utcDateFormatter) {
        utcDateFormatter = [[NSDateFormatter alloc] init];
    }
    [utcDateFormatter setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"UTC"]];
    [utcDateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss"];
    return [utcDateFormatter dateFromString:utcString];
}

+ (NSDate *)dateFromString:(NSString *)utcString {
    if (!utcDateFormatter) {
        utcDateFormatter = [[NSDateFormatter alloc] init];
    }
    [utcDateFormatter setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"UTC"]];
    [utcDateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ssZZZ"];   // Try with time zone

    NSDate *date = [utcDateFormatter dateFromString:utcString];
    if (!date) {    // Failed with time zone, try without (Amsterdam)
        [utcDateFormatter setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"GMT+1:00"]];
        [utcDateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss"];
        date = [utcDateFormatter dateFromString:utcString];
    }
    return date;
}

+ (NSDate *)emptyDate {
    return [NSDate dateWithTimeIntervalSince1970:0];
}

@end
