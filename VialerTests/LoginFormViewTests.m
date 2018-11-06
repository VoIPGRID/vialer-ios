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
@property (nonatomic) id configurationMock;
@property (nonatomic) UIColor *color;
@end

@implementation LoginFormViewTests

- (void)setUp {
    [super setUp];
    self.color = [UIColor redColor];

    self.loginViewController = [[LogInViewController alloc] initWithNibName:@"LogInViewController" bundle:nil];
    [self.loginViewController loadViewIfNeeded];
    self.loginFormView = self.loginViewController.loginFormView;
}

- (void)tearDown {
    self.loginFormView = nil;
    self.loginViewController = nil;
    self.color = nil;

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

- (void)testLoginButtonHasCorrectBackGroundColorForPressedState {
    XCTAssertEqual(self.loginFormView.loginButton.backgroundColorForPressedState, self.color, @"Loginbutton should have gotten the color from config.");
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

- (void)testForgotPasswordButtonHasCorrectBackGroundColorForPressedState {
    XCTAssertEqual(self.loginFormView.forgotPasswordButton.backgroundColorForPressedState, self.color, @"forgotPasswordButton should have gotten the color from config.");
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

- (void)testConfigurationInstructionsButtonHasCorrectBackGroundColorForPressedState {
    XCTAssertEqual(self.loginFormView.configurationInstructionsButton.backgroundColorForPressedState, self.color, @"configurationInstructionsButton should have gotten the color from config.");
    XCTAssertTrue(self.loginFormView.configurationInstructionsButton.borderWidth > 0, @"button needs a border");
    XCTAssertTrue(self.loginFormView.configurationInstructionsButton.cornerRadius > 0, @"button needs rounded corners");
}

@end
