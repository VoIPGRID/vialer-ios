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

@interface RecentCallManager()
@property (strong, nonatomic) NSArray<RecentCall *> *recentCalls;
@property (strong, nonatomic) NSArray<RecentCall *> *missedRecentCalls;
@property (nonatomic) BOOL reloading;
@property (strong, nonatomic) NSDate * previousRefresh;

@property (nonatomic) BOOL recentsFetchFailed;
@property (nonatomic) RecentCallManagerErrors recentsFetchErrorCode;
@property (strong, nonatomic) VoIPGRIDRequestOperationManager *operationManager;
@property (strong, nonatomic) NSDateFormatter *callDateGTFormatter;
@end

@implementation RecentCallManager

#pragma mark - Life Cycle

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
        self.recentsFetchFailed = NO;
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(logoutNotification:) name:SystemUserLogoutNotification object:nil];

    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:SystemUserLogoutNotification object:nil];
}

#pragma mark - Properties

- (VoIPGRIDRequestOperationManager *)operationManager {
    if (!_operationManager) {
        _operationManager = [VoIPGRIDRequestOperationManager sharedRequestOperationManager];
    }
    return _operationManager;
}

- (NSDateFormatter *)callDateGTFormatter {
    if (! _callDateGTFormatter) {
        _callDateGTFormatter = [[NSDateFormatter alloc] init];
        [_callDateGTFormatter setDateFormat:@"yyyy-MM-dd"];
    }
    return _callDateGTFormatter;
}

- (void)getLatestRecentCallsWithCompletion:(void(^)(NSError *error))completion {
    // no fetch going on
    if (self.reloading ||
        // rate limit fetching
        (self.previousRefresh && fabs([self.previousRefresh timeIntervalSinceNow]) < RecentCallManagerRefreshInterval)) {
        completion(nil);
        return;
    }

    // Retrieve recent calls from last month
    NSDateComponents *offsetComponents = [[NSDateComponents alloc] init];
    [offsetComponents setMonth:RecentCallManagerOffsetMonths];
    NSDate *lastMonth = [[NSCalendar currentCalendar] dateByAddingComponents:offsetComponents toDate:[NSDate date] options:0];

    NSMutableDictionary *parameters = [[NSMutableDictionary alloc] init];
    [parameters setObject:@(RecentCallManagerNumberOfCalls) forKey:@"limit"];
    [parameters setObject:@0 forKey:@"offset"];
    [parameters setObject:[self.callDateGTFormatter stringFromDate:lastMonth] forKey:@"call_date__gt"];

    self.reloading = YES;
    [self.operationManager cdrRecordsWithParameters:parameters withCompletion:^(AFHTTPRequestOperation *operation, NSDictionary *responseData, NSError *error) {
        self.reloading = NO;

        // Check if error happend.
        if (error) {
            self.recentsFetchFailed = YES;
            self.recentCalls = nil;
            self.missedRecentCalls = nil;

            if ([operation.response statusCode] == VoIPGRIDHttpErrorForbidden) {
                self.recentsFetchErrorCode = RecentCallManagerFetchingUserNotAllowed;
                NSError *error = [NSError errorWithDomain:RecentCallManagerErrorDomain code:RecentCallManagerFetchingUserNotAllowed userInfo:@{NSLocalizedDescriptionKey: NSLocalizedString(@"You are not allowed to view recent calls", nil)}];
                completion(error);
            } else {
                self.recentsFetchErrorCode = RecentCallManagerFetchFailed;
                NSError *error = [NSError errorWithDomain:RecentCallManagerErrorDomain code:RecentCallManagerFetchFailed userInfo:@{NSLocalizedDescriptionKey: NSLocalizedString(@"Could not load your recent calls", nil)}];
                completion(error);
            }
            return;
        }

        // Register the time when we had a succesfull retrieval
        self.previousRefresh = [NSDate date];
        self.reloading = NO;
        self.recentsFetchFailed = NO;
        self.recentCalls = [RecentCall recentCallsFromDictionary:responseData];
        self.missedRecentCalls = [self filterMissedRecents:self.recentCalls];
        completion(nil);
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

- (void)logoutNotification:(NSNotification *)notification {
    [self clearRecents];
}
@end
