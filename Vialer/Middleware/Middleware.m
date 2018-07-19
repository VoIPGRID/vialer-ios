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
#import "VialerSIPLib.h"

static NSString * const MiddlewareAPNSPayloadKeyType       = @"type";
static NSString * const MiddlewareAPNSPayloadKeyCall       = @"call";
static NSString * const MiddlewareAPNSPayloadKeyCheckin    = @"checkin";
static NSString * const MiddlewareAPNSPayloadKeyMessage    = @"message";
static NSString * const MiddlewareAPNSPayloadKeyUniqueKey  = @"unique_key";
static NSString * const MiddlewareAPNSPayloadKeyAttempt    = @"attempt";

static NSString * const MiddlewareAPNSPayloadKeyResponseAPI = @"response_api";
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
    [[NSNotificationCenter defaultCenter] removeObserver:self name:SystemUserSIPCredentialsChangedNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:SystemUserSIPDisabledNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:VSLCallStateChangedNotification object: nil];
}

- (instancetype)init {
    self = [super init];
    if (self) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateAPNSTokenOnSIPCredentialsChange) name:SystemUserSIPCredentialsChangedNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deleteDeviceRegistrationFromMiddleware:) name:SystemUserSIPDisabledNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(callStateChanged:) name:VSLCallStateChangedNotification object:nil];
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
        NSString *baseURLString = [[Configuration defaultConfiguration] UrlForKey:ConfigurationMiddleWareBaseURLString];
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
- (void)handleReceivedAPSNPayload:(NSDictionary *)payload {
    // Set current time to measure response time.
    NSDate *pushResponseTimeMeasurementStart = [NSDate date];

    NSString *payloadType = payload[MiddlewareAPNSPayloadKeyType];
    VialerLogDebug(@"Push message received from middleware of type: %@", payloadType);
    VialerLogDebug(@"Payload:\n%@", payload);

    if ([payloadType isEqualToString:MiddlewareAPNSPayloadKeyCall]) {
        // Separate VialerLog for the push notification that will be posted to LogEntries
        VialerLogPushNotification(@"iOS : %@\n", payload);
        
        double timeToInitialReport = ([pushResponseTimeMeasurementStart timeIntervalSince1970] - [[payload valueForKey:@"message_start_time"] doubleValue]) * 1000 ;
        NSString *keyToProcess = payload[MiddlewareAPNSPayloadKeyUniqueKey];
        int attempt = [payload[MiddlewareAPNSPayloadKeyAttempt] intValue];
        
        // Log statement to middleware for received push notification
        [VialerStats sharedInstance].middlewareUniqueKey = keyToProcess;
        [[VialerStats sharedInstance] logStatementForReceivedPushNotificationWithAttempt:attempt];
        
        // Incoming call.
        if (![SystemUser currentUser].sipEnabled) {
            // User is not SIP enabled.
            // Send not available to the middleware.
            VialerLogWarning(@"Not accepting call, SIP Disabled, Sending Available = NO to middleware");
            [self respondToMiddleware:payload isAvailable:NO withAccount:nil andPushResponseTimeMeasurementStart:pushResponseTimeMeasurementStart];
            return;
        }

        // Check for network connection before registering the account at pjsip.
        if (![[ReachabilityHelper sharedInstance] connectionFastEnoughForVoIP]) {
            VialerLogInfo(@"Wait for the next push! We currently don't have a network connection");
            if (attempt == MiddlewareMaxAttempts) {
                [[VialerStats sharedInstance] incomingCallFailedAfterEightPushNotificationsWithTimeToInitialReport:timeToInitialReport];
            }
            return;
        }

        VialerLogDebug(@"Middleware key: %@, Processing notificiation key: %@", keyToProcess, self.pushNotificationProcessing);

        if ([self.pushNotificationProcessing isEqualToString:keyToProcess]) {
            VialerLogInfo(@"Already processing a push notification with key: %@", keyToProcess);
            return;
        }

        self.pushNotificationProcessing = keyToProcess;
        // Register the account with the endpoint. This should trigger correct internet connection.
        [SIPUtils registerSIPAccountWithEndpointWithCompletion:^(BOOL success, VSLAccount *account) {
            // Check if register was success.
            if (!success) {
                // Check if it was the last attempt. If so remove the endpoint and send no to the middleware.
                if (attempt == MiddlewareMaxAttempts) {
                    VialerLogWarning(@"SIP Endpoint registration FAILED after 8 tries. Sending Available = NO to middleware");
                    [self respondToMiddleware:payload isAvailable:NO withAccount:nil andPushResponseTimeMeasurementStart:pushResponseTimeMeasurementStart];
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [SIPUtils removeSIPEndpoint];
                    });
                    [[VialerStats sharedInstance] incomingCallFailedAfterEightPushNotificationsWithTimeToInitialReport:timeToInitialReport];
                    self.pushNotificationProcessing = nil;
                } else {
                    // Registration has failed. But we are not at the last attempt yet, so we try again with the next notification.
                    VialerLogInfo(@"Registration of the account has failed, trying again with the next push. attempt: %d", attempt);
                    self.pushNotificationProcessing = nil;
                }
                return;
            } else {
                // The SIP account was successful registered.
                // Now check the network connection.
                if ([[ReachabilityHelper sharedInstance] connectionFastEnoughForVoIP]) {
                    // Highspeed, let's respond to the middleware with a success.
                    VialerLogDebug(@"Accepting call on push attempt: %d. Sending Available = YES to middleware", attempt);

                    [VialerStats sharedInstance].middlewareUniqueKey = self.pushNotificationProcessing;
                    [self respondToMiddleware:payload isAvailable:YES withAccount:account andPushResponseTimeMeasurementStart:pushResponseTimeMeasurementStart];
                } else if (attempt == MiddlewareMaxAttempts) {
                    // Connection is not good enough.
                    // Send not available to the middleware.
                    VialerLogWarning(@"Not accepting call, max number of attempts reached, connection quality insufficient. Sending Available = NO to middleware");
                    [self respondToMiddleware:payload isAvailable:NO withAccount:nil andPushResponseTimeMeasurementStart:pushResponseTimeMeasurementStart];
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [SIPUtils removeSIPEndpoint];
                    });
                    self.pushNotificationProcessing = nil;
                    
                    [VialerGAITracker declineIncomingCallBecauseOfInsufficientInternetConnectionEvent];
                    // Calling middleware to log that the call was rejected due to insufficient internet connection.
                    [self.commonMiddlewareRequestOperationManager sendHangupReasonToMiddleware:@"Rejected - Insufficient internet connection" forUniqueKey:keyToProcess withCompletion:^(NSError * _Nullable error) {
                        if (error) {
                            VialerLogError(@"The middleware responded with an error: %@", error);
                        } else {
                            VialerLogDebug(@"Successfully sent to middleware that the call was rejected due to insufficient internet connection");
                        }
                    }];
                    // Log to middleware that incoming call failed after 8 received push notifications due to insufficient network.
                    [[VialerStats sharedInstance] incomingCallFailedAfterEightPushNotificationsWithTimeToInitialReport:timeToInitialReport];
                } else if (attempt < MiddlewareMaxAttempts) {
                    VialerLogDebug(@"The network connection is not sufficient. Waiting for a next push");
                    self.pushNotificationProcessing = nil;
                }
            }
        }];

    } else if ([payloadType isEqualToString:MiddlewareAPNSPayloadKeyCheckin]) {
        VialerLogDebug(@"Checkin payload:\n %@", payload);
    } else if ([payloadType isEqualToString:MiddlewareAPNSPayloadKeyMessage] && self.systemUser.sipEnabled) {
        VialerLogWarning(@"Another device took over the SIP account, disabling account.");
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
    PushedCall *pushedCall = [PushedCall findOrCreateFor:payload accepted:available connectionType:connectionTypeString in:self.context];
    [self.context save:nil];

    int attempt = [payload[MiddlewareAPNSPayloadKeyAttempt] intValue];

    NSString *middlewareBaseURLString = payload[MiddlewareAPNSPayloadKeyResponseAPI];
    VialerLogDebug(@"Responding to Middleware for attempt: %d with URL: %@", attempt, middlewareBaseURLString);
    MiddlewareRequestOperationManager *middlewareToRespondTo = [[MiddlewareRequestOperationManager alloc] initWithBaseURLasString:middlewareBaseURLString];

    [middlewareToRespondTo sentCallResponseToMiddleware:payload isAvailable:available withCompletion:^(NSError * _Nullable error) {
        // Whole response cycle completed, log duration.
        NSTimeInterval responseTime = [[NSDate date] timeIntervalSinceDate:pushResponseTimeMeasurmentStart];
        [VialerGAITracker respondedToIncomingPushNotificationWithResponseTime:responseTime];
        VialerLogDebug(@"Middleware response time: [%f s] for attempt: %d", responseTime, attempt);

        if (available) {
            NSNotification *notification = [NSNotification notificationWithName:MiddlewareAccountRegistrationIsDoneNotification object:nil];
            [[NSNotificationQueue defaultQueue] enqueueNotification:notification postingStyle:NSPostASAP];
        }

        if (error) {
            // Not only do we want to unregister upon a 408 but on every error.
            VialerLogError(@"The middleware responded with an error: %@", error);
        } else {
            VialerLogDebug(@"Successfully sent \"availabe: %@\" to middleware", available ? @"YES" : @"NO");
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

- (void)updateDeviceRegistrationWithRemoteLoggingId {
    VialerLogInfo(@"Update middelware with remote logging id");
    NSString *storedAPNSToken = [APNSHandler storedAPNSToken];

    [self sentAPNSToken:storedAPNSToken withCompletion:^(NSError *error) {
        if (error) {
            VialerLogWarning(@"Updating the remote logging id to the middleware has failed %@", [error localizedDescription]);
        } else {
            if ([VialerLogger remoteLoggingEnabled]) {
                VialerLogInfo(@"The remote logging id has been succesful sent to the middleware");
            } else {
                VialerLogInfo(@"The remote logging id has been succesful removed from the middleware");
            }
        }
    }];
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

- (void)callStateChanged:(NSNotification *)notification {
    VSLCallState callState = [notification.userInfo[VSLNotificationUserInfoCallStateKey] intValue];
    
    if (callState == VSLCallStateDisconnected || callState == VSLCallStateConfirmed) {
        VialerLogDebug(@"Call ended or confirmed: Stop processing the notification");
        self.pushNotificationProcessing = nil;
    }
}

@end
