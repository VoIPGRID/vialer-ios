//
//  SystemUserTests.m
//  Copyright © 2015 VoIPGRID. All rights reserved.
//

#import <OCMock/OCMock.h>
#import <XCTest/XCTest.h>
#import "SSKeychain.h"
#import "SystemUser.h"
#import "VoIPGRIDRequestOperationManager.h"

@interface SystemUser()
+ (void)persistObject:(id)object forKey:(id)key;
+ (id)readObjectForKey:(id)key;
- (instancetype) initPrivate;

@property (strong, nonatomic)NSString *user;
@property (strong, nonatomic)NSString *sipAccount;
@property (strong, nonatomic)NSString *mobileNumber;
@property (strong, nonatomic)NSString *emailAddress;
@property (strong, nonatomic)NSString *firstName;
@property (strong, nonatomic)NSString *lastName;

@property (nonatomic)BOOL loggedIn;
@property (nonatomic)BOOL isSipAllowed;

@property (strong, nonatomic) VoIPGRIDRequestOperationManager * operationsManager;
@end

@interface SystemUserTests : XCTestCase
@property (nonatomic) SystemUser *user;
@property (nonatomic) id userDefaultsMock;
@property (nonatomic) id operationsMock;
@property (nonatomic) id keychainMock;
@end

@implementation SystemUserTests

- (void)setUp {
    [super setUp];
    self.userDefaultsMock = OCMClassMock([NSUserDefaults class]);
    OCMStub([self.userDefaultsMock standardUserDefaults]).andReturn(self.userDefaultsMock);
    self.user = [[SystemUser alloc] initPrivate];
    self.operationsMock = OCMClassMock([VoIPGRIDRequestOperationManager class]);
    self.user.operationsManager = self.operationsMock;
    self.keychainMock = OCMClassMock([SSKeychain class]);
}

- (void)tearDown {
    [super tearDown];
    [self.userDefaultsMock stopMocking];
    [self.operationsMock stopMocking];
    [self.keychainMock stopMocking];
}


- (void)testSystemUserHasNoDisplayNameOnDefault {
    OCMStub([self.userDefaultsMock objectForKey:[OCMArg any]]).andReturn(nil);

    XCTAssertEqualObjects(self.user.displayName, NSLocalizedString(@"No email address configured", nil), @"it should say there is no display information");
}

- (void)testSystemUserDisplaysUser {
    OCMStub([self.userDefaultsMock objectForKey:@"User"]).andReturn(@"john@apple.com");

    SystemUser *user = [[SystemUser alloc] initPrivate];

    XCTAssertEqualObjects(user.displayName ,@"john@apple.com", @"the user should be displayed");
}

- (void)testSystemUserDisplaysFirstName {
    OCMStub([self.userDefaultsMock objectForKey:@"FirstName"]).andReturn(@"John");
    OCMStub([self.userDefaultsMock objectForKey:@"User"]).andReturn(@"john@apple.com");

    SystemUser *user = [[SystemUser alloc] initPrivate];

    XCTAssertEqualObjects(user.displayName, @"John", @"The firstname should be displayed and not the user");
}

- (void)testSystemUserDisplaysLastName {
    OCMStub([self.userDefaultsMock objectForKey:@"LastName"]).andReturn(@"Appleseed");
    OCMStub([self.userDefaultsMock objectForKey:@"User"]).andReturn(@"john@apple.com");

    SystemUser *user = [[SystemUser alloc] initPrivate];

    XCTAssertEqualObjects(user.displayName, @"Appleseed", @"The lastname should be displayed and not the user");
}

- (void)testSystemUserDisplaysFirstAndLastName {
    OCMStub([self.userDefaultsMock objectForKey:@"FirstName"]).andReturn(@"John");
    OCMStub([self.userDefaultsMock objectForKey:@"LastName"]).andReturn(@"Appleseed");
    OCMStub([self.userDefaultsMock objectForKey:@"User"]).andReturn(@"john@apple.com");

    SystemUser *user = [[SystemUser alloc] initPrivate];

    XCTAssertEqualObjects(user.displayName, @"John Appleseed", @"The fullname should be displayed and not the user");
}

- (void)testSystemUserDisplaysEmailAddress {
    OCMStub([self.userDefaultsMock objectForKey:@"Email"]).andReturn(@"john@apple.com");
    OCMStub([self.userDefaultsMock objectForKey:@"User"]).andReturn(@"steve@apple.com");

    SystemUser *user = [[SystemUser alloc] initPrivate];

    XCTAssertEqualObjects(user.displayName, @"john@apple.com", @"The emailaddress should be displayed and not the user");
}

- (void)testSystemUserDisplaysFirstNameBeforeEmail {
    OCMStub([self.userDefaultsMock objectForKey:@"FirstName"]).andReturn(@"John");
    OCMStub([self.userDefaultsMock objectForKey:@"Email"]).andReturn(@"john@apple.com");

    SystemUser *user = [[SystemUser alloc] initPrivate];

    XCTAssertEqualObjects(user.displayName, @"John", @"The firstname should be displayed and not the emailaddress");
}

- (void)testLoginUserWillLoginOnRemote {
    [self.user loginWithUsername:@"testUsername" password:@"testPassword" completion:nil];

    OCMVerify([self.operationsMock loginWithUsername:[OCMArg isEqual:@"testUsername"] password:[OCMArg isEqual:@"testPassword"] withCompletion:[OCMArg any]]);
}

- (void)testLoginUserWillStoreCredentials {
    NSDictionary *response = @{@"client": @"42"};
    OCMStub([self.operationsMock loginWithUsername:[OCMArg any] password:[OCMArg any] withCompletion:[OCMArg checkWithBlock:^BOOL(void (^passedBlock)(NSDictionary *responseData, NSError *error)) {
        passedBlock(response, nil);
        return YES;
    }]]);
    [self.user loginWithUsername:@"testUsername" password:@"testPassword" completion:nil];

    OCMVerify([SSKeychain setPassword:[OCMArg isEqual:@"testPassword"] forService:[OCMArg any] account:[OCMArg isEqual:@"testUsername"]]);
    XCTAssertEqualObjects(self.user.username, @"testUsername", @"The correct username should have been set");
}

- (void)testFetchPropertiesFromRemoteWillSetPropertiesOnInstance {
    NSDictionary *response  = @{@"client": @"42",
                                @"first_name": @"John",
                                @"last_name": @"Appleseed"
                                };
    OCMStub([self.operationsMock loginWithUsername:[OCMArg any] password:[OCMArg any] withCompletion:[OCMArg checkWithBlock:^BOOL(void (^passedBlock)(NSDictionary *responseData, NSError *error)) {
        passedBlock(response, nil);
        return YES;
    }]]);

    [self.user loginWithUsername:@"testUsername" password:@"testPassword" completion:nil];

    XCTAssertEqualObjects(self.user.displayName, @"John Appleseed", @"The correct first and lastname should have been fetched.");
}

- (void)testSystemUserHasNoSipEnabledOnDefault {
    XCTAssertFalse(self.user.sipEnabled, @"On default, is should not be possible to call sip.");
}

- (void)testSystemUserHasNoSipAllowedOnDefault {
    XCTAssertFalse(self.user.sipAllowed, @"On default, is should not be allowed to call sip.");
}

- (void)testLoggingInWithUserWithSIPAllowedWillStoreSIPCredentialsInUserDefaults {
    NSDictionary *response = @{@"client": @"42",
                               @"allow_app_account": @"true"};
    OCMStub([self.operationsMock loginWithUsername:[OCMArg any] password:[OCMArg any] withCompletion:[OCMArg checkWithBlock:^BOOL(void (^passedBlock)(NSDictionary *responseData, NSError *error)) {
        passedBlock(response, nil);
        return YES;
    }]]);

    [self.user loginWithUsername:@"testUser" password:@"testPassword" completion:nil];

    OCMVerify([self.userDefaultsMock setBool:YES forKey:@"SIPAllowed"]);
}

- (void)testLoggingInWithUserWithSIPEnabledWillFetchAppAccount {
    NSDictionary *response = @{@"client": @"42",
                               @"allow_app_account": @"true",
                               @"app_account": @"/account/12340042",
                               };
    OCMStub([self.operationsMock loginWithUsername:[OCMArg any] password:[OCMArg any] withCompletion:[OCMArg checkWithBlock:^BOOL(void (^passedBlock)(NSDictionary *responseData, NSError *error)) {
        passedBlock(response, nil);
        return YES;
    }]]);

    [self.user loginWithUsername:@"testUser" password:@"testPassword" completion:nil];

    OCMVerify([self.operationsMock retrievePhoneAccountForUrl:[OCMArg isEqual:@"/account/12340042"] withCompletion:[OCMArg any]]);
}

- (void)testFetchingAppAccountWillSetProperCredentials {
    NSDictionary *response = @{@"client": @"42",
                               @"allow_app_account": @"true",
                               @"app_account": @"/account/12340042",
                               };
    OCMStub([self.operationsMock loginWithUsername:[OCMArg any] password:[OCMArg any] withCompletion:[OCMArg checkWithBlock:^BOOL(void (^passedBlock)(NSDictionary *responseData, NSError *error)) {
        passedBlock(response, nil);
        return YES;
    }]]);
    NSDictionary *responseAppAccount = @{@"account_id": @12340042,
                                         @"password": @"testPassword",
                                         };
    OCMStub([self.operationsMock retrievePhoneAccountForUrl:[OCMArg any] withCompletion:[OCMArg checkWithBlock:^BOOL(void (^passedBlock)(AFHTTPRequestOperation *operation, NSDictionary *responseData, NSError *error)) {
        passedBlock(nil, responseAppAccount, nil);
        return YES;
    }]]);
    OCMStub([SSKeychain passwordForService:[OCMArg any] account:[OCMArg any]]).andReturn(@"testPassword");

    [self.user loginWithUsername:@"testUser" password:@"testPassword" completion:nil];

    OCMVerify([self.userDefaultsMock setObject:[OCMArg isEqual:@"12340042"] forKey:[OCMArg isEqual:@"SIPAccount"]]);
    OCMVerify([SSKeychain setPassword:[OCMArg isEqual:@"testPassword"] forService:[OCMArg any] account:@"12340042"]);
    XCTAssertEqualObjects(self.user.sipAccount, @"12340042", @"the correct sipaccount should have been set");
    XCTAssertEqualObjects(self.user.sipPassword, @"testPassword", @"the correct sipaccount should have been set");
    XCTAssertFalse(self.user.sipEnabled, @"When sip settings are retrieved, sip isn't enabled on default.");
    XCTAssertTrue(self.user.sipAllowed, @"It should be possible for the user to use sip");
}

- (void)testLoggingInUserWithoutSIPEnabledWillPostLoginNotification {
    id mockNotificationCenter = OCMClassMock([NSNotificationCenter class]);
    OCMStub([mockNotificationCenter defaultCenter]).andReturn(mockNotificationCenter);

    NSDictionary *response = @{@"client": @"42",
                               @"allow_app_account": @"false",
                               };
    OCMStub([self.operationsMock loginWithUsername:[OCMArg any] password:[OCMArg any] withCompletion:[OCMArg checkWithBlock:^BOOL(void (^passedBlock)(NSDictionary *responseData, NSError *error)) {
        passedBlock(response, nil);
        return YES;
    }]]);

    [self.user loginWithUsername:@"testUser" password:@"testPassword" completion:nil];

    OCMVerify([mockNotificationCenter postNotificationName:[OCMArg isEqual:SystemUserLoginNotification] object:[OCMArg isEqual:self.user]]);

    [mockNotificationCenter stopMocking];
}

- (void)testLoggingInUserWithSIPEnabledWillPostLoginNotification {
    id mockNotificationCenter = OCMClassMock([NSNotificationCenter class]);
    OCMStub([mockNotificationCenter defaultCenter]).andReturn(mockNotificationCenter);

    NSDictionary *response = @{@"client": @"42",
                               @"allow_app_account": @"true",
                               };
    OCMStub([self.operationsMock loginWithUsername:[OCMArg any] password:[OCMArg any] withCompletion:[OCMArg checkWithBlock:^BOOL(void (^passedBlock)(NSDictionary *responseData, NSError *error)) {
        passedBlock(response, nil);
        return YES;
    }]]);
    NSDictionary *responseAppAccount = @{@"account_id": @12340042,
                                         @"password": @"testPassword",
                                         };
    OCMStub([self.operationsMock retrievePhoneAccountForUrl:[OCMArg any] withCompletion:[OCMArg checkWithBlock:^BOOL(void (^passedBlock)(AFHTTPRequestOperation *operation, NSDictionary *responseData, NSError *error)) {
        passedBlock(nil, responseAppAccount, nil);
        return YES;
    }]]);

    [self.user loginWithUsername:@"testUser" password:@"testPassword" completion:nil];

    OCMVerify([mockNotificationCenter postNotificationName:[OCMArg isEqual:SystemUserLoginNotification] object:[OCMArg isEqual:self.user]]);

    [mockNotificationCenter stopMocking];
}

- (void)testLoggingOutUserWillPostLogoutNotification {
    id mockNotificationCenter = OCMClassMock([NSNotificationCenter class]);
    OCMStub([mockNotificationCenter defaultCenter]).andReturn(mockNotificationCenter);

    [self.user logout];

    OCMVerify([mockNotificationCenter postNotificationName:SystemUserLogoutNotification object:self.user]);
    [mockNotificationCenter stopMocking];
}

- (void)testUserWithAllowedToSipInDefaultsWillAllowSip {
    OCMStub([self.userDefaultsMock boolForKey:@"SIPAllowed"]).andReturn(YES);

    SystemUser *user = [[SystemUser alloc] initPrivate];

    XCTAssertTrue(user.sipAllowed, @"It should be allowed to use sip if defaults says so.");
}

- (void)testUserCanEnableSIPWhenHeIsAllowed {
    OCMStub([self.userDefaultsMock boolForKey:@"SIPAllowed"]).andReturn(YES);
    SystemUser *user = [[SystemUser alloc] initPrivate];

    user.sipEnabled = YES;

    OCMVerify([self.userDefaultsMock setBool:YES forKey:@"SipEnabled"]);
}

- (void)testUserHasSipAccountAndPasswordWhenInSUD {
    OCMStub([self.userDefaultsMock objectForKey:[OCMArg isEqual:@"SIPAccount"]]).andReturn(@"12340042");
    OCMStub([SSKeychain passwordForService:[OCMArg any] account:[OCMArg any]]).andReturn(@"testPassword");

    SystemUser *user = [[SystemUser alloc] initPrivate];

    XCTAssertEqualObjects(user.sipAccount, @"12340042", @"The correct sipAccount should have been retrieved.");
    XCTAssertEqualObjects(user.sipPassword, @"testPassword", @"The correct sip password should have been retrieved.");
}

- (void)testUpdateSIPAccountInformationWhenAsked {
    // Make sure we have a properly loggedin user.
    SystemUser *user = [[SystemUser alloc] initPrivate];
    user.operationsManager = self.operationsMock;
    user.sipEnabled = YES;
    user.loggedIn = YES;

    // Fake user profile.
    NSDictionary *response = @{@"client": @"42",
                               @"app_account": @"/account/12340044",
                               };
    OCMStub([self.operationsMock userProfileWithCompletion:[OCMArg checkWithBlock:^BOOL(void (^passedBlock)(AFHTTPRequestOperation *operation, NSDictionary *responseData, NSError *error)) {
        passedBlock(nil, response, nil);
        return YES;
    }]]);

    // Fake sip account.
    NSDictionary *responseAppAccount = @{@"account_id": @12340044,
                                         @"password": @"newTestPassword",
                                         };
    OCMStub([self.operationsMock retrievePhoneAccountForUrl:[OCMArg any] withCompletion:[OCMArg checkWithBlock:^BOOL(void (^passedBlock)(AFHTTPRequestOperation *operation, NSDictionary *responseData, NSError *error)) {
        passedBlock(nil, responseAppAccount, nil);
        return YES;
    }]]);

    XCTestExpectation *expectation = [self expectationWithDescription:@"Expect status call from TwoStepCall."];
    [user updateSIPAccountWithSuccess:^(BOOL success, NSError *error) {
        XCTAssertTrue(success, @"It should have been a success when updating the SIP account of the user.");
        XCTAssertNil(error, @"There should be no error");
        XCTAssertEqualObjects(user.sipAccount, @"12340044", @"The new account should have been set.");
        XCTAssertEqualObjects(user.sipPassword, @"newTestPassword", @"The new account should have been set.");
        [expectation fulfill];
    }];

    [self waitForExpectationsWithTimeout:0.5 handler:^(NSError * _Nullable error) {
        NSLog(@"Error: %@", error);
    }];
}

@end
