//
//  RecentCallManager.h
//  Vialer
//
//  Created by Bob Voorneveld on 16/11/15.
//  Copyright © 2015 VoIPGRID. All rights reserved.
//

#import <Foundation/Foundation.h>

@class RecentCall;

@interface RecentCallManager : NSObject

@property (readonly, nonatomic) NSArray<RecentCall *> *recentCalls;
@property (readonly, nonatomic) NSArray<RecentCall *> *missedRecentCalls;
@property (readonly, nonatomic) BOOL reloading;

+ (RecentCallManager *)defaultManager;

- (void)getLatestRecentCallsWithCompletion:(void(^)(NSError *error))completion;
- (void)clearRecents;

@end
