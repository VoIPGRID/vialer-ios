//
//  LogInViewControllerTests.m
//  Copyright © 2015 VoIPGRID. All rights reserved.
//

#import "LogInViewController.h"
#import "SystemUser.h"

#import <XCTest/XCTest.h>

#import <OCMock/OCMock.h>
#import "PBWebViewController.h"

@interface LogInViewControllerTests : XCTestCase
@property (nonatomic) LogInViewController *loginViewController;
@property (nonatomic) id mockUser;
@end

@implementation LogInViewControllerTests

- (void)setUp {
    [super setUp];
    self.loginViewController = [[LogInViewController alloc] initWithNibName:@"LogInViewController" bundle:[NSBundle mainBundle]];

    self.mockUser = OCMClassMock([SystemUser class]);
    self.loginViewController.currentUser = self.mockUser;
}

- (void)tearDown {
    [self.mockUser stopMocking];
    [super tearDown];
}

- (void)testLoginViewControllerHasCurrentSystemUserAsDependency {
    XCTAssertNotNil(self.loginViewController.currentUser, @"There should be a systemuser");
}

- (void)testLoginActionWillAskCurrentUserToLogin {
    [self.loginViewController loadViewIfNeeded];
    self.loginViewController.loginFormView.usernameField.text = @"testUsername";
    self.loginViewController.loginFormView.passwordField.text = @"testPassword";

    [self.loginViewController loginButtonPushed:nil];

    OCMVerify([self.mockUser loginWithUsername:[OCMArg isEqual:@"testUsername"] password:[OCMArg isEqual:@"testPassword"] completion:[OCMArg any]]);
}

- (void)testUnsuccessfulLoginActionWillKeepUsernameInFieldLogin {
    OCMStub([self.mockUser loginWithUsername:[OCMArg any] password:[OCMArg any] completion:[OCMArg checkWithBlock:^BOOL(void (^passedBlock)(BOOL loggedin, NSError *error)) {
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

@end
