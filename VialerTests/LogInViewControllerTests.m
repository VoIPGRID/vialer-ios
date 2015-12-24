//
//  LogInViewControllerTests.m
//  Copyright © 2015 VoIPGRID. All rights reserved.
//

#import "LogInViewController.h"

#import <XCTest/XCTest.h>

#import <OCMock/OCMock.h>
#import "PBWebViewController.h"

@interface LogInViewControllerTests : XCTestCase
@property (nonatomic) LogInViewController *loginViewController;
@end

@implementation LogInViewControllerTests

- (void)setUp {
    [super setUp];
    self.loginViewController = [[LogInViewController alloc] init];
}

- (void)tearDown {
    self.loginViewController = nil;
    [super tearDown];
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
    }] animated:[OCMArg any] completion:[OCMArg any]]);
}

@end
