//  LogInViewControllerTests.m
//  Copyright © 2015 VoIPGRID. All rights reserved.
//

#import "LogInViewController.h"
#import <OCMock/OCMock.h>
#import "PBWebViewController.h"
#import "SettingsViewController.h"
#import "SystemUser.h"
#import "VoIPGRIDRequestOperationManager+ForgotPassword.h"
@import XCTest;

@interface LogInViewController()
@property (strong, nonatomic) VoIPGRIDRequestOperationManager *operationManager;
- (void)sendEmail:(NSString *)email;
@end

@interface LogInViewControllerTests : XCTestCase
@property (nonatomic) LogInViewController *loginViewController;
@property (nonatomic) id mockUser;
@end

@interface SystemUser()
@property (strong, nonatomic) NSString *sipAccount;
@end

@interface LogInViewController()
- (void)unlockIt;
@end

@implementation LogInViewControllerTests

- (void)setUp {
    [super setUp];
    self.loginViewController = [[LogInViewController alloc] initWithNibName:@"LogInViewController" bundle:[NSBundle mainBundle]];
    
    self.mockUser = OCMClassMock([SystemUser class]);
    self.loginViewController.currentUser = self.mockUser;
}

- (void)tearDown {
    self.loginViewController = nil;
    [self.mockUser stopMocking];
    self.mockUser = nil;
    [super tearDown];
}

- (void)testLoginViewControllerHasCurrentSystemUserAsDependency {
    XCTAssertNotNil(self.loginViewController.currentUser, @"There should be a systemuser");
}

- (void)testLoginActionWillAskCurrentUserToLogin {
    [self.loginViewController loadViewIfNeeded];
    
    NSString *testUsername = @"testUsername";
    NSString *testPassword = @"testPassword";
    
    self.loginViewController.loginFormView.usernameField.text = testUsername;
    self.loginViewController.loginFormView.passwordField.text = testPassword;
    
    OCMExpect([self.mockUser loginToCheckTwoFactorWithUserName:testUsername password:testPassword andToken:[OCMArg any] completion:[OCMArg any]]);
    
    [self.loginViewController loginButtonPushed:nil];
    OCMVerifyAll(self.mockUser);
}

- (void)testUnsuccessfulLoginActionWillKeepUsernameInFieldLogin {
    OCMStub([self.mockUser loginToCheckTwoFactorWithUserName:[OCMArg any] password:[OCMArg any] andToken:[OCMArg any] completion:[OCMArg checkWithBlock:^BOOL(void (^passedBlock)(BOOL loggedin, NSError *error)) {
        passedBlock(NO, nil);
        return YES;
    }]]);
    [self.loginViewController loadViewIfNeeded];
    self.loginViewController.loginFormView.usernameField.text = @"testUsername";
    self.loginViewController.loginFormView.passwordField.text = @"testPassword";
    
    [self.loginViewController loginButtonPushed:nil];
    
    XCTAssertTrue([self.loginViewController.loginFormView.usernameField.text isEqualToString:@"testUsername"], @"The username should stay in the field");
    XCTAssertTrue([self.loginViewController.loginFormView.passwordField.text isEqualToString:@""], @"The passwordfield should be empty");
}

- (void)testThatConfigurationOpenActionOpensTheCorrectView {
    id loginViewControllerMock = OCMPartialMock(self.loginViewController);
    
    [loginViewControllerMock openConfigurationInstructions:nil];
    OCMVerify([loginViewControllerMock presentViewController:[OCMArg checkWithBlock:^BOOL(id obj) {
        XCTAssertTrue([obj isKindOfClass:[UINavigationController class]], @"There should be a navigationcontroller.");
        UINavigationController *navController = (UINavigationController *)obj;
        XCTAssertEqual(navController.viewControllers.count, 1, @"there should be one controller");
        XCTAssertTrue([navController.viewControllers[0] isKindOfClass:[PBWebViewController class]], @"There should be a webview visible");
        PBWebViewController *webViewController = (PBWebViewController *)navController.viewControllers[0];
        XCTAssertFalse(webViewController.showsNavigationToolbar, @"There should be no navigationbar visible");
        return YES;
    }] animated:YES completion:[OCMArg any]]);
    [loginViewControllerMock stopMocking];
}

- (void)testForgotPasswordViewHasUsernamePrefilledWhenUsernameIsFilled {
    [self.loginViewController loadViewIfNeeded];
    self.loginViewController.loginFormView.usernameField.text = @"testUsername";
    
    [self.loginViewController openForgotPassword:nil];
    
    XCTAssertTrue([self.loginViewController.forgotPasswordView.emailTextfield.text isEqualToString:@"testUsername"], @"the username should have been transferred");
}

- (void)testForgotPasswordViewHasUsernamePrefilledWhenSystemUsernameHasDefaultUsername {
    OCMStub([self.mockUser username]).andReturn(@"presetUser");
    
    [self.loginViewController loadViewIfNeeded];
    
    [self.loginViewController openForgotPassword:nil];
    
    XCTAssertTrue([self.loginViewController.forgotPasswordView.emailTextfield.text isEqualToString:@"presetUser"], @"the username should have been transferred");
}

- (void)testForgotPasswordViewHasActiveButtonWhenEmailAddressIsPrefilled {
    [self.loginViewController loadViewIfNeeded];
    self.loginViewController.loginFormView.usernameField.text = @"testUsername@test.com";
    [self.loginViewController viewDidAppear:NO];
    
    [self.loginViewController openForgotPassword:nil];
    
    XCTAssertTrue(self.loginViewController.forgotPasswordView.requestPasswordButton.enabled, @"The requestButton should be enabled when a emailadres is prefilled.");
}

- (void)testForgotPasswordViewHasInActiveButtonWhenNoEmailAddressIsPrefilled {
    [self.loginViewController loadViewIfNeeded];
    self.loginViewController.loginFormView.usernameField.text = @"testUsername";
    [self.loginViewController viewDidAppear:NO];
    
    [self.loginViewController openForgotPassword:nil];
    
    XCTAssertFalse(self.loginViewController.forgotPasswordView.requestPasswordButton.enabled, @"The requestButton should be enabled when a emailadres is prefilled.");
}

- (void)testForgotPasswordViewHasInActiveButtonWhenNoUsernameIsFilled {
    [self.loginViewController loadViewIfNeeded];
    [self.loginViewController viewDidAppear:NO];
    
    [self.loginViewController openForgotPassword:nil];
    
    XCTAssertFalse(self.loginViewController.forgotPasswordView.requestPasswordButton.enabled, @"The requestButton should be disabled when no emailadress is filled.");
}

- (void)testForgotPasswordButtonIsPressedAnAlertIsShown {
    id mockLoginVC = OCMPartialMock(self.loginViewController);
    
    [self.loginViewController requestPasswordButtonPressed:nil];
    
    OCMVerify([mockLoginVC presentViewController:[OCMArg isKindOfClass:[UIAlertController class]] animated:YES completion:nil]);
    [mockLoginVC stopMocking];
}

- (void)testLoginForgetAlertOkActionWillAskUserToSentEmail {
    id mockOperationsManager = OCMClassMock([VoIPGRIDRequestOperationManager class]);
    self.loginViewController.operationManager = mockOperationsManager;
    [self.loginViewController sendEmail:@"test@test.com"];
    
    OCMVerify([mockOperationsManager passwordResetWithEmail:[OCMArg isEqual:@"test@test.com"] withCompletion:[OCMArg any]]);
    [mockOperationsManager stopMocking];
}

- (void)testSIPAllowedNoSIPAccountSegueToActiveSIPAccount {
    OCMStub([self.mockUser sipAccount]).andReturn(nil);
    
    id loginViewControllerMock = OCMPartialMock(self.loginViewController);
    [loginViewControllerMock unlockIt];
    OCMVerify([loginViewControllerMock presentViewController:[OCMArg checkWithBlock:^BOOL(id obj) {
        XCTAssertTrue([obj isKindOfClass:[UINavigationController class]], @"There should be a navigationcontroller.");
        UINavigationController *navController = (UINavigationController *)obj;
        XCTAssertEqual(navController.viewControllers.count, 1, @"there should be one controller");
        XCTAssertTrue([navController.viewControllers[0] isKindOfClass:[SettingsViewController class]], @"There should be the settings view controller visible");
        return YES;
    }] animated:NO completion:nil]);
    
    [loginViewControllerMock stopMocking];
}

- (void)testLoginForgetAlertOkActionWillShowLoginForm {
    [self.loginViewController loadViewIfNeeded];
    id mockOperationsManager = OCMClassMock([VoIPGRIDRequestOperationManager class]);
    XCTestExpectation *expectation = [self expectationWithDescription:@"Should show the login form."];
    OCMStub([mockOperationsManager passwordResetWithEmail:[OCMArg any] withCompletion:[OCMArg checkWithBlock:^BOOL(void (^passedBlock)(     *operation, NSDictionary *responseData, NSError *error)) {
        passedBlock(nil, nil, nil);
        [expectation fulfill];
        return YES;
    }]]);
    
    self.loginViewController.operationManager = mockOperationsManager;
    
    [self.loginViewController sendEmail:@"test@test.com"];
    
    [self waitForExpectationsWithTimeout:5.0 handler:^(NSError * _Nullable error) {
        XCTAssertNotNil(self.loginViewController.loginFormView, @"there should be a form");
        XCTAssertEqual(self.loginViewController.loginFormView.alpha, 1.0f);
        XCTAssertEqual(self.loginViewController.forgotPasswordView.alpha, 0.0f);
        
        [mockOperationsManager stopMocking];
    }];
}

@end
