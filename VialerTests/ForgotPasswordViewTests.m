//
//  ForgotPasswordViewTests.m
//  Copyright © 2015 VoIPGRID. All rights reserved.
//

#import "Vialer-Swift.h"
#import "ForgotPasswordView.h"
#import "LogInViewController.h"
#import <OCMock/OCMock.h>
@import XCTest;

@interface ForgotPasswordViewTests : XCTestCase
@property (nonatomic) LogInViewController *loginViewController;
@property (nonatomic) ForgotPasswordView *forgotPasswordView;
@end

@implementation ForgotPasswordViewTests

- (void)setUp {
    [super setUp];
    
    self.loginViewController = [[LogInViewController alloc] initWithNibName:@"LogInViewController" bundle:nil];
    [self.loginViewController loadViewIfNeeded];
    self.forgotPasswordView = self.loginViewController.forgotPasswordView;
}

- (void)tearDown {
    self.forgotPasswordView = nil;
    self.loginViewController = nil;

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
    OCMStub([self.forgotPasswordView.requestPasswordButton setHighlighted:YES]);
    XCTAssert([self.forgotPasswordView.requestPasswordButton.backgroundColorForPressedState isEqual:self.forgotPasswordView.requestPasswordButton.backgroundColor], @"ContinueButton should have gotten the color given from the custom method setHighlighted.");
    XCTAssertTrue(self.forgotPasswordView.requestPasswordButton.borderWidth > 0, @"button needs a border");
    XCTAssertTrue(self.forgotPasswordView.requestPasswordButton.cornerRadius > 0, @"button needs rounded corners");
}

@end
