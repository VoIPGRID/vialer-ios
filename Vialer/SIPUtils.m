//
//  SIPUtils.m
//  Copyright © 2016 VoIPGRID. All rights reserved.
//

#import "SIPUtils.h"
#import "SystemUser.h"
#import "VialerSIPLib-iOS/VialerSIPLib.h"

@implementation SIPUtils

# pragma mark - Methods

+ (BOOL)setupSIPEndpoint {
    if (![SystemUser currentUser].sipAllowed || ![SystemUser currentUser].sipEnabled) {
        return NO;
    }

    VSLEndpointConfiguration *endpointConfiguration = [[VSLEndpointConfiguration alloc] init];
    VSLTransportConfiguration *updTransportConfiguration = [VSLTransportConfiguration configurationWithTransportType:VSLTransportTypeUDP];

    endpointConfiguration.transportConfigurations = @[updTransportConfiguration];

    NSError *error;
    BOOL success = [[VialerSIPLib sharedInstance] configureLibraryWithEndPointConfiguration:endpointConfiguration error:&error];
    if (!success || error) {
        NSLog(@"Failed to startup VialerSIPLib: %@", error);
    }

    return success;
}

+ (void)removeSIPEndpoint {
    [[VialerSIPLib sharedInstance] removeEndpoint];
}

@end
