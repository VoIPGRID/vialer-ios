//
//  Middleware.m
//  Copyright © 2016 VoIPGRID. All rights reserved.
//

#import "Middleware.h"
@import CoreData;
#import "MiddlewareRequestOperationManager.h"
#import "SystemUser.h"
#import "Vialer-Swift.h"

static float const MiddlewareResendTimeInterval = 10.0;
static int const MiddlewareMaxAttempts = 8;
NSString * const MiddlewareRegistrationOnOtherDeviceNotification = @"MiddlewareRegistrationOnOtherDeviceNotification";
NSString * const MiddlewareAccountRegistrationIsDoneNotification = @"MiddlewareAccountRegistrationIsDoneNotification";

@interface Middleware ()
@property (strong, nonatomic) MiddlewareRequestOperationManager *commonMiddlewareRequestOperationManager;
@property (weak, nonatomic) SystemUser *systemUser;
@property (nonatomic) int retryCount;
@property (strong, nonatomic) Reachability *reachability;
@property (strong, nonatomic) NSManagedObjectContext* context;
@property (strong, nonatomic) NSString *pushNotificationProcessing;
@end

@implementation Middleware

#pragma mark - Lifecycle
- (void)dealloc {
}

- (instancetype)init {
    self = [super init];
    if (self) {
    }
    return self;
}

#pragma mark - properties
- (SystemUser *)systemUser {
    if (!_systemUser) {
        _systemUser = [SystemUser currentUser];
    }
    return _systemUser;
}

- (Reachability *)reachability {
    if (!_reachability) {
        _reachability = [ReachabilityHelper sharedInstance].reachability;
    }
    return _reachability;
}

/**
 *  There is one Common Middleware used for registering and unregistration of a device.
 *  Responding to an incoming call is done to the middleware which is included in the push payload.
 *
 *  @return A Middleware instance representing the common middleware.
 */
- (MiddlewareRequestOperationManager *)commonMiddlewareRequestOperationManager {
    if (!_commonMiddlewareRequestOperationManager) {
        NSString *baseURLString = [[UrlsConfiguration shared] middlewareBaseUrl];
        _commonMiddlewareRequestOperationManager = [[MiddlewareRequestOperationManager alloc] initWithBaseURLasString:baseURLString];
    }
    return _commonMiddlewareRequestOperationManager;
}

- (NSManagedObjectContext *)context {
    if (!_context) {
        _context = [CoreDataStackHelper sharedInstance].syncContext;
    }
    return _context;
}

#pragma mark - actions

- (void)deleteDeviceRegistration: (NSString *_Nonnull) apnsToken {
    VialerLogInfo(@"SIP Disabled, unregistering from middleware");
    NSString *storedAPNSToken = apnsToken;
    NSString *sipAccount = SystemUser.currentUser.sipAccount;

    if (sipAccount && storedAPNSToken) {
        [self.commonMiddlewareRequestOperationManager deleteDeviceRecordWithAPNSToken:storedAPNSToken sipAccount:sipAccount withCompletion:^(NSError *error) {
            if (error) {
                VialerLogError(@"Error deleting device record from middleware. %@", error);
            } else {
                VialerLogDebug(@"Middleware device record deleted successfully");
            }
        }];
    } else {
        VialerLogDebug(@"Not deleting device registration from middleware, SIP Account(%@) not set or no APNS Token(%@) stored.",
                   sipAccount, storedAPNSToken);
    }
}

- (void)sentAPNSToken:(NSString *)apnsToken {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSString *applicationStateString;
        NSInteger applicationState = [UIApplication sharedApplication].applicationState;
        switch (applicationState) {
                case UIApplicationStateActive: {
                    applicationStateString = @"UIApplicationStateActive";
                    break;
                }
                case UIApplicationStateInactive: {
                    applicationStateString = @"UIApplicationStateInactive";
                    break;
                }
                case UIApplicationStateBackground: {
                    applicationStateString = @"UIApplicationStateBackground";
                    break;
                }
        }

        NSString *backgroundTimeRemaining = @"N/A";
        if (applicationState == UIApplicationStateBackground) {
            backgroundTimeRemaining = [NSString stringWithFormat:@"%.4f", [UIApplication sharedApplication].backgroundTimeRemaining];
        }

        VialerLogInfo(@"Trying to sent APNSToken to middleware. Application state: \"%@\". Background time remaining: %@", applicationStateString, backgroundTimeRemaining);
    });

    UIApplication *application = [UIApplication sharedApplication];
    UIBackgroundTaskIdentifier __block backgroundtask = UIBackgroundTaskInvalid;

    void (^backgroundTaskCleanupBlock)(void) = ^{
        [application endBackgroundTask:backgroundtask];
        backgroundtask = UIBackgroundTaskInvalid;
    };

    backgroundtask = [application beginBackgroundTaskWithExpirationHandler:^{
        VialerLogInfo(@"APNS token background task timed out.");
        backgroundTaskCleanupBlock();
    }];

    [self sentAPNSToken:apnsToken withCompletion:^(NSError *error) {
        NSMutableString *logString = [NSMutableString stringWithFormat:@"APNS token background task completed"];
        if (application.applicationState == UIApplicationStateBackground) {
            [logString appendFormat:@" with %.3f time remaining", application.backgroundTimeRemaining];
        }

        VialerLogInfo(@"%@", logString);
        backgroundTaskCleanupBlock();
    }];
}

- (void)sentAPNSToken:(NSString *)apnsToken withCompletion:(void (^)(NSError *error))completion {
    if (self.systemUser.sipEnabled) {
        [self.commonMiddlewareRequestOperationManager updateDeviceRecordWithAPNSToken:apnsToken sipAccount:self.systemUser.sipAccount withCompletion:^(NSError *error) {
            if (error) {

                if ((error.code == NSURLErrorTimedOut || error.code == NSURLErrorNotConnectedToInternet) && self.retryCount < 5) {
                    // Update the retry count.
                    self.retryCount++;

                    // Log an error.
                    VialerLogWarning(@"Device registration failed. Will retry 5 times. Currently tried %d out of 5.", self.retryCount);

                    // Retry to call the function.
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(MiddlewareResendTimeInterval * self.retryCount * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                        [self sentAPNSToken:apnsToken withCompletion:completion];
                    });
                } else {
                    // Reset the retry count back to 0.
                    self.retryCount = 0;

                    // And log the problem to track failures.
                    [VialerGAITracker registrationFailedWithMiddleWareException];
                    VialerLogError(@"Device registration with Middleware failed. %@", error);

                    if (completion) {
                        completion(error);
                    }
                }
            } else {
                // Reset the retry count back to 0.
                self.retryCount = 0;

                // Display debug message the registration has been successfull.
                VialerLogDebug(@"Middleware registration successfull");
                if (completion) {
                    completion(nil);
                }
            }
        }];
    }
}

@end
