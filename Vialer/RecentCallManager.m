//
//  RecentCallManager.m
//  Vialer
//
//  Created by Bob Voorneveld on 16/11/15.
//  Copyright © 2015 VoIPGRID. All rights reserved.
//

#import "RecentCallManager.h"

#import "RecentCall.h"
#import "SystemUser.h"
#import "VoIPGRIDRequestOperationManager.h"

static int const RecentCallManagerOffsetMonths = -1;
static int const RecentCallManagerNumberOfCalls = 50;
static NSString * const RecentCallManagerErrorDomain = @"RecentCallManagerError";
static NSTimeInterval const RecentCallManagerRefreshInterval = 60; // Update rate not quicker than this amount of seconds.
static NSTimeInterval const RecentCallManagerLastRecentsFailureInterval = 1800; // Do not fetch recents again after failure after this amound of seconds.

@interface RecentCallManager()
@property (strong, nonatomic) NSArray<RecentCall *> *recentCalls;
@property (strong, nonatomic) NSArray<RecentCall *> *missedRecentCalls;
@property (nonatomic) BOOL reloading;
@property (nonatomic) NSDate *lastRecentsFailure;
@property (strong, nonatomic) NSDate * previousRefresh;
@end

@implementation RecentCallManager

+ (RecentCallManager *)defaultManager {
    static RecentCallManager *_defaultManager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _defaultManager = [[RecentCallManager alloc] init];
    });
    return _defaultManager;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.reloading = NO;
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(loginFailedNotification:) name:LOGIN_FAILED_NOTIFICATION object:nil];

    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:LOGIN_FAILED_NOTIFICATION object:nil];
}

- (void)getLatestRecentCallsWithCompletion:(void(^)(NSError *error))completion {

    // User must be loggedin
    if (![SystemUser currentUser].isLoggedIn ||
        // no fetch going on
        self.reloading ||
        // rate limit fetching
        (self.previousRefresh && fabs([self.previousRefresh timeIntervalSinceNow]) < RecentCallManagerRefreshInterval) ||
        // wait after failure
        (self.lastRecentsFailure && fabs([self.lastRecentsFailure timeIntervalSinceNow]) < RecentCallManagerLastRecentsFailureInterval)) {
        completion(nil);
        return;
    }

    // Retrieve recent calls from last month
    NSDateComponents *offsetComponents = [[NSDateComponents alloc] init];
    [offsetComponents setMonth:RecentCallManagerOffsetMonths];
    NSDate *lastMonth = [[NSCalendar currentCalendar] dateByAddingComponents:offsetComponents toDate:[NSDate date] options:0];

    NSString *sourceNumber = nil;

    self.reloading = YES;
    [[VoIPGRIDRequestOperationManager sharedRequestOperationManager] cdrRecordWithLimit:RecentCallManagerNumberOfCalls offset:0 sourceNumber:sourceNumber callDateGte:lastMonth success:^(AFHTTPRequestOperation *operation, id responseObject) {
        // Register the time when we had a succesfull retrieval
        self.lastRecentsFailure = nil;
        self.previousRefresh = [NSDate date];
        self.reloading = NO;
        self.recentCalls = [RecentCall recentCallsFromDictionary:responseObject];
        self.missedRecentCalls = [self filterMissedRecents:self.recentCalls];
        completion(nil);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        self.reloading = NO;
        if ([operation.response statusCode] == VoIPGRIDHttpErrorsUnauthorized) {
            // No permissions
            [[SystemUser currentUser] logout];
            [self clearRecents];
        } else {
            self.lastRecentsFailure = [NSDate date];
            NSError *error = [NSError errorWithDomain:RecentCallManagerErrorDomain code:0 userInfo:@{NSLocalizedDescriptionKey: NSLocalizedString(@"Failed to fetch your recent calls.", nil)}];
            completion(error);
        }
    }];
}

- (NSArray *)filterMissedRecents:(NSArray *)recents {
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(atime == 0) AND (callDirection == 0)"];
    return [recents filteredArrayUsingPredicate:predicate];
}

- (void)clearRecents {
    self.recentCalls = nil;
    self.missedRecentCalls = nil;
}

#pragma mark - Notifications

- (void)loginFailedNotification:(NSNotification *)notification {
    [self clearRecents];
}
@end
