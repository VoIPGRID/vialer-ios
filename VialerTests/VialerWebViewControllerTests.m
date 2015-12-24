//
//  VialerWebViewControllerTests.m
//  Copyright © 2015 VoIPGRID. All rights reserved.
//

#import "VialerWebViewController.h"

#import <XCTest/XCTest.h>

@interface VialerWebViewControllerTests : XCTestCase
@property (nonatomic) VialerWebViewController *webViewController;
@end

@implementation VialerWebViewControllerTests

- (void)setUp {
    [super setUp];
    self.webViewController = [[VialerWebViewController alloc] init];
}

- (void)tearDown {
    self.webViewController = nil;
    [super tearDown];
}

- (void)testWebViewControllerHasADefaultConfigurationAsDependency {
    XCTAssertEqualObjects(self.webViewController.configuration, [Configuration defaultConfiguration], @"The webview should have the default configuration as a dependency.");
}

- (void)testWebViewControllerDoesHaveABottomNavigationBarOnDefault {
    XCTAssertTrue(self.webViewController.showsNavigationToolbar, @"There should be a navigation bar shown on default.");
}

@end
