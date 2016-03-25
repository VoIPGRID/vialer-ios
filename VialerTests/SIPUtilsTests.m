//
//  SIPUtilsTest.m
//  Copyright © 2016 VoIPGRID. All rights reserved.
//

#import "SIPUtils.h"
#import "SystemUser.h"
#import <OCMock/OCMock.h>
#import <VialerSIPLib-iOS/VialerSIPLib.h>
@import XCTest;

@interface SIPUtilsTests : XCTestCase
@property (strong, nonatomic) id systemUserMock;
@end

@interface SIPUtils()
+ (BOOL)setupSIPEndpoint;
@end

@interface SystemUser()
@property (readwrite, nonatomic) BOOL isAllowedToSip;
@end

@implementation SIPUtilsTests

- (void)setUp {
    [super setUp];
    self.systemUserMock = OCMClassMock([SystemUser class]);
    OCMStub([self.systemUserMock currentUser]).andReturn(self.systemUserMock);
}

- (void)tearDown {
    [self.systemUserMock stopMocking];
    self.systemUserMock = nil;
    [super tearDown];
}

- (void)testSetupSIPEndPointUserIsNotAllowedToSip {
    OCMStub([self.systemUserMock sipAllowed]).andReturn(NO);

    BOOL success = [SIPUtils setupSIPEndpoint];

    OCMVerify([self.systemUserMock sipAllowed]);

    XCTAssertFalse(success, @"The user should not be allowed to setup the endpoint. Because the user is not allowed to SIP.");
}

- (void)testSetupSIPEndPointWithSystemUserIsAllowedToUseSIP {
    OCMStub([self.systemUserMock sipAllowed]).andReturn(YES);
    OCMStub([self.systemUserMock sipEnabled]).andReturn(YES);

    id vialerSIPLibMock = OCMClassMock([VialerSIPLib class]);
    OCMStub([vialerSIPLibMock sharedInstance]).andReturn(vialerSIPLibMock);
    OCMStub([vialerSIPLibMock configureLibraryWithEndPointConfiguration:[OCMArg any] error:[OCMArg setTo:nil]]).andReturn(YES);

    BOOL success = [SIPUtils setupSIPEndpoint];

    OCMVerify([self.systemUserMock sipAllowed]);
    OCMVerify([self.systemUserMock sipEnabled]);

    XCTAssertTrue(success, @"The endpoint should be setup with the configuration.");

    [vialerSIPLibMock stopMocking];
}

- (void)testNotificationsForSIPCredentials {
    id observerMock  = [OCMockObject observerMock];
    [[NSNotificationCenter defaultCenter] addMockObserver:observerMock name:SystemUserSIPCredentialsChangedNotification object:nil];

    [[observerMock expect] notificationWithName:SystemUserSIPCredentialsChangedNotification object:[OCMArg any]];

    [[NSNotificationCenter defaultCenter] postNotificationName:SystemUserSIPCredentialsChangedNotification object:self];

    [[NSNotificationCenter defaultCenter] removeObserver:observerMock];
    [observerMock verify];
}

- (void)testNotificationsLoggedOutUser {
    id observerMock  = [OCMockObject observerMock];
    [[NSNotificationCenter defaultCenter] addMockObserver:observerMock name:SystemUserLogoutNotification object:nil];

    [[observerMock expect] notificationWithName:SystemUserLogoutNotification object:[OCMArg any]];

    [[NSNotificationCenter defaultCenter] postNotificationName:SystemUserLogoutNotification object:self];

    [[NSNotificationCenter defaultCenter] removeObserver:observerMock];
    [observerMock verify];
}

@end
