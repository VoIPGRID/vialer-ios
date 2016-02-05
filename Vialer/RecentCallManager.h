//
//  RecentCallManager.h
//  Vialer
//
//  Created by Bob Voorneveld on 16/11/15.
//  Copyright © 2015 VoIPGRID. All rights reserved.
//

#import <Foundation/Foundation.h>

@class RecentCall;

typedef NS_ENUM(NSUInteger, RecentCallManagerErrors) {
    RecentCallManagerFetchFailed = 1, //Unknown error, but fetch failed.
    RecentCallManagerFetchingUserNotAllowed, //No permission
};

@interface RecentCallManager : NSObject

@property (readonly, nonatomic) NSArray<RecentCall *> *recentCalls;
@property (readonly, nonatomic) NSArray<RecentCall *> *missedRecentCalls;
@property (readonly, nonatomic) BOOL reloading;

/** When an error occurs this bool is set*/
@property (readonly, nonatomic) BOOL recentsFetchFailed;
/** When an error occurs, the error code is obtain by questioning this parameter*/
@property (readonly, nonatomic) RecentCallManagerErrors recentsFetchErrorCode;


+ (RecentCallManager *)defaultManager;

- (void)getLatestRecentCallsWithCompletion:(void(^)(NSError *error))completion;
- (void)clearRecents;

@end
