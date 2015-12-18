//
//  ForgotPasswordViewTests.m
//  Vialer
//
//  Created by Bob Voorneveld on 19/12/15.
//  Copyright © 2015 VoIPGRID. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>
#import "Configuration.h"
#import "ForgotPasswordView.h"
#import "LogInViewController.h"

@interface ForgotPasswordViewTests : XCTestCase
@property (nonatomic) LogInViewController *loginViewController;
@property (nonatomic) ForgotPasswordView *forgotPasswordView;
@property (nonatomic) id configurationMock;
@property (nonatomic) UIColor *color;
@end

@implementation ForgotPasswordViewTests

- (void)setUp {
    [super setUp];
    self.configurationMock = OCMClassMock([Configuration class]);
    self.color = [UIColor redColor];
    OCMStub([self.configurationMock tintColorForKey:[OCMArg any]]).andReturn(self.color);
    OCMStub([self.configurationMock defaultConfiguration]).andReturn(self.configurationMock);
    self.loginViewController = [[LogInViewController alloc] initWithNibName:@"LogInViewController" bundle:nil];
    [self.loginViewController loadViewIfNeeded];
    self.forgotPasswordView = self.loginViewController.forgotPasswordView;
}

- (void)tearDown {
    self.forgotPasswordView = nil;
    self.loginViewController = nil;
    self.color = nil;
    self.configurationMock = nil;
    [super tearDown];
}

- (void)testForgotPasswordViewExists {
    XCTAssertNotNil(self.forgotPasswordView, @"There should be a login form view.");
}

- (void)testRequestPasswordButtonExists {
    XCTAssertNotNil(self.forgotPasswordView.requestPasswordButton, @"There should be a requestPasswordButton");
}

- (void)testRequestPasswordButtonHasRoundedBorder {
    XCTAssertTrue(self.forgotPasswordView.requestPasswordButton.borderWidth > 0, @"button needs a border");
    XCTAssertTrue(self.forgotPasswordView.requestPasswordButton.cornerRadius > 0, @"button needs rounded corners");
}

- (void)testRequestPasswordButtonHasCorrectBackGroundColorForPressedState {
    XCTAssertEqual(self.forgotPasswordView.requestPasswordButton.backgroundColorForPressedState, self.color, @"requestPasswordButton should have gotten the color from config.");
    XCTAssertTrue(self.forgotPasswordView.requestPasswordButton.borderWidth > 0, @"button needs a border");
    XCTAssertTrue(self.forgotPasswordView.requestPasswordButton.cornerRadius > 0, @"button needs rounded corners");
}

@end
