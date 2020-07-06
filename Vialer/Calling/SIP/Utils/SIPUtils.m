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
    if (![SystemUser currentUser].sipEnabled) {
        VialerLogWarning(@"Not setting up sip endpoint because sip disabled");
        return NO;
    }
    
    if ([VialerSIPLib sharedInstance].endpointAvailable && [self getFirstActiveCall] == nil) {
        for (VSLAccount* account in [VialerSIPLib sharedInstance].endpoint.accounts) {
            [[VialerSIPLib sharedInstance].endpoint removeAccount:account];
        }
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

+ (BOOL)safelyRemoveSipEndpoint {
    if ([VialerSIPLib sharedInstance].endpointAvailable && [self getFirstCall] == nil) {
        for (VSLAccount* account in [VialerSIPLib sharedInstance].endpoint.accounts) {
            [[VialerSIPLib sharedInstance].endpoint removeAccount:account];
        }
        [SIPUtils removeSIPEndpoint];
        return true;
    }

    return false;
}

+ (void)removeSIPEndpoint {
    [[VialerSIPLib sharedInstance] removeEndpoint];
}

+ (BOOL)updateCodecs {
    VialerLogDebug(@"Updating the codec which is being used");
    VSLCodecConfiguration *codecConfiguration = [SIPUtils codecConfiguration];
    VSLAudioCodecs *codec = codecConfiguration.audioCodecs.firstObject;
    VialerLogDebug(@"Swithcing to codec: %@", [VSLAudioCodecs codecString: codec.codec]);
    [[VialerSIPLib sharedInstance] updateCodecConfiguration:codecConfiguration];
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
    [[VialerSIPLib sharedInstance] registerAccountWithUser:[SystemUser currentUser]  forceRegistration:false withCompletion:^(BOOL success, VSLAccount *account) {
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

+ (VSLCall *)getFirstCall {
    VSLAccount *account = [[VialerSIPLib sharedInstance] firstAccount];
    VSLCall *call = [account firstCall];
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

        opusConfiguration.constantBitRate = NO;
        
        codecConfiguration.opusConfiguration = opusConfiguration;
    } else {
        codecConfiguration.audioCodecs = @[
                                           [[VSLAudioCodecs alloc] initWithAudioCodec:VSLAudioCodecILBC andPriority:210]
                                           ];
    }

    return codecConfiguration;
}
@end
