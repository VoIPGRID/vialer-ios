//
//  ConfigureFormViewTests.m
//  Copyright © 2015 VoIPGRID. All rights reserved.
//

#import "Configuration.h"
#import "ConfigureFormView.h"
#import "LogInViewController.h"
#import <OCMock/OCMock.h>
@import XCTest;

@interface ConfigureFormViewTests : XCTestCase
@property (nonatomic) LogInViewController *loginViewController;
@property (nonatomic) ConfigureFormView *configurationFormView;
@property (nonatomic) id configurationMock;
@property (nonatomic) UIColor *color;
@end

@implementation ConfigureFormViewTests

- (void)setUp {
    [super setUp];
    self.configurationMock = OCMClassMock([Configuration class]);
    self.color = [UIColor redColor];
    OCMStub([self.configurationMock tintColorForKey:[OCMArg any]]).andReturn(self.color);
    OCMStub([self.configurationMock defaultConfiguration]).andReturn(self.configurationMock);
    self.loginViewController = [[LogInViewController alloc] initWithNibName:@"LogInViewController" bundle:nil];
    [self.loginViewController loadViewIfNeeded];
    self.configurationFormView = self.loginViewController.configureFormView;
}

- (void)tearDown {
    self.configurationFormView = nil;
    self.loginViewController = nil;
    self.color = nil;

    [self.configurationMock stopMocking];
    self.configurationMock = nil;
    [super tearDown];
}

- (void)testConfigurationFormViewExists {
    XCTAssertNotNil(self.configurationFormView, @"There should be a configuration form view.");
}

- (void)testContinueButtonExists {
    XCTAssertNotNil(self.configurationFormView.continueButton, @"There should be a continueButton");
}

- (void)testContinueButtonHasRoundedBorder {
    XCTAssertTrue(self.configurationFormView.continueButton.borderWidth > 0, @"button needs a border");
    XCTAssertTrue(self.configurationFormView.continueButton.cornerRadius > 0, @"button needs rounded corners");
}

- (void)testContinueButtonHasCorrectBackGroundColorForPressedState {
    XCTAssertEqual(self.configurationFormView.continueButton.backgroundColorForPressedState, self.color, @"continueButton should have gotten the color from config.");
    XCTAssertTrue(self.configurationFormView.continueButton.borderWidth > 0, @"button needs a border");
    XCTAssertTrue(self.configurationFormView.continueButton.cornerRadius > 0, @"button needs rounded corners");
}

@end
