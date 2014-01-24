//
//  RecentCall.h
//  Vialer
//
//  Created by Reinier Wieringa on 13/11/13.
//  Copyright (c) 2013 Voys. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum {
    CallDirectionInbound   = 0,
    CallDirectionOutbound  = 1,
} CallDirection;

@interface RecentCall : NSObject

@property (nonatomic) int32_t callerRecordId;   // Record id for Address Book (-1 means unknown)
@property (nonatomic, strong) NSString *callerName;
@property (nonatomic, strong) NSString *callerPhoneType;
@property (nonatomic, strong) NSString *callerPhoneNumber;
@property (nonatomic, assign) CallDirection callDirection;
@property (nonatomic, strong) NSDate *callDate;
@property (nonatomic, assign) NSInteger atime;

- (BOOL)isEqualToRecentCall:(RecentCall *)other;

+ (void)clearCachedRecentCalls; // Clear cached results
+ (NSArray *)cachedRecentCalls; // Cached results from last recentCalls invocation
+ (NSArray *)recentCallsFromDictionary:(NSDictionary *)dict;

@end
