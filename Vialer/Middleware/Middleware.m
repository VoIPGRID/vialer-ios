//
//  Middleware.m
//  Copyright © 2016 VoIPGRID. All rights reserved.
//

#import "Middleware.h"

#import "APNSHandler.h"
#import <CocoaLumberjack/CocoaLumberjack.h>
#import "ReachabilityManager.h"
#import "SystemUser.h"
#import "VoIPGRIDRequestOperationManager+Middleware.h"

static const DDLogLevel ddLogLevel = DDLogLevelVerbose;

static NSString * const MiddlewareAPNSPayloadKeyType       = @"type";
static NSString * const MiddlewareAPNSPayloadKeyCall       = @"call";
static NSString * const MiddlewareAPNSPayloadKeyCheckin    = @"checkin";
static NSString * const MiddlewareAPNSPayloadKeyMessage    = @"message";

NSString *const MiddlewareAPNSPayloadKeyResponseAPI = @"response_api";

@interface Middleware ()
@property (strong, nonatomic) VoIPGRIDRequestOperationManager *middlewareRequestOperationManager;
@property (strong, nonatomic) ReachabilityManager *reachabilityManager;
@property (weak, nonatomic) SystemUser *systemUser;
@end

@implementation Middleware

#pragma mark - Lifecycle
- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:SystemUserSIPCredentialsChangedNotification object:nil];
}

- (instancetype)init {
    self = [super init];
    if (self) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateAPNSTokenOnSIPCredentialsChange) name:SystemUserSIPCredentialsChangedNotification object:nil];
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

- (VoIPGRIDRequestOperationManager *)middlewareRequestOperationManager {
    if (!_middlewareRequestOperationManager) {
        NSURL *baseURL = [NSURL URLWithString: [Configuration UrlForKey:ConfigurationMiddleWareBaseURLString]];
        _middlewareRequestOperationManager = [[VoIPGRIDRequestOperationManager alloc] initWithBaseURL:baseURL];
        _middlewareRequestOperationManager.responseSerializer = [AFHTTPResponseSerializer serializer];

        //To have DELETE also put it's parameters into the request body: (Default on JSON Serializer is to put them in URI)
        _middlewareRequestOperationManager.requestSerializer.HTTPMethodsEncodingParametersInURI = [NSSet setWithObjects:@"GET", @"HEAD", nil];
    }
    return _middlewareRequestOperationManager;
}

- (ReachabilityManager *)reachabilityManager {
    if (!_reachabilityManager) {
        _reachabilityManager = [[ReachabilityManager alloc] init];
    }
    return _reachabilityManager;
}

#pragma mark - actions
- (void)handleReceivedAPSNPayload:(NSDictionary *)payload {
    NSString *payloadType = payload[MiddlewareAPNSPayloadKeyType];

    if ([payloadType isEqualToString:MiddlewareAPNSPayloadKeyCall]) {
        //Incoming call
        if ([self.reachabilityManager currentReachabilityStatus] == ReachabilityManagerStatusHighSpeed) {
            // signal "Ok to accept Call" to middleware
        } else {
            // signal "could not accept call" to middleware
        }
    } else if ([payloadType isEqualToString:MiddlewareAPNSPayloadKeyCheckin]) {

    } else if ([payloadType isEqualToString:MiddlewareAPNSPayloadKeyMessage]) {

    }
}
/**
 *  Invoked when the SystemUserSIPCredentialsChangedNotification is received.
 */
- (void)updateAPNSTokenOnSIPCredentialsChange {
    if (self.systemUser.sipEnabled) {
        DDLogInfo(@"Sip Credentials have changed, updating Middleware");
        [self sentAPNSToken:[APNSHandler storedAPNSToken]];
    } else {
        DDLogInfo(@"User disabled SIP, unregistering from middleware");
        //TODO: VIALI-3111
    }
}

- (void)deleteDeviceRegistrationFromMiddleware {
    NSString *storedAPNSToken = [APNSHandler storedAPNSToken];
    NSString *sipAccount = self.systemUser.sipAccount;

    if (sipAccount && storedAPNSToken) {
        [self.middlewareRequestOperationManager deleteDeviceRecordWithAPNSToken:storedAPNSToken sipAccount:sipAccount withCompletion:^(NSError *error) {
            if (error) {
                DDLogError(@"Error deleting device record from middleware. %@", error);
            } else {
                DDLogInfo(@"Middleware device record deleted successfully");
            }
        }];
    } else {
        DDLogDebug(@"Not deleting device registration from middleware, SIP Account(%@) not set or no APNS Token(%@) stored.",
                   sipAccount, storedAPNSToken);
    }
}

- (void)sentAPNSToken:(NSString *)apnsToken {
    if (self.systemUser.sipEnabled) {
        [self.middlewareRequestOperationManager updateDeviceRecordWithAPNSToken:apnsToken sipAccount:self.systemUser.sipAccount withCompletion:^(NSError *error) {
            if (error) {
                DDLogError(@"Device registration with Middleware failed. %@", error);
            } else {
                DDLogInfo(@"Middelware registration successfull");
            }
        }];
    }
}

@end
