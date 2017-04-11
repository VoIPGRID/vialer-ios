//
//  Middleware.m
//  Copyright © 2016 VoIPGRID. All rights reserved.
//

#import "Middleware.h"

#import "APNSHandler.h"
#import "Configuration.h"
@import CoreData;
#import "MiddlewareRequestOperationManager.h"
#import "SIPUtils.h"
#import "SystemUser.h"
#import "Vialer-Swift.h"

static NSString * const MiddlewareAPNSPayloadKeyType       = @"type";
static NSString * const MiddlewareAPNSPayloadKeyCall       = @"call";
static NSString * const MiddlewareAPNSPayloadKeyCheckin    = @"checkin";
static NSString * const MiddlewareAPNSPayloadKeyMessage    = @"message";

static NSString * const MiddlewareAPNSPayloadKeyResponseAPI = @"response_api";
static float const MiddlewareResendTimeInterval = 10.0;
NSString * const MiddlewareRegistrationOnOtherDeviceNotification = @"MiddlewareRegistrationOnOtherDeviceNotification";

@interface Middleware ()
@property (strong, nonatomic) MiddlewareRequestOperationManager *commonMiddlewareRequestOperationManager;
@property (weak, nonatomic) SystemUser *systemUser;
@property (nonatomic) int retryCount;
@property (strong, nonatomic) Reachability *reachability;
@property (strong, nonatomic) NSManagedObjectContext* context;
@end

@implementation Middleware

 #pragma mark - Lifecycle
- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:SystemUserSIPCredentialsChangedNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:SystemUserSIPDisabledNotification object:nil];
}

- (instancetype)init {
    self = [super init];
    if (self) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateAPNSTokenOnSIPCredentialsChange) name:SystemUserSIPCredentialsChangedNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deleteDeviceRegistrationFromMiddleware:) name:SystemUserSIPDisabledNotification object:nil];
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
        AppDelegate *delegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
        _reachability = delegate.reachability;
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
        NSString *baseURLString = [[Configuration defaultConfiguration] UrlForKey:ConfigurationMiddleWareBaseURLString];
        _commonMiddlewareRequestOperationManager = [[MiddlewareRequestOperationManager alloc] initWithBaseURLasString:baseURLString];
    }
    return _commonMiddlewareRequestOperationManager;
}

- (NSManagedObjectContext *)context {
    if (!_context) {
        _context = ((AppDelegate *)[UIApplication sharedApplication].delegate).syncContext;
    }
    return _context;
}

#pragma mark - actions
- (void)handleReceivedAPSNPayload:(NSDictionary *)payload {
    // Set current time to measure response time.
    NSDate *pushResponseTimeMeasurementStart = [NSDate date];

    NSString *payloadType = payload[MiddlewareAPNSPayloadKeyType];
    VialerLogDebug(@"Push message received from middleware of type: %@", payloadType);
    VialerLogVerbose(@"Payload:\n%@", payload);

    if ([payloadType isEqualToString:MiddlewareAPNSPayloadKeyCall]) {
        // Incoming call.

        if (![SystemUser currentUser].sipEnabled) {
            // User is not SIP enabled.
            // Sent not available to the middleware.
            VialerLogDebug(@"Not accepting call, SIP Disabled, Sending Available = NO to middleware");
            [self respondToMiddleware:payload isAvailable:NO withAccount:nil andPushResponseTimeMeasurementStart:pushResponseTimeMeasurementStart];
            return;
        }

        // Register the account with the endpoint. This should trigger correct internet connection.
        [SIPUtils registerSIPAccountWithEndpointWithCompletion:^(BOOL success, VSLAccount *account) {
            // Check if register was success.
            if (!success) {
                VialerLogDebug(@"SIP Endpoint registration FAILED. Sending Available = NO to middleware");
                [self respondToMiddleware:payload isAvailable:NO withAccount:nil andPushResponseTimeMeasurementStart:pushResponseTimeMeasurementStart];
                dispatch_async(dispatch_get_main_queue(), ^{
                    [SIPUtils removeSIPEndpoint];
                });
                return;
            }

            // Now check the network connection.
            if (self.reachability.hasHighSpeed) {
                // Highspeed, let's respond to the middleware with a success.
                [self respondToMiddleware:payload isAvailable:success withAccount:account andPushResponseTimeMeasurementStart:pushResponseTimeMeasurementStart];
            } else {
                // Connection is not good enough.
                // Sent not available to the middleware.
                VialerLogDebug(@"Not accepting call, connection quality insufficient. Sending Available = NO to middleware");
                [self respondToMiddleware:payload isAvailable:NO withAccount:nil andPushResponseTimeMeasurementStart:pushResponseTimeMeasurementStart];
                dispatch_async(dispatch_get_main_queue(), ^{
                    [SIPUtils removeSIPEndpoint];
                });
            }
        }];

    } else if ([payloadType isEqualToString:MiddlewareAPNSPayloadKeyCheckin]) {
        VialerLogDebug(@"Checking payload:\n %@", payload);
    } else if ([payloadType isEqualToString:MiddlewareAPNSPayloadKeyMessage] && self.systemUser.sipEnabled) {
        VialerLogDebug(@"Another device took over the SIP account, disabling account.");
        self.systemUser.sipEnabled = NO;
        NSNotification *notification = [NSNotification notificationWithName:MiddlewareRegistrationOnOtherDeviceNotification object:nil];
        [[NSNotificationQueue defaultQueue] enqueueNotification:notification postingStyle:NSPostASAP];
    }
}

- (void)respondToMiddleware:(NSDictionary *)payload isAvailable:(BOOL)available withAccount:(VSLAccount *)account andPushResponseTimeMeasurementStart:(NSDate *)pushResponseTimeMeasurmentStart  {
    // Track the response that is sent to the middleware.
    NSString *connectionTypeString = self.reachability.statusString;
    [VialerGAITracker pushNotificationWithIsAccepted:available connectionType:connectionTypeString];

    // Track the pushed call in Core Data.
    [PushedCall findOrCreateFor:payload accepted:available connectionType:connectionTypeString in:self.context];
    [self.context save:nil];

    NSString *middlewareBaseURLString = payload[MiddlewareAPNSPayloadKeyResponseAPI];
    VialerLogDebug(@"Responding to Middleware with URL: %@", middlewareBaseURLString);
    MiddlewareRequestOperationManager *middlewareToRespondTo = [[MiddlewareRequestOperationManager alloc] initWithBaseURLasString:middlewareBaseURLString];

    [middlewareToRespondTo sentCallResponseToMiddleware:payload isAvailable:available withCompletion:^(NSError * _Nullable error) {
        // Whole response cycle completed, log duration.
        NSTimeInterval responseTime = [[NSDate date] timeIntervalSinceDate:pushResponseTimeMeasurmentStart];
        [VialerGAITracker respondedToIncomingPushNotificationWithResponseTime:responseTime];
        VialerLogDebug(@"Middleware response time: [%f s]", responseTime);

        if (error) {
            // Not only do we want to unregister upon a 408 but on every error.
            [account unregisterAccount:nil];
            VialerLogError(@"The middleware responded with an error: %@", error);
        } else {
            VialerLogDebug(@"Succsesfully sent \"availabe: %@\" to middleware", available ? @"YES" : @"NO");
        }
    }];
}

/**
 *  Invoked when the SystemUserSIPCredentialsChangedNotification is received.
 */
- (void)updateAPNSTokenOnSIPCredentialsChange {
    if (self.systemUser.sipEnabled) {
        VialerLogInfo(@"Sip Credentials have changed, updating Middleware");
        [self sentAPNSToken:[APNSHandler storedAPNSToken]];
    }
}

- (void)deleteDeviceRegistrationFromMiddleware:(NSNotification *)notification {
    VialerLogInfo(@"SIP Disabled, unregistering from middleware");
    NSString *storedAPNSToken = [APNSHandler storedAPNSToken];
    NSString *sipAccount = notification.object;

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
    // This is for debuging, can be removed in the future
    // Inserted to debug VIALI-3176. Remove with VIALI-3178
    NSString *applicationState;
    switch ([UIApplication sharedApplication].applicationState) {
            case UIApplicationStateActive: {
                applicationState = @"UIApplicationStateActive";
                break;
            }
            case UIApplicationStateInactive: {
                applicationState = @"UIApplicationStateInactive";
                break;
            }
            case UIApplicationStateBackground: {
                applicationState = @"UIApplicationStateBackground";
                break;
            }
    }

    NSString *backgroundTimeRemaining = @"N/A";
    if ([UIApplication sharedApplication].applicationState == UIApplicationStateBackground) {
        backgroundTimeRemaining = [NSString stringWithFormat:@"%.4f", [UIApplication sharedApplication].backgroundTimeRemaining];
    }

    VialerLogInfo(@"Trying to sent APNSToken to middleware. Application state: \"%@\". Background time remaining: %@", applicationState, backgroundTimeRemaining);
    // End debugging statements

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
