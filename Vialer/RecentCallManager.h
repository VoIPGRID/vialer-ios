//
//  RecentCallManager.h
//  Copyright © 2015 VoIPGRID. All rights reserved.
//

#import <Foundation/Foundation.h>

@class RecentCall;
@class NSManagedObjectContext;

/**
 *  Errors the RecentCallManager can have.
 */
typedef NS_ENUM(NSUInteger, RecentCallManagerErrors) {
    /**
     *  Failed to fetch the latest recents remotely.
     */
    RecentCallManagerFetchFailed = 1,
    /**
     *  The user is not allowed to fetch recents.
     */
    RecentCallManagerFetchingUserNotAllowed,
};

@interface RecentCallManager : NSObject

/**
 *  Boolean indicating if there is a fetch active.
 */
@property (readonly, nonatomic) BOOL reloading;

/**
 *  When an error occurs this bool is set.
 */
@property (readonly, nonatomic) BOOL recentsFetchFailed;

/**
 *  When an error occurs, the error code is obtain by questioning this parameter
 */
@property (readonly, nonatomic) RecentCallManagerErrors recentsFetchErrorCode;

/**
 *  The managedObjectContext that will be used to store and retrieve RecentCalls.
 */
@property (strong, nonatomic) NSManagedObjectContext *mainManagedObjectContext;

/**
 *  Fetch remotely the latest recent calls and store them in the managedObjectContext.
 *
 *  @param completion A block that will be called when fetching was completed. If an error occured, this will be returned in the block.
 */
- (void)getLatestRecentCallsWithCompletion:(void(^)(NSError *error))completion;

/**
 *  Remove all recents from the ManagedObjectContext.
 */
- (void)clearRecents;

@end
