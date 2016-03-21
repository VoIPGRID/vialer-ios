//
//  SIPUtils.m
//  Copyright © 2016 VoIPGRID. All rights reserved.
//

#import "SIPUtils.h"

#import "SystemUser.h"

@implementation SIPUtils

# pragma mark - Methods

+ (BOOL)setupSIPEndpoint {
    if (![SystemUser currentUser].sipAllowed || ![SystemUser currentUser].sipEnabled) {
        return NO;
    }

    VSLEndpointConfiguration *endpointConfiguration = [[VSLEndpointConfiguration alloc] init];
    endpointConfiguration.transportConfigurations = @[[VSLTransportConfiguration configurationWithTransportType:VSLTransportTypeTCP],
                                                      [VSLTransportConfiguration configurationWithTransportType:VSLTransportTypeUDP]];

    NSError *error;
    BOOL success = [[VialerSIPLib sharedInstance] configureLibraryWithEndPointConfiguration:endpointConfiguration error:&error];
    if (!success || error) {
        DDLogError(@"Failed to startup VialerSIPLib: %@", error);
    }

    return success;
}

+ (void)removeSIPEndpoint {
    [[VialerSIPLib sharedInstance] removeEndpoint];
}

+ (VSLAccount *)addSIPAccountToEndpoint {
    NSError *error;
    VSLAccount *account = [[VialerSIPLib sharedInstance] createAccountWithSipUser:[SystemUser currentUser] error:&error];

    if (error) {
        DDLogError(@"Add SIP Account to Endpoint failed: %@", error);
    }

    return account;
}

+ (void)registerSIPAccountWithEndpointWithCompletion:(void (^)(BOOL))completion {
    if (![VialerSIPLib sharedInstance].endpointAvailable) {
        BOOL success = [SIPUtils setupSIPEndpoint];
        if (!success) {
            DDLogError(@"Error setting up endpoint");
            completion(NO);
        }
    }

    [[VialerSIPLib sharedInstance] registerAccountWithUser:[SystemUser currentUser] withCompletion:^(BOOL success, VSLAccount *account) {
        if (!success) {
            DDLogError(@"Error registering the account with the endpoint");
        }
        completion(success);
    }];
}

+ (NSString *)cleanPhoneNumber:(NSString *)phoneNumber {
    phoneNumber = [[phoneNumber componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] componentsJoinedByString:@""];
    return [[phoneNumber componentsSeparatedByCharactersInSet:[[NSCharacterSet characterSetWithCharactersInString:@"+0123456789*#"] invertedSet]] componentsJoinedByString:@""];
}

+ (VSLCall *)getCallWithId:(NSString *)callId {
    if (!callId) {
        return nil;
    }

    VSLCall *call = [[VialerSIPLib sharedInstance] getVSLCallWithId:callId andSipUser:[SystemUser currentUser]];

    return call;
}

+ (NSString *)getCallName:(VSLCall *)call {
    NSString *callName;

    if (call.callerName && call.callerNumber) {
        callName = [NSString stringWithFormat:@"%@\n%@", call.callerName, call.callerNumber];
    } else if (call.callerName && !call.callerNumber) {
        callName = [NSString stringWithFormat:@"%@", call.callerName];
    } else if (!call.callerName && call.callerNumber) {
        callName = [NSString stringWithFormat:@"%@", call.callerNumber];
    } else {
        callName = [NSString stringWithFormat:@"%@", call.remoteURI];
    }
    return callName;
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