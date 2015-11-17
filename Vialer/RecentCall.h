//
//  RecentCall.h
//  Vialer
//
//  Created by Reinier Wieringa on 13/11/13.
//  Copyright (c) 2014 VoIPGRID. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, CallDirection) {
    CallDirectionInbound,
    CallDirectionOutbound,
};

@interface RecentCall : NSObject

@property (nonatomic) int32_t callerRecordId;   // Record id for Address Book (-1 means unknown)
@property (strong, nonatomic) NSString *contactIdentifier;
@property (strong, nonatomic) NSString *callerName;
@property (strong, nonatomic) NSString *callerPhoneType;
@property (strong, nonatomic) NSString *callerPhoneNumber;
@property (nonatomic) CallDirection callDirection;
@property (strong, nonatomic) NSString *callDate;
@property (nonatomic) NSInteger atime;
@property (strong, nonatomic) NSString *callerId;

- (BOOL)isEqualToRecentCall:(RecentCall *)other;

+ (void)clearCachedRecentCalls; // Clear cached results
+ (NSArray *)cachedRecentCalls; // Cached results from last recentCalls invocation
+ (NSArray *)recentCallsFromDictionary:(NSDictionary *)dict;

+ (NSCharacterSet *)digitsCharacterSet;

@end
