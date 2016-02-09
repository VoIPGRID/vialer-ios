//
//  RecentCallManager.m
//  Copyright © 2015 VoIPGRID. All rights reserved.
//

#import "RecentCallManager.h"

#import "AppDelegate.h"
#import "RecentCall+VoIPGRID.h"
#import "SystemUser.h"
#import "VoIPGRIDRequestOperationManager+Recents.h"

static int const RecentCallManagerOffsetMonths = -1;
static int const RecentCallManagerNumberOfCalls = 50;
static NSString * const RecentCallManagerErrorDomain = @"RecentCallManagerError";
static NSTimeInterval const RecentCallManagerRefreshInterval = 30; // Update rate not quicker than this amount of seconds.

@interface RecentCallManager()
@property (strong, nonatomic) NSArray<RecentCall *> *recentCalls;
@property (strong, nonatomic) NSArray<RecentCall *> *missedRecentCalls;
@property (nonatomic) BOOL reloading;
@property (strong, nonatomic) NSDate * previousRefresh;

@property (nonatomic) BOOL recentsFetchFailed;
@property (nonatomic) RecentCallManagerErrors recentsFetchErrorCode;
@property (strong, nonatomic) VoIPGRIDRequestOperationManager *operationManager;
@property (strong, nonatomic) NSDateFormatter *callDateGTFormatter;

@property (strong, nonatomic) NSManagedObjectContext *privateManagedObjectContext;
@end

@implementation RecentCallManager

#pragma mark - Life Cycle

- (instancetype)init {
    self = [super init];
    if (self) {
        self.reloading = NO;
        self.recentsFetchFailed = NO;
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(logoutNotification:) name:SystemUserLogoutNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(managedObjectContextSaved:) name:NSManagedObjectContextDidSaveNotification object:nil];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:SystemUserLogoutNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSManagedObjectContextDidSaveNotification object:nil];
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
        _callDateGTFormatter.dateFormat = @"yyyy-MM-dd'T'HH:mm:ss";
    }
    return _callDateGTFormatter;
}

- (void)setMainManagedObjectContext:(NSManagedObjectContext *)mainManagedObjectContext {
    _mainManagedObjectContext = mainManagedObjectContext;
    self.privateManagedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    self.privateManagedObjectContext.parentContext = mainManagedObjectContext;
}

#pragma mark - Actions

- (void)getLatestRecentCallsWithCompletion:(void(^)(NSError *error))completion {
    // no fetch going on
    if (self.reloading ||
        // rate limit fetching
        (self.previousRefresh && fabs([self.previousRefresh timeIntervalSinceNow]) < RecentCallManagerRefreshInterval)) {
        completion(nil);
        return;
    }

    __block RecentCall *lastCall;
    [self.privateManagedObjectContext performBlockAndWait:^{
        lastCall = [RecentCall latestCallInManagedObjectContext:self.privateManagedObjectContext];
    }];

    NSDate *lastDate;
    NSDateComponents *offsetComponents = [[NSDateComponents alloc] init];
    if (lastCall) {
        lastDate = lastCall.callDate;
        offsetComponents.hour = -2;
    } else {
        // Retrieve recent calls from last month
        lastDate = [NSDate date];
        offsetComponents.month = RecentCallManagerOffsetMonths;

    }
    NSDate *fetchDate = [[NSCalendar currentCalendar] dateByAddingComponents:offsetComponents toDate:lastDate options:0];

    NSDictionary *parameters = @{@"limit": @(RecentCallManagerNumberOfCalls),
                                 @"offset": @0,
                                 @"call_date__gte": [self.callDateGTFormatter stringFromDate:fetchDate]
                                 };

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
        [self.privateManagedObjectContext performBlockAndWait:^{
            NSArray *newRecents = [RecentCall createRecentCallsFromVoIGPRIDResponseData:responseData inManagedObjectContext:self.privateManagedObjectContext];
            [self clearOldRecentsIfRecent:lastCall isNotInNewSet:[NSSet setWithArray:newRecents]];
        }];
        completion(nil);
    }];
}

- (void)clearOldRecentsIfRecent:(RecentCall *)lastRecentCall isNotInNewSet:(NSSet *)newRecentCalls {
    if (lastRecentCall && ![newRecentCalls containsObject:lastRecentCall]) {
        [self.privateManagedObjectContext performBlockAndWait:^{
            NSFetchRequest *fetch = [[NSFetchRequest alloc] init];
            fetch.entity = [NSEntityDescription entityForName:@"RecentCall" inManagedObjectContext:self.privateManagedObjectContext];
            fetch.predicate = [NSPredicate predicateWithFormat:@"callDate <= %@", lastRecentCall.callDate];
            NSArray *result = [self.privateManagedObjectContext executeFetchRequest:fetch error:nil];
            for (id recentCall in result) {
                [self.privateManagedObjectContext deleteObject:recentCall];
            }
            NSError *error;
            if (![self.privateManagedObjectContext save:&error]) {
                NSLog(@"Error saving Recent call: %@", error);
            }
        }];
    }
}

- (void)clearRecents {
    NSFetchRequest *fetch = [[NSFetchRequest alloc] init];
    fetch.entity = [NSEntityDescription entityForName:@"RecentCall" inManagedObjectContext:self.privateManagedObjectContext];
    [self.privateManagedObjectContext performBlockAndWait:^{
        NSArray *result = [self.privateManagedObjectContext executeFetchRequest:fetch error:nil];
        for (id recentCall in result) {
            [self.privateManagedObjectContext deleteObject:recentCall];
        }
        NSError *error;
        if (![self.privateManagedObjectContext save:&error]) {
            NSLog(@"Error saving Recent call: %@", error);
        }
    }];
}

#pragma mark - Notifications

- (void)logoutNotification:(NSNotification *)notification {
    [self clearRecents];
}

- (void)managedObjectContextSaved:(NSNotification *)notification {
    [self.privateManagedObjectContext performBlock:^{
        [self.privateManagedObjectContext mergeChangesFromContextDidSaveNotification:notification];
    }];
}

@end
