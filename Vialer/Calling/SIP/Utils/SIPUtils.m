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
        VialerLogWarning(@"Not setting up sip endpoint because sip disabled");
        return NO;
    }

    VialerLogInfo(@"SIP endpoint available: %@", [VialerSIPLib sharedInstance].endpointAvailable ? @"YES" : @"NO");
    if ([VialerSIPLib sharedInstance].endpointAvailable) {
        BOOL shouldRemoveEndpoint = NO;
        if ((![VialerSIPLib sharedInstance].hasTLSTransport && [SystemUser currentUser].sipUseEncryption && [SystemUser currentUser].useTLS) ||
            ([VialerSIPLib sharedInstance].hasTLSTransport && ![SystemUser currentUser].sipUseEncryption && ![SystemUser currentUser].useTLS)) {
            VialerLogDebug(@"Endpoint or User is not TLS ready so remove the endoint so a fresh one can be setup");
            shouldRemoveEndpoint = YES;
        }

        // User has STUN enbaled but the enpoint is not configured to use STUN.
        if ([SystemUser currentUser].useStunServers && ![VialerSIPLib sharedInstance].hasSTUNEnabled) {
            VialerLogDebug(@"User has STUN ENABLED but the enpoint is not configured to use STUN. Setup a new endpoint with STUN");
            shouldRemoveEndpoint = YES;
        } else if (![SystemUser currentUser].useStunServers && [VialerSIPLib sharedInstance].hasSTUNEnabled) {
            VialerLogDebug(@"User has STUN DISABLED but the endpoint is configured to use STUN. Setup a new endpoint without STUN");
            shouldRemoveEndpoint = YES;
        }

        if (shouldRemoveEndpoint) {
            // Remove all endpoint accounts for VialerSIPLib to allow the endpoint removal.
            for (VSLAccount* account in [VialerSIPLib sharedInstance].endpoint.accounts) {
                [[VialerSIPLib sharedInstance].endpoint removeAccount:account];
            }
            [SIPUtils removeSIPEndpoint];
        }
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

    endpointConfiguration.codecConfiguration = [SIPUtils codecConfiguration];

    NSError *error;
    BOOL success = [[VialerSIPLib sharedInstance] configureLibraryWithEndPointConfiguration:endpointConfiguration error:&error];
    if (!success || error) {
        VialerLogError(@"Failed to startup VialerSIPLib: %@", error);
    }

    VialerLogInfo(@"TLS status: endpoint: %@, user setting: %@",
                  [VialerSIPLib sharedInstance].hasTLSTransport ? @"YES" : @"NO",
                  ([SystemUser currentUser].sipUseEncryption && [SystemUser currentUser].useTLS) ? @"YES" : @"NO");
    VialerLogInfo(@"STUN status: endpoint: %@, user setting: %@",
                  [VialerSIPLib sharedInstance].hasSTUNEnabled ? @"YES": @"NO",
                  [SystemUser currentUser].useStunServers ? @"YES" : @"NO");

    return success;
}

+ (void)removeSIPEndpoint {
    [[VialerSIPLib sharedInstance] removeEndpoint];
}

+ (BOOL)updateCodecs {
    VialerLogDebug(@"Updating the codec which is being used");
    VSLCodecConfiguration *codecConfiguration = [SIPUtils codecConfiguration];
    VSLAudioCodecs *codec = codecConfiguration.audioCodecs.firstObject;
    VialerLogDebug(@"Swithcing to codec: %@", [VSLAudioCodecs codecString: codec.codec]);
    if (![[VialerSIPLib sharedInstance] updateCodecConfiguration:codecConfiguration]) {
        [SIPUtils removeSIPEndpoint];
        [SIPUtils setupSIPEndpoint];
    }

    return YES;
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

    [[VialerSIPLib sharedInstance] registerAccountWithUser:[SystemUser currentUser]  forceRegistration:forceUpdate withCompletion:^(BOOL success, VSLAccount *account) {
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

+ (VSLCodecConfiguration *)codecConfiguration {
    VSLCodecConfiguration *codecConfiguration = [[VSLCodecConfiguration alloc] init];

    if ([SystemUser currentUser].currentAudioQuality > 0) {
        codecConfiguration.audioCodecs = @[
                                           [[VSLAudioCodecs alloc] initWithAudioCodec:VSLAudioCodecOpus andPriority:210]
                                           ];
        VSLOpusConfiguration *opusConfiguration = [[VSLOpusConfiguration alloc] init];
        //opusConfiguration.frameDuration = VSLOpusConfigurationFrameDurationTwenty; // VSLOpusConfigurationFrameDurationSixty is default (=VSLOpusConfigurationFrameDurationDefault)

        opusConfiguration.constantBitRate = YES;
        
        codecConfiguration.opusConfiguration = opusConfiguration;
    } else {
        codecConfiguration.audioCodecs = @[
                                           [[VSLAudioCodecs alloc] initWithAudioCodec:VSLAudioCodecILBC andPriority:210]
                                           ];
    }

    return codecConfiguration;
}
@end
