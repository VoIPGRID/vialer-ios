//
//  LoginFormViewTests.m
//  Copyright © 2015 VoIPGRID. All rights reserved.
//

#import "LoginFormView.h"
#import "LogInViewController.h"
#import <OCMock/OCMock.h>
@import XCTest;

@interface LoginFormViewTests : XCTestCase
@property (nonatomic) LogInViewController *loginViewController;
@property (nonatomic) LoginFormView *loginFormView;
@end

@implementation LoginFormViewTests

- (void)setUp {
    [super setUp];

    self.loginViewController = [[LogInViewController alloc] initWithNibName:@"LogInViewController" bundle:nil];
    [self.loginViewController loadViewIfNeeded];
    self.loginFormView = self.loginViewController.loginFormView;
}

- (void)tearDown {
    self.loginFormView = nil;
    self.loginViewController = nil;

    [super tearDown];
}

- (void)testLoginFormViewExists {
    XCTAssertNotNil(self.loginFormView, @"There should be a login form view.");
}

- (void)testLoginButtonExists {
    XCTAssertNotNil(self.loginFormView.loginButton, @"There should be a loginButton");
}

- (void)testLoginButtonHasRoundedBorder {
    XCTAssertTrue(self.loginFormView.loginButton.borderWidth > 0, @"button needs a border");
    XCTAssertTrue(self.loginFormView.loginButton.cornerRadius > 0, @"button needs rounded corners");
}

- (void)testLoginButtonHasCorrectBackgroundColorForPressedState {
    OCMStub([self.loginViewController.loginFormView.loginButton setHighlighted:YES]);
    XCTAssert([self.loginFormView.loginButton.backgroundColorForPressedState isEqual:self.loginFormView.loginButton.backgroundColor], @"LoginButton should have gotten the color given from the custom method setHighlighted.");
    XCTAssertTrue(self.loginFormView.loginButton.borderWidth > 0, @"button needs a border");
    XCTAssertTrue(self.loginFormView.loginButton.cornerRadius > 0, @"button needs rounded corners");
}

- (void)testForgotPasswordButtonExists {
    XCTAssertNotNil(self.loginFormView.forgotPasswordButton, @"There should be a forgotPasswordButton");
}

- (void)testForgotPasswordButtonHasRoundedBorder {
    XCTAssertTrue(self.loginFormView.forgotPasswordButton.borderWidth > 0, @"button needs a border");
    XCTAssertTrue(self.loginFormView.forgotPasswordButton.cornerRadius > 0, @"button needs rounded corners");
}

- (void)testForgotPasswordButtonHasCorrectBackgroundColorForPressedState {
    OCMStub([self.loginFormView.forgotPasswordButton setHighlighted:YES]);
    XCTAssert([self.loginFormView.forgotPasswordButton.backgroundColorForPressedState isEqual:self.loginFormView.forgotPasswordButton.backgroundColor], @"LoginButton should have gotten the color given from the custom method setHighlighted.");
    XCTAssertTrue(self.loginFormView.forgotPasswordButton.borderWidth > 0, @"button needs a border");
    XCTAssertTrue(self.loginFormView.forgotPasswordButton.cornerRadius > 0, @"button needs rounded corners");
}

- (void)testConfigurationInstructionsButtonExists {
    XCTAssertNotNil(self.loginFormView.configurationInstructionsButton, @"There should be a configurationInstructionsButton");
}

- (void)testConfigurationInstructionsButtonHasRoundedBorder {
    XCTAssertTrue(self.loginFormView.configurationInstructionsButton.borderWidth > 0, @"button needs a border");
    XCTAssertTrue(self.loginFormView.configurationInstructionsButton.cornerRadius > 0, @"button needs rounded corners");
}

- (void)testConfigurationInstructionsButtonHasCorrectBackgroundColorForPressedState {
    OCMStub([self.loginFormView.configurationInstructionsButton setHighlighted:YES]);
    XCTAssert([self.loginFormView.configurationInstructionsButton.backgroundColorForPressedState isEqual:self.loginFormView.configurationInstructionsButton.backgroundColor], @"ConfigurationInstructionsButton should have gotten the color given from the custom method setHighlighted.");
    XCTAssertTrue(self.loginFormView.configurationInstructionsButton.borderWidth > 0, @"button needs a border");
    XCTAssertTrue(self.loginFormView.configurationInstructionsButton.cornerRadius > 0, @"button needs rounded corners");
}

@end
