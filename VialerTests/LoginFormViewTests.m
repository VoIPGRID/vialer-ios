//
//  LoginFormViewTests.m
//  Vialer
//
//  Created by Bob Voorneveld on 19/12/15.
//  Copyright © 2015 VoIPGRID. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>
#import "Configuration.h"
#import "LoginFormView.h"
#import "LogInViewController.h"

@interface LoginFormViewTests : XCTestCase
@property (nonatomic) LogInViewController *loginViewController;
@property (nonatomic) LoginFormView *loginFormView;
@property (nonatomic) id configurationMock;
@property (nonatomic) UIColor *color;
@end

@implementation LoginFormViewTests

- (void)setUp {
    [super setUp];
    self.configurationMock = OCMClassMock([Configuration class]);
    self.color = [UIColor redColor];
    OCMStub([self.configurationMock tintColorForKey:[OCMArg any]]).andReturn(self.color);
    OCMStub([self.configurationMock defaultConfiguration]).andReturn(self.configurationMock);
    self.loginViewController = [[LogInViewController alloc] initWithNibName:@"LogInViewController" bundle:nil];
    [self.loginViewController loadViewIfNeeded];
    self.loginFormView = self.loginViewController.loginFormView;
}

- (void)tearDown {
    self.loginFormView = nil;
    self.loginViewController = nil;
    self.color = nil;

    [self.configurationMock stopMocking];
    self.configurationMock = nil;
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
