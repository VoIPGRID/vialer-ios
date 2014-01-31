//
//  NSDate+RelativeDate.h
//  Vialer
//
//  Created by Reinier Wieringa on 06/11/13.
//  Copyright (c) 2014 VoIPGRID. All rights reserved.
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
