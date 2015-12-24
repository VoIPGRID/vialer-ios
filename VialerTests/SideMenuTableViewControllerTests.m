//
//  SideMenuTableViewControllerTests.m
//  Copyright © 2015 VoIPGRID. All rights reserved.
//

#import "SideMenuTableViewController.h"
#import "VialerWebViewController.h"

#import <XCTest/XCTest.h>

@interface SideMenuTableViewControllerTests : XCTestCase
@property (nonatomic) SideMenuTableViewController *sideMenuTableViewController;
@end

@implementation SideMenuTableViewControllerTests

- (void)setUp {
    [super setUp];
    self.sideMenuTableViewController = [[UIStoryboard storyboardWithName:@"SideMenuStoryboard" bundle:nil] instantiateViewControllerWithIdentifier:@"SideMenuTableViewController"];
}

- (void)tearDown {
    self.sideMenuTableViewController = nil;
    [super tearDown];
}

- (void)testWebViewControllerForInformationSequeWillBePreparedWithoutNavigationToolbar {
    UINavigationController *navVC = [[UIStoryboard storyboardWithName:@"SideMenuStoryboard" bundle:nil] instantiateViewControllerWithIdentifier:@"WebviewNavigationController"];
    UIStoryboardSegue *segue = [UIStoryboardSegue segueWithIdentifier:SideMenuTableViewControllerShowInformationSegue source:self.sideMenuTableViewController destination:navVC performHandler:^{}];
    [self.sideMenuTableViewController prepareForSegue:segue sender:self];

    VialerWebViewController *webviewController = (VialerWebViewController *)navVC.viewControllers[0];
    XCTAssertFalse(webviewController.showsNavigationToolbar, @"Navigation toolbar should not be shown for this view.");
}

- (void)testWebViewControllerForDialplanSequeWillBePreparedWithNavigationToolbar {
    UINavigationController *navVC = [[UIStoryboard storyboardWithName:@"SideMenuStoryboard" bundle:nil] instantiateViewControllerWithIdentifier:@"WebviewNavigationController"];
    UIStoryboardSegue *segue = [UIStoryboardSegue segueWithIdentifier:SideMenuTableViewControllerShowDialPlanSegue source:self.sideMenuTableViewController destination:navVC performHandler:^{}];
    [self.sideMenuTableViewController prepareForSegue:segue sender:self];

    VialerWebViewController *webviewController = (VialerWebViewController *)navVC.viewControllers[0];
    XCTAssertTrue(webviewController.showsNavigationToolbar, @"Navigation toolbar should not be shown for this view.");
}

- (void)testWebViewControllerForStatisticsSequeWillBePreparedWithNavigationToolbar {
    UINavigationController *navVC = [[UIStoryboard storyboardWithName:@"SideMenuStoryboard" bundle:nil] instantiateViewControllerWithIdentifier:@"WebviewNavigationController"];
    UIStoryboardSegue *segue = [UIStoryboardSegue segueWithIdentifier:SideMenuTableViewControllerShowStatisticsSegue source:self.sideMenuTableViewController destination:navVC performHandler:^{}];
    [self.sideMenuTableViewController prepareForSegue:segue sender:self];

    VialerWebViewController *webviewController = (VialerWebViewController *)navVC.viewControllers[0];
    XCTAssertTrue(webviewController.showsNavigationToolbar, @"Navigation toolbar should not be shown for this view.");
}

- (void)testWebViewControllerHasABackButtonInNavigationBar {
    UINavigationController *navVC = [[UIStoryboard storyboardWithName:@"SideMenuStoryboard" bundle:nil] instantiateViewControllerWithIdentifier:@"WebviewNavigationController"];
    VialerWebViewController *webviewController = (VialerWebViewController *)navVC.viewControllers[0];
    XCTAssertTrue([webviewController.navigationItem.leftBarButtonItem.title isEqualToString:NSLocalizedString(@"Back", nil)], @"There should be a back bar button item.");
}
@end
