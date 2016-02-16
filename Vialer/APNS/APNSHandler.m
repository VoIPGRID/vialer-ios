//
//  APNSHandler.m
//  Copyright © 2016 voipgrid.com. All rights reserved.
//

#import "APNSHandler.h"
#import <CocoaLumberjack/CocoaLumberjack.h>
#import "PZPushMiddleware.h"
#import "ReachabilityManager.h"
#import "SystemUser.h"

static const DDLogLevel ddLogLevel = DDLogLevelVerbose;

@interface APNSHandler ()
@property (strong, nonatomic) PKPushRegistry *voipRegistry;
@property (strong, nonatomic) ReachabilityManager *reachabilityManger;
@end

@implementation APNSHandler

#pragma mark - Lifecycle
- (void)dealloc {
    self.reachabilityManger = nil;
}

+ (instancetype)sharedHandler {
    static APNSHandler *sharedAPNSHandler = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        DDLogVerbose(@"Creating shared APNS Handler");
        sharedAPNSHandler = [[self alloc] init];
    });
    return sharedAPNSHandler;
}

#pragma mark - properties
- (PKPushRegistry *)voipRegistry {
    if (!_voipRegistry) {
        _voipRegistry = [[PKPushRegistry alloc] initWithQueue:nil];
    }
    return _voipRegistry;
}

- (ReachabilityManager *)reachabilityManger {
    if (!_reachabilityManger) {
        _reachabilityManger = [[ReachabilityManager alloc] init];
    }
    return _reachabilityManger;
}

#pragma mark - actions
- (void)registerForVoIPNotifications {
    self.voipRegistry.delegate = self;

    DDLogVerbose(@"Initiating VoIP push registration");
    self.voipRegistry.desiredPushTypes = [NSSet setWithObject:PKPushTypeVoIP];
}

#pragma mark - PKPushRegistray management
- (void)pushRegistry:(PKPushRegistry *)registry didInvalidatePushTokenForType:(NSString *)type {
    DDLogInfo(@"APNS Token became invalid");
}

- (void)pushRegistry:(PKPushRegistry *)registry didReceiveIncomingPushWithPayload:(PKPushPayload *)payload forType:(NSString *)type {
    DDLogDebug(@"%s Incoming push notification of type: %@", __PRETTY_FUNCTION__, type);

    if ([self.reachabilityManger currentReachabilityStatus] == ReachabilityManagerStatusHighSpeed) {
        // signal "Ok to accept Call" to middleware
    } else {
        // signal "could not accept call" to middleware
    }
}

- (void)pushRegistry:(PKPushRegistry *)registry didUpdatePushCredentials:(PKPushCredentials *)credentials forType:(NSString *)type {
    DDLogInfo(@"%@ type APNS registration successful. Token: %@", type, credentials.token);
}

@end
