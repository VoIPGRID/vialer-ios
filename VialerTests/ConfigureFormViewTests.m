//
//  ConfigureFormViewTests.m
//  Copyright © 2015 VoIPGRID. All rights reserved.
//

#import "Vialer-Swift.h"
#import "ConfigureFormView.h"
#import "LogInViewController.h"
#import <OCMock/OCMock.h>
@import XCTest;

@interface ConfigureFormViewTests : XCTestCase
@property (nonatomic) LogInViewController *loginViewController;
@property (nonatomic) ConfigureFormView *configurationFormView;
@end

@implementation ConfigureFormViewTests

- (void)setUp {
    [super setUp];
    
    self.loginViewController = [[LogInViewController alloc] initWithNibName:@"LogInViewController" bundle:nil];
    [self.loginViewController loadViewIfNeeded];
    self.configurationFormView = self.loginViewController.configureFormView;
}

- (void)tearDown {
    self.configurationFormView = nil;
    self.loginViewController = nil;
    
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
    OCMStub([self.configurationFormView.continueButton setHighlighted:YES]);
    XCTAssert([self.configurationFormView.continueButton.backgroundColorForPressedState isEqual:self.configurationFormView.continueButton.backgroundColor], @"ContinueButton should have gotten the color given from the custom method setHighlighted.");
    XCTAssertTrue(self.configurationFormView.continueButton.borderWidth > 0, @"button needs a border");
    XCTAssertTrue(self.configurationFormView.continueButton.cornerRadius > 0, @"button needs rounded corners");
}

@end
