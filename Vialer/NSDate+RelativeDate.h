//
//  NSDate+RelativeDate.h
//  Copyright © 2015 VoIPGRID. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSDate (RelativeDate)

- (NSString *)relativeDayTimeString;
- (NSString *)relativeDayString;
- (NSString *)utcString;
- (BOOL)isEmpty;

+ (NSDate *)dateFromUtcString:(NSString *)utcString;
+ (NSDate *)dateFromString:(NSString *)string;
+ (NSDate *)emptyDate;

@end
