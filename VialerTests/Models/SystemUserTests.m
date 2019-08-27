//
//  SystemUserTests.m
//  Copyright © 2015 VoIPGRID. All rights reserved.
//

#import <OCMock/OCMock.h>
#import "SAMKeychain.h"
#import "SystemUser.h"
#import "TestKVOObserverClass.h"
#import "VoIPGRIDRequestOperationManager.h"
@import XCTest;

@interface SystemUser()
+ (void)persistObject:(id)object forKey:(id)key;
+ (id)readObjectForKey:(id)key;
- (instancetype) initPrivate;

@property (strong, nonatomic) NSString *username;
@property (strong, nonatomic) NSString *sipAccount;
@property (strong, nonatomic) NSString *mobileNumber;
@property (strong, nonatomic) NSString *emailAddress;
@property (strong, nonatomic) NSString *firstName;
@property (strong, nonatomic) NSString *preposition;
@property (strong, nonatomic) NSString *lastName;
@property (strong, nonatomic) NSString *clientID;

@property (nonatomic) BOOL loggedIn;

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
    self.keychainMock = OCMClassMock([SAMKeychain class]);
}

- (void)tearDown {
    self.user = nil;
    [self.userDefaultsMock stopMocking];
    self.userDefaultsMock = nil;
    [self.operationsMock stopMocking];
    self.operationsMock = nil;
    [self.keychainMock stopMocking];
    self.keychainMock = nil;
    [super tearDown];
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

- (void)testSystemUserDisplaysFirstNamePrepositionAndLastName {
    OCMStub([self.userDefaultsMock objectForKey:@"FirstName"]).andReturn(@"John");
    OCMStub([self.userDefaultsMock objectForKey:@"Preposition"]).andReturn(@"of");
    OCMStub([self.userDefaultsMock objectForKey:@"LastName"]).andReturn(@"Appleseed");
    OCMStub([self.userDefaultsMock objectForKey:@"User"]).andReturn(@"john@apple.com");

    SystemUser *user = [[SystemUser alloc] initPrivate];

    XCTAssertEqualObjects(user.displayName, @"John of Appleseed", @"The fullname should be displayed and not the user");
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

    XCTAssertEqualObjects(user.displayName, @"John", @"The firstname should be displayed and not the email address");
}

- (void)testLoginUserWillLoginOnRemote {
    [self.user loginToCheckTwoFactorWithUserName:@"testUsername" password:@"testPassword" andToken:@"testToken" completion:nil];
    
    OCMVerify([self.operationsMock loginWithUserNameForTwoFactor:[OCMArg isEqual:@"testUsername"] password:[OCMArg isEqual:@"testPassword"] orToken:[OCMArg isEqual:@"testToken"] withCompletion:[OCMArg any]]);
}

- (void)testLoginUserWillStoreCredentials {
    NSDictionary *response = @{@"client": @"42"};
    
    OCMStub([self.operationsMock loginWithUserNameForTwoFactor:[OCMArg any] password:[OCMArg any] orToken:[OCMArg any] withCompletion:([OCMArg checkWithBlock:^BOOL(void (^passedBlock)(NSDictionary *responseData, NSError *error)) {
        passedBlock(response, nil);
        return YES;
    }])]);

    OCMStub([self.operationsMock getSystemUserInfowithCompletion:[OCMArg checkWithBlock:^BOOL(void (^passedBlock)(NSDictionary *responseData, NSError *error)) {
        passedBlock(response, nil);
        return YES;
    }]]);
    
    [self.user loginToCheckTwoFactorWithUserName:@"testUsername" password:@"testPassword" andToken:@"testToken" completion:nil];

    OCMVerify([SAMKeychain setPassword:[OCMArg isEqual:@"testPassword"] forService:[OCMArg any] account:[OCMArg isEqual:@"testUsername"]]); //this is always verified....! Even if it is the only line in this test and has random values like testPassword223132 and testUsername24324..
    
    XCTAssertEqualObjects(self.user.username, @"testUsername", @"The correct username should have been set");
}

- (void)testFetchPropertiesFromRemoteWillSetPropertiesOnInstance {
    NSDictionary *response  = @{@"client": @"42",
                                @"first_name": @"John",
                                @"last_name": @"Appleseed"
                                };

    OCMStub([self.operationsMock loginWithUserNameForTwoFactor:[OCMArg any] password:[OCMArg any] orToken:[OCMArg any] withCompletion:[OCMArg checkWithBlock:^BOOL(void (^passedBlock)(NSDictionary *responseData, NSError *error)) {
        passedBlock(response, nil);
        return YES;
    }]]);
    
    OCMStub([self.operationsMock getSystemUserInfowithCompletion:[OCMArg checkWithBlock:^BOOL(void (^passedBlock)(NSDictionary *responseData, NSError *error)) {
        passedBlock(response, nil);
        return YES;
    }]]);

    [self.user loginToCheckTwoFactorWithUserName:@"testUsername" password:@"testPassword" andToken:@"testToken" completion:nil];
    
    XCTAssertEqualObjects(self.user.displayName, @"John Appleseed", @"The correct first and lastname should have been fetched.");
}

- (void)testFetchPropertiesFromRemoteWillSetAllPropertiesOnInstance {
    NSDictionary *response  = @{@"client": @"42",
                                @"first_name": @"John",
                                @"preposition": @"of",
                                @"last_name": @"Appleseed"
                                };

    OCMStub([self.operationsMock loginWithUserNameForTwoFactor:[OCMArg any] password:[OCMArg any] orToken:[OCMArg any] withCompletion:[OCMArg checkWithBlock:^BOOL(void (^passedBlock)(NSDictionary *responseData, NSError *error)) {
        passedBlock(response, nil);
        return YES;
    }]]);
    
    OCMStub([self.operationsMock getSystemUserInfowithCompletion:[OCMArg checkWithBlock:^BOOL(void (^passedBlock)(NSDictionary *responseData, NSError *error)) {
        passedBlock(response, nil);
        return YES;
    }]]);
    
    [self.user loginToCheckTwoFactorWithUserName:@"testUsername" password:@"testPassword" andToken:@"testToken" completion:nil];

    XCTAssertEqualObjects(self.user.displayName, @"John of Appleseed", @"The correct firstname, preposition and lastname should have been fetched.");
}

- (void)testSystemUserHasNoSipEnabledOnDefault {
    XCTAssertFalse(self.user.sipEnabled, @"On default, is should not be possible to call sip.");
}

- (void)testSystemUserWithSipEnabledAndSipAccountWillSetSoOnInit {
    OCMStub([self.userDefaultsMock boolForKey:@"SipEnabled"]).andReturn(YES);
    OCMStub([self.userDefaultsMock objectForKey:@"SIPAccount"]).andReturn(@"12340042");
    OCMStub([self.userDefaultsMock objectForKey:@"User"]).andReturn(@"johna");

    SystemUser *newUser = [[SystemUser alloc] initPrivate];
    
    XCTAssertTrue(newUser.sipEnabled, @"The user should be able to call SIP");
}

- (void)testSystemUserWithSipEnabledAndSipAccountWillPostNotification {
    OCMStub([self.userDefaultsMock boolForKey:@"SipEnabled"]).andReturn(YES);
    OCMStub([self.userDefaultsMock objectForKey:@"SIPAccount"]).andReturn(@"12340042");
    OCMStub([self.userDefaultsMock objectForKey:@"User"]).andReturn(@"johna");
    
    SystemUser *newUser = [SystemUser alloc];
    
    [self expectationForNotification:SystemUserSIPCredentialsChangedNotification
                              object:newUser
                             handler:^BOOL(NSNotification * _Nonnull notification) {
                                 NSLog(@"Notification observed");
                                 return YES;
                             }];
    
    newUser = [newUser initPrivate];
    
    [self waitForExpectationsWithTimeout:5.0 handler:^(NSError * _Nullable error) {
        if (error) {
            NSLog(@"expectation Timeout!");
        }
    }];
}

- (void)testSystemUserHasNoWifiNotificationDisabledOnDefault {
    XCTAssertFalse(self.user.showWiFiNotification, @"On default, is should not be possible to call sip.");
}

- (void)testSystemUserHasWithNoWifiNotificationWhenInSUD {
    OCMStub([self.userDefaultsMock boolForKey:@"ShowWiFiNotification"]).andReturn(YES);
    
    SystemUser *newUser = [[SystemUser alloc] initPrivate];

    XCTAssertTrue(newUser.showWiFiNotification, @"ShowWifiNotification should be YES");
}

- (void)testSystemUserWithChangesNoWiFiNotificationWillStoreInSUD {

    self.user.showWiFiNotification = YES;
    OCMVerify([self.userDefaultsMock setBool:YES forKey:@"ShowWiFiNotification"]);
}

- (void)testLoggingInWithUserWithSIPEnabledWillFetchAppAccount {
    NSDictionary *response = @{@"client": @"42"};
    
    OCMStub([self.operationsMock loginWithUserNameForTwoFactor:[OCMArg any] password:[OCMArg any] orToken:[OCMArg any] withCompletion:[OCMArg checkWithBlock:^BOOL(void (^passedBlock)(NSDictionary *responseData, NSError *error)) {
        passedBlock(response, nil);
        return YES;
    }]]);

    OCMStub([self.operationsMock userProfileWithCompletion:[OCMArg checkWithBlock:^BOOL(void (^passedBlock)(NSURL *operation, NSDictionary *responseData, NSError *error)) {
        passedBlock(nil, response, nil);
        return YES;
    }]]);
    
    OCMStub([self.operationsMock getSystemUserInfowithCompletion:[OCMArg checkWithBlock:^BOOL(void (^passedBlock)(NSDictionary *responseData, NSError *error)) {
        passedBlock(response, nil);
        return YES;
    }]]);

    [self.user loginToCheckTwoFactorWithUserName:@"testUsername" password:@"testPassword" andToken:@"testToken" completion:nil];

    OCMVerify([self.operationsMock getMobileProfileWithCompletion:[OCMArg any]]);
}

- (void)testFetchingAppAccountWillSetProperCredentials {
    NSDictionary *response = @{@"client": @"42",
                               @"app_account": @"/account/12340042",
                               };
    
    OCMStub([self.operationsMock loginWithUserNameForTwoFactor:[OCMArg any] password:[OCMArg any] orToken:[OCMArg any] withCompletion:[OCMArg checkWithBlock:^BOOL(void (^passedBlock)(NSDictionary *responseData, NSError *error)) {
        passedBlock(response, nil);
        return YES;
    }]]);
    
    NSDictionary *responseAppAccount = @{@"appaccount_account_id": @12340042,
                                         @"appaccount_password": @"testPassword",
                                         };

    OCMStub([self.operationsMock userProfileWithCompletion:[OCMArg checkWithBlock:^BOOL(void (^passedBlock)(NSURLResponse *operation, NSDictionary *responseData, NSError *error)) {
        passedBlock(nil, response, nil);
        return YES;
    }]]);
    
    OCMStub([self.operationsMock getSystemUserInfowithCompletion:[OCMArg checkWithBlock:^BOOL(void (^passedBlock)(NSDictionary *responseData, NSError *error)) {
        passedBlock(response, nil);
        return YES;
    }]]);
    
    OCMStub([self.operationsMock getMobileProfileWithCompletion:[OCMArg checkWithBlock:^BOOL(void (^passedBlock)(NSURLResponse *operation, NSDictionary *responseData, NSError *error)) {
        passedBlock(nil, responseAppAccount, nil);
        return YES;
    }]]);
    
    OCMStub([self.operationsMock pushUseEncryptionWithCompletion:[OCMArg checkWithBlock:^BOOL(void (^passedBlock)(BOOL success, NSError *error)) {
        passedBlock(YES, nil);
        return YES;
    }]]);

    OCMStub([SAMKeychain passwordForService:[OCMArg any] account:[OCMArg any]]).andReturn(@"testPassword");

    [self.user loginToCheckTwoFactorWithUserName:@"testUsername" password:@"testPassword" andToken:@"testToken" completion:^(BOOL loggedin, BOOL tokenRequired, NSError *error) {
        OCMVerify([self.userDefaultsMock setObject:[OCMArg isEqual:@"12340042"] forKey:[OCMArg isEqual:@"SIPAccount"]]);
    }];
    
    OCMVerify([SAMKeychain setPassword:[OCMArg isEqual:@"testPassword"] forService:[OCMArg any] account:@"12340042"]);
    XCTAssertEqualObjects(self.user.sipAccount, @"12340042", @"the correct sipaccount should have been set");
    XCTAssertEqualObjects(self.user.sipPassword, @"testPassword", @"the correct sipaccount should have been set");
    XCTAssertTrue(self.user.sipEnabled, @"Setting: \"Enable VoIP\" should have been enabled");
}

- (void)testLoggingInUserWithoutSIPEnabledWillPostLoginNotification {
    id mockNotificationCenter = OCMClassMock([NSNotificationCenter class]);
    OCMStub([mockNotificationCenter defaultCenter]).andReturn(mockNotificationCenter);

    NSDictionary *response = @{@"client": @"42"};
    OCMStub([self.operationsMock loginWithUserNameForTwoFactor:[OCMArg any] password:[OCMArg any] orToken:[OCMArg any] withCompletion:[OCMArg checkWithBlock:^BOOL(void (^passedBlock)(NSDictionary *responseData, NSError *error)) {
        passedBlock(response, nil);
        return YES;
    }]]);
    
    OCMStub([self.operationsMock userProfileWithCompletion:[OCMArg checkWithBlock:^BOOL(void (^passedBlock)(NSURLResponse *operation, NSDictionary *responseData, NSError *error)) {
        passedBlock(nil, response, nil);
        return YES;
    }]]);
    
    OCMStub([self.operationsMock getSystemUserInfowithCompletion:[OCMArg checkWithBlock:^BOOL(void (^passedBlock)(NSDictionary *responseData, NSError *error)) {
        passedBlock(response, nil);
        return YES;
    }]]);

    [self.user loginToCheckTwoFactorWithUserName:@"testUsername" password:@"testPassword" andToken:@"testToken" completion:nil];

    OCMVerify([mockNotificationCenter postNotificationName:[OCMArg isEqual:SystemUserLoginNotification] object:[OCMArg isEqual:self.user]]);

    [mockNotificationCenter stopMocking];
}

- (void)testLoggingInUserWithSIPEnabledWillPostLoginNotification {
    id mockNotificationCenter = OCMClassMock([NSNotificationCenter class]);
    OCMStub([mockNotificationCenter defaultCenter]).andReturn(mockNotificationCenter);

    NSDictionary *response = @{@"client": @"42"};
     OCMStub([self.operationsMock loginWithUserNameForTwoFactor:[OCMArg any] password:[OCMArg any] orToken:[OCMArg any] withCompletion:[OCMArg checkWithBlock:^BOOL(void (^passedBlock)(NSDictionary *responseData, NSError *error)) {
        passedBlock(response, nil);
        return YES;
    }]]);
    
    NSDictionary *responseAppAccount = @{@"appaccount_account_id": @12340042,
                                         @"appaccount_password": @"testPassword",
                                         };

    OCMStub([self.operationsMock userProfileWithCompletion:[OCMArg checkWithBlock:^BOOL(void (^passedBlock)(NSURLResponse *operation, NSDictionary *responseData, NSError *error)) {
        passedBlock(nil, response, nil);
        return YES;
    }]]);
    
    OCMStub([self.operationsMock getSystemUserInfowithCompletion:[OCMArg checkWithBlock:^BOOL(void (^passedBlock)(NSDictionary *responseData, NSError *error)) {
        passedBlock(response, nil);
        return YES;
    }]]);
    
    OCMStub([self.operationsMock getMobileProfileWithCompletion:[OCMArg checkWithBlock:^BOOL(void (^passedBlock)(NSURLResponse *operation, NSDictionary *responseData, NSError *error)) {
        passedBlock(nil, responseAppAccount, nil);
        return YES;
    }]]);
    
    OCMStub([self.operationsMock pushUseEncryptionWithCompletion:[OCMArg checkWithBlock:^BOOL(void (^passedBlock)(BOOL success, NSError *error)) {
        passedBlock(YES, nil);
        return YES;
    }]]);

    [self.user loginToCheckTwoFactorWithUserName:@"testUsername" password:@"testPassword" andToken:@"testToken" completion:^(BOOL loggedin, BOOL tokenRequired, NSError *error) {
    }];

    OCMVerify([mockNotificationCenter postNotificationName:[OCMArg isEqual:SystemUserLoginNotification] object:[OCMArg isEqual:self.user]]);
    
    [mockNotificationCenter stopMocking];
}

- (void)testLoggingOutUserWillPostLogoutNotification {
    id mockNotificationCenter = OCMClassMock([NSNotificationCenter class]);
    OCMStub([mockNotificationCenter defaultCenter]).andReturn(mockNotificationCenter);

    [self.user logout];

    OCMVerify([mockNotificationCenter postNotificationName:SystemUserLogoutNotification object:[OCMArg isEqual:self.user] userInfo:[OCMArg any]]);
    [mockNotificationCenter stopMocking];
}

- (void)testUnAuthorizedNotificationWillLogoutUser {
    self.user.loggedIn = YES;
    
    [[NSNotificationCenter defaultCenter] postNotificationName:VoIPGRIDRequestOperationManagerUnAuthorizedNotification object:self.user];
    
    XCTAssertFalse(self.user.loggedIn, @"The user should be logged out.");
}

- (void)testUserCannotEnableSIPWhenHeHasNoSipAccount {
    SystemUser *user = [[SystemUser alloc] initPrivate];

    user.sipEnabled = YES;

    XCTAssertFalse(user.sipEnabled, @"It should not be possible to enable sip.");
    [[self.userDefaultsMock reject] setBool:YES forKey:@"SipEnabled"];
}

- (void)testUserCanEnableSIPWhenHeIsAllowedAndHasAccount {
    OCMStub([self.userDefaultsMock boolForKey:@"SipEnabled"]).andReturn(YES);
    
    SystemUser *user = [[SystemUser alloc] initPrivate];
    user.sipAccount = @"42";
    user.loggedIn = YES;
    user.sipEnabled = YES;
    
    OCMVerify([self.userDefaultsMock setBool:YES forKey:@"SipEnabled"]);
}

- (void)testUserHasSipAccountAndPasswordWhenInSUD {
    OCMStub([self.userDefaultsMock objectForKey:[OCMArg isEqual:@"SIPAccount"]]).andReturn(@"12340042");
    id keyChainMock = OCMClassMock([SAMKeychain class]);
    OCMStub([keyChainMock passwordForService:[OCMArg any] account:[OCMArg any]]).andReturn(@"testPassword");

    SystemUser *user = [[SystemUser alloc] initPrivate];

    XCTAssertEqualObjects(user.sipAccount, @"12340042", @"The correct sipAccount should have been retrieved.");
    XCTAssertEqualObjects(user.sipPassword, @"testPassword", @"The correct sip password should have been retrieved.");

    [keyChainMock stopMocking];
}

- (void)testUpdateSIPAccountInformationWhenAsked {
    // Make sure we have a properly logged in user.
    SystemUser *user = [[SystemUser alloc] initPrivate];
    user.operationsManager = self.operationsMock;
    user.sipAccount = @"42";
    user.loggedIn = YES;
    user.sipEnabled = YES;

    // Fake user profile.
    NSDictionary *response = @{@"client": @"42",
                               @"app_account": @"/account/12340044",
                               };
    OCMStub([self.operationsMock userProfileWithCompletion:[OCMArg checkWithBlock:^BOOL(void (^passedBlock)(NSURLResponse *operation, NSDictionary *responseData, NSError *error)) {
        passedBlock(nil, response, nil);
        return YES;
    }]]);

    // Fake sip account.
    NSDictionary *responseAppAccount = @{@"appaccount_account_id": @12340044,
                                         @"appaccount_password": @"newTestPassword",
                                         };

    OCMStub([self.operationsMock userProfileWithCompletion:[OCMArg checkWithBlock:^BOOL(void (^passedBlock)(NSURLResponse *operation, NSDictionary *responseData, NSError *error)) {
        passedBlock(nil, response, nil);
        return YES;
    }]]);
    
    OCMStub([self.operationsMock getSystemUserInfowithCompletion:[OCMArg checkWithBlock:^BOOL(void (^passedBlock)(NSDictionary *responseData, NSError *error)) {
        passedBlock(response, nil);
        return YES;
    }]]);
    
    OCMStub([self.operationsMock getMobileProfileWithCompletion:[OCMArg checkWithBlock:^BOOL(void (^passedBlock)(NSURLResponse *operation, NSDictionary *responseData, NSError *error)) {
        passedBlock(nil, responseAppAccount, nil);
        return YES;
    }]]);
    
    OCMStub([self.operationsMock pushUseEncryptionWithCompletion:[OCMArg checkWithBlock:^BOOL(void (^passedBlock)(BOOL success, NSError *error)) {
        passedBlock(YES, nil);
        return YES;
    }]]);
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"Expect status call from TwoStepCall."];
    [user getAndActivateSIPAccountWithCompletion:^(BOOL success, NSError *error) {
        XCTAssertTrue(success, @"It should have been a success when updating the SIP account of the user.");
        XCTAssertNil(error, @"There should be no error");
        XCTAssertEqualObjects(user.sipAccount, @"12340044", @"The new account should have been set.");
        XCTAssertEqualObjects(user.sipPassword, @"newTestPassword", @"The new account should have been set.");
        [expectation fulfill];
    }];

    [self waitForExpectationsWithTimeout:5.0 handler:^(NSError * _Nullable error) {
        NSLog(@"Error: %@", error);
    }];
}

- (void)testGetAndActivateSipAccountWillAskOperationManagerForProfile {
    SystemUser *user = [[SystemUser alloc] initPrivate];
    user.operationsManager = self.operationsMock;
    user.loggedIn = YES;
    
    [user getAndActivateSIPAccountWithCompletion:^(BOOL success, NSError *error) {
        OCMVerify([self.operationsMock userProfileWithCompletion:[OCMArg any]]);
    }];
}

- (void)testGetAndActivateSipAccountWillAskOperationManagerToFetchAccount {
    SystemUser *user = [[SystemUser alloc] initPrivate];
    user.operationsManager = self.operationsMock;

    NSDictionary *response = @{@"client": @"42"};
    
    OCMStub([self.operationsMock loginWithUserNameForTwoFactor:[OCMArg any] password:[OCMArg any] orToken:[OCMArg any] withCompletion:[OCMArg checkWithBlock:^BOOL(void (^passedBlock)(NSDictionary *responseData, NSError *error)) {
        passedBlock(response, nil);
        return YES;
    }]]);
    
    OCMStub([self.operationsMock userProfileWithCompletion:[OCMArg checkWithBlock:^BOOL(void (^passedBlock)(NSURLResponse *operation, NSDictionary *responseData, NSError *error)) {
        passedBlock(nil, response, nil);
        return YES;
    }]]);
    
    OCMStub([self.operationsMock getSystemUserInfowithCompletion:[OCMArg checkWithBlock:^BOOL(void (^passedBlock)(NSDictionary *responseData, NSError *error)) {
        passedBlock(response, nil);
        return YES;
    }]]);
    
    user.loggedIn = YES;
    
    [user getAndActivateSIPAccountWithCompletion:nil];
    OCMVerify([self.operationsMock getMobileProfileWithCompletion:[OCMArg any]]);
}

- (void)testGetAndActivateSipAccountWillReturnYESOnSuccess {
    SystemUser *user = [[SystemUser alloc] initPrivate];
    user.operationsManager = self.operationsMock;

    NSDictionary *response = @{@"client": @"42"};
    
    // Fake sip account.
    NSDictionary *responseAppAccount = @{@"appaccount_account_id": @12340044,
                                         @"appaccount_password": @"newTestPassword",
                                         };
    
    OCMStub([self.operationsMock userProfileWithCompletion:[OCMArg checkWithBlock:^BOOL(void (^passedBlock)(NSURLResponse *operation, NSDictionary *responseData, NSError *error)) {
        passedBlock(nil, response, nil);
        return YES;
    }]]);
    
    OCMStub([self.operationsMock getSystemUserInfowithCompletion:[OCMArg checkWithBlock:^BOOL(void (^passedBlock)(NSDictionary *responseData, NSError *error)) {
        passedBlock(response, nil);
        return YES;
    }]]);
    
    OCMStub([self.operationsMock getMobileProfileWithCompletion:[OCMArg checkWithBlock:^BOOL(void (^passedBlock)(NSURLResponse *operation, NSDictionary *responseData, NSError *error)) {
        passedBlock(nil, responseAppAccount, nil);
        return YES;
    }]]);
    
    OCMStub([self.operationsMock pushUseEncryptionWithCompletion:[OCMArg checkWithBlock:^BOOL(void (^passedBlock)(BOOL success, NSError *error)) {
        passedBlock(YES, nil);
        return YES;
    }]]);
    user.loggedIn = YES;

    [user getAndActivateSIPAccountWithCompletion:^(BOOL success, NSError *error) {
        XCTAssertTrue(user.sipEnabled, @"User should have sip enabled");
        XCTAssertEqualObjects(user.sipAccount, @"12340044", @"User should have correct sip account");
    }];
}

- (void)testClientIDSetterWithAURLStyledString {
    // Given
    SystemUser *user = [[SystemUser alloc] initPrivate];
    NSString *plainClientID = @"12345";
    NSString *clientID = [NSString stringWithFormat:@"client = \"/api/apprelation/client/%@/\"", plainClientID];

    // When
    user.clientID = clientID;

    // Then
    XCTAssert([user.clientID isEqualToString:plainClientID], @"Client ID should have been filtered from the given string");
}

- (void)testClientIDSetterWithAPlainUserIDString {
    // Given
    SystemUser *user = [[SystemUser alloc] initPrivate];
    NSString *clientID = @"12345";

    // When
    user.clientID = clientID;

    // Then
    XCTAssert([user.clientID isEqualToString:clientID], @"Client ID should have been set unparsed.");
}

- (void)testClientIDSetterWithAnEmptyString {
    // Given
    SystemUser *user = [[SystemUser alloc] initPrivate];
    NSString *clientID = @"";

    // When
    user.clientID = clientID;

    // Then
    XCTAssertNil(user.clientID, @"Client ID should have been nil");
}

- (void)testClientIDSetterWithANilString {
    // Given
    SystemUser *user = [[SystemUser alloc] initPrivate];
    NSString *clientID = nil;

    // When
    user.clientID = clientID;

    // Then
    XCTAssertNil(user.clientID, @"Client ID should have been nil");
}

- (void)testKVONotificationFiresWhenClientIDChangesFromNilToValue {
    // Given
    NSString *kvoKeypath = NSStringFromSelector(@selector(clientID));
    SystemUser *user = [[SystemUser alloc] initPrivate];
    user.clientID = nil;

    id kvoObserver = OCMClassMock([TestKVOObserverClass class]);
    [user addObserver:kvoObserver forKeyPath:kvoKeypath options:0 context:NULL];

    // When
    NSString *newClientID = @"11111";
    user.clientID = newClientID;

    // Then
    OCMVerify([kvoObserver observeValueForKeyPath:kvoKeypath
                                         ofObject:[OCMArg checkWithBlock:^BOOL(id obj) {
        XCTAssert([user.clientID isEqualToString:newClientID]);
        return true;
    }]
                                           change:[OCMArg any]
                                          context:NULL]);

    OCMExpect([kvoObserver removeObserver:kvoObserver forKeyPath:kvoKeypath]);
    [kvoObserver removeObserver:kvoObserver forKeyPath:kvoKeypath];
    [kvoObserver stopMocking];
}

- (void)testKVONotificationFiresWhenClientIDChanges {
    // Given
    NSString *kvoKeypath = NSStringFromSelector(@selector(clientID));
    SystemUser *user = [[SystemUser alloc] initPrivate];
    user.clientID = @"11111";

    id kvoObserver = OCMClassMock([TestKVOObserverClass class]);
    [user addObserver:kvoObserver forKeyPath:kvoKeypath options:0 context:NULL];

    // When
    NSString *newClientID = @"22222";
    user.clientID = newClientID;

    // Then
    OCMVerify([kvoObserver observeValueForKeyPath:kvoKeypath
                                         ofObject:[OCMArg checkWithBlock:^BOOL(id obj) {
        XCTAssert([user.clientID isEqualToString:newClientID]);
        return true;
    }]
                                           change:[OCMArg any]
                                          context:NULL]);

    [kvoObserver removeObserver:kvoObserver forKeyPath:kvoKeypath];
    OCMVerify([kvoObserver removeObserver:kvoObserver forKeyPath:kvoKeypath]);
    [kvoObserver stopMocking];
}

- (void)testKVONotificationFiresWhenClientIDChangesFromValueToNil {
    // Given
    NSString *kvoKeypath = NSStringFromSelector(@selector(clientID));
    SystemUser *user = [[SystemUser alloc] initPrivate];
    user.clientID = @"11111";

    id kvoObserver = OCMClassMock([TestKVOObserverClass class]);
    [user addObserver:kvoObserver forKeyPath:kvoKeypath options:0 context:NULL];

    // When
    NSString *newClientID = nil;
    user.clientID = newClientID;

    // Then
    OCMVerify([kvoObserver observeValueForKeyPath:kvoKeypath
                                         ofObject:[OCMArg checkWithBlock:^BOOL(id obj) {
        XCTAssertNil(user.clientID, @"Client ID should have been set to nil");
        return true;
    }]
                                           change:[OCMArg any]
                                          context:NULL]);

    [kvoObserver removeObserver:kvoObserver forKeyPath:kvoKeypath];
    OCMVerify([kvoObserver removeObserver:kvoObserver forKeyPath:kvoKeypath]);
    [kvoObserver stopMocking];
}

- (void)testKVONotificationDoesNotFire {
    // Given
    NSString *kvoKeypath = NSStringFromSelector(@selector(clientID));
    SystemUser *user = [[SystemUser alloc] initPrivate];
    NSString *oldClientID = @"11111";
    user.clientID = oldClientID;

    id kvoObserver = OCMStrictClassMock([TestKVOObserverClass class]);
    [user addObserver:kvoObserver forKeyPath:kvoKeypath options:0 context:NULL];

    // When
    NSString *newClientID = oldClientID;
    user.clientID = newClientID;

    // Then
    // The "Then" part of the test is to see that a certain call does NOT happen.
    // This can be done with a strict class mock. When a method is envoked on a
    // strict mock which is not explicitly "Expected" or "Stubbed" the test
    // will fail.
    OCMVerifyAll(kvoObserver);

    OCMExpect([kvoObserver removeObserver:kvoObserver forKeyPath:kvoKeypath]);
    [kvoObserver removeObserver:kvoObserver forKeyPath:kvoKeypath];
    OCMVerifyAll(kvoObserver);
    [kvoObserver stopMocking];
}

- (void)testKVONotificationDoesNotFireNilCase {
    // Given
    NSString *kvoKeypath = NSStringFromSelector(@selector(clientID));
    SystemUser *user = [[SystemUser alloc] initPrivate];
    NSString *oldClientID = nil;
    user.clientID = oldClientID;

    id kvoObserver = OCMStrictClassMock([TestKVOObserverClass class]);
    [user addObserver:kvoObserver forKeyPath:kvoKeypath options:0 context:NULL];

    // When
    NSString *newClientID = oldClientID;
    user.clientID = newClientID;

    // Then
    // The "Then" part of the test is to see that a certain call does NOT happen.
    // This can be done with a strict class mock. When a method is envoked on a
    // strict mock which is not explicitly "Expected" or "Stubbed" the test
    // will fail.
    OCMVerifyAll(kvoObserver);

    OCMExpect([kvoObserver removeObserver:kvoObserver forKeyPath:kvoKeypath]);
    [kvoObserver removeObserver:kvoObserver forKeyPath:kvoKeypath];
    OCMVerifyAll(kvoObserver);
    [kvoObserver stopMocking];
}

- (void)testGetPasswordNoUsernameSetReturnsNil {
    self.user.username = nil;

    XCTAssertNil(self.user.password, @"Password should have been Nil");
}

- (void)testGetPasswordReturnsCorrectPassword {
    NSString *mockUsername = @"mockUsername";
    NSString *mockPassword = @"mockPassword";
    self.user.username = mockUsername;
    OCMStub([self.keychainMock passwordForService:[OCMArg any] account:mockUsername]).andReturn(mockPassword);

    XCTAssert([self.user.password isEqualToString:mockPassword], @"Passwords should have been equal");
    OCMVerifyAll(self.keychainMock);
}

- (void)testStoreNewAvailability {
    // Given
    NSDictionary *option = @{
                             SystemUserAvailabilityPhoneNumberKey: @42,
                             SystemUserAvailabilityDescriptionKey: @"Test phonennumber"
                             };

    // When
    NSString *newAvailabilityString = [self.user storeNewAvailabilityInSUD:option];

    // Then
    NSString *expectedString = [NSString stringWithFormat:@"%@ / %@", option[SystemUserAvailabilityPhoneNumberKey], option[SystemUserAvailabilityDescriptionKey]];
    XCTAssertEqualObjects(newAvailabilityString, expectedString, @"Expected and retrieved availability states mismatch");
}

- (void)testStoreNewAvailabilityNotAvailable {
    // Given
    NSDictionary *option = @{
                             SystemUserAvailabilityPhoneNumberKey: @0,
                             };

    // When
    NSString *newAvailabilityString = [self.user storeNewAvailabilityInSUD:option];

    // Then
    NSString *expectedString = NSLocalizedString(@"Not available", nil);
    XCTAssertEqualObjects(newAvailabilityString, expectedString, @"Expected and retrieved availability states mismatch");
}

@end
