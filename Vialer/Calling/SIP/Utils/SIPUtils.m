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
        return NO;
    }

    VSLEndpointConfiguration *endpointConfiguration = [[VSLEndpointConfiguration alloc] init];
    endpointConfiguration.logLevel = 4;
    endpointConfiguration.userAgent = [NSString stringWithFormat:@"iOS:%@-%@",[[NSBundle mainBundle] bundleIdentifier], [AppInfo currentAppVersion]];

    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"UseTCPConnection"]) {
    endpointConfiguration.transportConfigurations = @[[VSLTransportConfiguration configurationWithTransportType:VSLTransportTypeTCP],
                                                      [VSLTransportConfiguration configurationWithTransportType:VSLTransportTypeUDP]];
    } else {
        endpointConfiguration.transportConfigurations = @[[VSLTransportConfiguration configurationWithTransportType:VSLTransportTypeUDP]];
    }

    NSError *error;
    BOOL success = [[VialerSIPLib sharedInstance] configureLibraryWithEndPointConfiguration:endpointConfiguration error:&error];
    if (!success || error) {
        VialerLogError(@"Failed to startup VialerSIPLib: %@", error);
    }
    [[VialerSIPLib sharedInstance] onlyUseIlbc:YES];
    return success;
}

+ (void)removeSIPEndpoint {
    [[VialerSIPLib sharedInstance] removeEndpoint];
}

+ (VSLAccount *)addSIPAccountToEndpoint {
    NSError *error;
    VSLAccount *account = [[VialerSIPLib sharedInstance] createAccountWithSipUser:[SystemUser currentUser] error:&error];

    if (error) {
        VialerLogError(@"Add SIP Account to Endpoint failed: %@", error);
    }

    return account;
}

+ (void)registerSIPAccountWithEndpointWithCompletion:(void (^)(BOOL success, VSLAccount *account))completion {
    if (![VialerSIPLib sharedInstance].endpointAvailable) {
        BOOL success = [SIPUtils setupSIPEndpoint];
        if (!success) {
            VialerLogError(@"Error setting up endpoint");
            completion(NO, nil);
        }
    }

    [[VialerSIPLib sharedInstance] registerAccountWithUser:[SystemUser currentUser] withCompletion:^(BOOL success, VSLAccount *account) {
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
