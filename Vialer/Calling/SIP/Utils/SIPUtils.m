//
//  SIPUtils.m
//  Copyright © 2016 VoIPGRID. All rights reserved.
//

#import "SIPUtils.h"

#import "SystemUser.h"
#import "Vialer-Swift.h"

@implementation SIPUtils

# pragma mark - Methods

+ (BOOL)setupSIPEndpoint {
    VialerLogDebug(@"Setup the endpoint for VoIP");
    if (![SystemUser currentUser].sipEnabled) {
        return NO;
    }

    VialerLogInfo(@"Endpoint Available: %@, Use encryption: %@, TLS enabled: %@, SIP endpoint TLS: %@",
                  [VialerSIPLib sharedInstance].endpointAvailable ? @"YES" : @"NO",
                  [SystemUser currentUser].sipUseEncryption ? @"YES": @"NO",
                  [SystemUser currentUser].useTLS ? @"YES" : @"NO",
                  [VialerSIPLib sharedInstance].hasTLSTransport ? @"YES" : @"NO");

    if ((![VialerSIPLib sharedInstance].hasTLSTransport && [SystemUser currentUser].sipUseEncryption && [SystemUser currentUser].useTLS) ||
        ([VialerSIPLib sharedInstance].hasTLSTransport && ![SystemUser currentUser].sipUseEncryption && ![SystemUser currentUser].useTLS)) {
        VialerLogDebug(@"Endpoint or User is not TLS ready so remove the endoint so a fresh one can be setup");
        [SIPUtils removeSIPEndpoint];
    }

    VSLEndpointConfiguration *endpointConfiguration = [[VSLEndpointConfiguration alloc] init];
    endpointConfiguration.logLevel = 4;
    endpointConfiguration.userAgent = [NSString stringWithFormat:@"iOS:%@-%@", [[NSBundle mainBundle] bundleIdentifier], [AppInfo currentAppVersion]];
    endpointConfiguration.disableVideoSupport = YES;
    endpointConfiguration.unregisterAfterCall = YES;

    VSLIpChangeConfiguration * ipChangeConfiguration = [[VSLIpChangeConfiguration alloc] init];
    ipChangeConfiguration.ipChangeCallsUpdate = VSLIpChangeConfigurationIpChangeCallsUpdate;
    ipChangeConfiguration.ipAddressChangeReinviteFlags = VSLReinviteFlagsReinitMedia | VSLReinviteFlagsUpdateVia | VSLReinviteFlagsUpdateContact;

    endpointConfiguration.ipChangeConfiguration = ipChangeConfiguration;

    if ([SystemUser currentUser].useStunServers) {
        NSArray *stunServers = [[UrlsConfiguration shared] stunServers];
        if (stunServers.count > 0) {
            VSLStunConfiguration *stunConfiguration = [[VSLStunConfiguration alloc] init];
            stunConfiguration.stunServers = stunServers;
            endpointConfiguration.stunConfiguration = stunConfiguration;
        }
    }

    if ([SystemUser currentUser].sipUseEncryption && [SystemUser currentUser].useTLS) {
        endpointConfiguration.transportConfigurations = @[[VSLTransportConfiguration configurationWithTransportType:VSLTransportTypeTLS]];
    } else {
        endpointConfiguration.transportConfigurations = @[[VSLTransportConfiguration configurationWithTransportType:VSLTransportTypeTCP],
                                                          [VSLTransportConfiguration configurationWithTransportType:VSLTransportTypeUDP]];
    }

    VSLCodecConfiguration *codecConfiguration = [[VSLCodecConfiguration alloc] init];
    codecConfiguration.audioCodecs = @[
                                       [[VSLAudioCodecs alloc] initWithAudioCodec:VSLAudioCodecILBC andPriority:210]
                                       ];
    endpointConfiguration.codecConfiguration = codecConfiguration;

    NSError *error;
    BOOL success = [[VialerSIPLib sharedInstance] configureLibraryWithEndPointConfiguration:endpointConfiguration error:&error];
    if (!success || error) {
        VialerLogError(@"Failed to startup VialerSIPLib: %@", error);
    }

    VialerLogInfo(@"Endpoint Available: %@, Use encryption: %@, TLS enabled: %@, SIP endpoint TLS: %@",
                  [VialerSIPLib sharedInstance].endpointAvailable ? @"YES" : @"NO",
                  [SystemUser currentUser].sipUseEncryption ? @"YES": @"NO",
                  [SystemUser currentUser].useTLS ? @"YES" : @"NO",
                  [VialerSIPLib sharedInstance].hasTLSTransport ? @"YES" : @"NO");

    return success;
}

+ (void)removeSIPEndpoint {
    [[VialerSIPLib sharedInstance] removeEndpoint];
}

+ (VSLAccount *)addSIPAccountToEndpoint {
    if (![VialerSIPLib sharedInstance].endpointAvailable) {
        [SIPUtils setupSIPEndpoint];
    }

    NSError *error;
    VSLAccount *account = [[VialerSIPLib sharedInstance] createAccountWithSipUser:[SystemUser currentUser] error:&error];

    if (error) {
        VialerLogError(@"Add SIP Account to Endpoint failed: %@", error);
    }

    return account;
}

+ (void)registerSIPAccountWithEndpointWithCompletion:(void (^)(BOOL success, VSLAccount *account))completion {
    BOOL forceUpdate = NO;
    if ((![VialerSIPLib sharedInstance].hasTLSTransport && [SystemUser currentUser].sipUseEncryption && [SystemUser currentUser].useTLS) ||
        ([VialerSIPLib sharedInstance].hasTLSTransport && ![SystemUser currentUser].sipUseEncryption && ![SystemUser currentUser].useTLS)) {
        BOOL success = [SIPUtils setupSIPEndpoint];
        if (!success) {
            VialerLogError(@"Error setting up endpoint");
            completion(NO, nil);
        }
    } else {
        if ([[VialerSIPLib sharedInstance] firstAccount]) {
            VialerLogDebug(@"Update the registration to make sure it is correct");
            forceUpdate = YES;
        }
    }

    [[VialerSIPLib sharedInstance] registerAccountWithUser:[SystemUser currentUser] forceRegistration:forceUpdate withCompletion:^(BOOL success, VSLAccount *account) {
        if (!success) {
            VialerLogError(@"Error registering the account with the endpoint");
        }
        completion(success, account);
    }];
}

+ (BOOL)anotherCallInProgress:(VSLCall *)receivedCall {
    return [[VialerSIPLib sharedInstance] anotherCallInProgress:receivedCall];
}

+ (VSLCall *)getFirstActiveCall {
    VSLAccount *account = [[VialerSIPLib sharedInstance] firstAccount];
    VSLCall *call = [account firstActiveCall];
    return call;
}
@end
