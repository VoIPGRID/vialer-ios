//
//  APNSHandler.m
//  Copyright © 2016 voipgrid.com. All rights reserved.
//

#import "APNSHandler.h"
#import <CocoaLumberjack/CocoaLumberjack.h>
#import "PZPushMiddleware.h"
#import "SystemUser.h"

static const DDLogLevel ddLogLevel = DDLogLevelVerbose;

@interface APNSHandler ()
@property (strong, nonatomic) PKPushRegistry *voipRegistry;
@end

@implementation APNSHandler

#pragma mark - Lifecycle
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
}

- (void)pushRegistry:(PKPushRegistry *)registry didUpdatePushCredentials:(PKPushCredentials *)credentials forType:(NSString *)type {
    DDLogInfo(@"%@ type APNS registration successful. Token: %@", type, credentials.token);
}

@end
