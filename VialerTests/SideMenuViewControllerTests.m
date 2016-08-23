//
//  SideMenuViewControllerTests.m
//  Copyright © 2015 VoIPGRID. All rights reserved.
//

#import "SideMenuViewController.h"
#import "VialerWebViewController.h"
@import XCTest;

@interface SideMenuViewControllerTests : XCTestCase
@property (nonatomic) SideMenuViewController *sideMenuViewController;
@end

@implementation SideMenuViewControllerTests

- (void)setUp {
    [super setUp];
    self.sideMenuViewController = [[UIStoryboard storyboardWithName:@"SideMenuStoryboard" bundle:nil] instantiateInitialViewController];
}

- (void)tearDown {
    self.sideMenuViewController = nil;
    [super tearDown];
}

- (void)testWebViewControllerForInformationSegueWillBePreparedWithoutNavigationToolbar {
    UINavigationController *navVC = [[UIStoryboard storyboardWithName:@"SideMenuStoryboard" bundle:nil] instantiateViewControllerWithIdentifier:@"WebviewNavigationController"];
    UIStoryboardSegue *segue = [UIStoryboardSegue segueWithIdentifier:SideMenuViewControllerShowInformationSegue source:self.sideMenuViewController destination:navVC performHandler:^{}];
    [self.sideMenuViewController prepareForSegue:segue sender:self];

    VialerWebViewController *webviewController = (VialerWebViewController *)navVC.viewControllers[0];
    XCTAssertFalse(webviewController.showsNavigationToolbar, @"Navigation toolbar should not be shown for this view.");
}

- (void)testWebViewControllerForDialplanSegueWillBePreparedWithNavigationToolbar {
    UINavigationController *navVC = [[UIStoryboard storyboardWithName:@"SideMenuStoryboard" bundle:nil] instantiateViewControllerWithIdentifier:@"WebviewNavigationController"];
    UIStoryboardSegue *segue = [UIStoryboardSegue segueWithIdentifier:SideMenuViewControllerShowDialPlanSegue source:self.sideMenuViewController destination:navVC performHandler:^{}];
    [self.sideMenuViewController prepareForSegue:segue sender:self];

    VialerWebViewController *webviewController = (VialerWebViewController *)navVC.viewControllers[0];
    XCTAssertTrue(webviewController.showsNavigationToolbar, @"Navigation toolbar should not be shown for this view.");
}

- (void)testWebViewControllerForStatisticsSegueWillBePreparedWithNavigationToolbar {
    UINavigationController *navVC = [[UIStoryboard storyboardWithName:@"SideMenuStoryboard" bundle:nil] instantiateViewControllerWithIdentifier:@"WebviewNavigationController"];
    UIStoryboardSegue *segue = [UIStoryboardSegue segueWithIdentifier:SideMenuViewControllerShowStatisticsSegue source:self.sideMenuViewController destination:navVC performHandler:^{}];
    [self.sideMenuViewController prepareForSegue:segue sender:self];

    VialerWebViewController *webviewController = (VialerWebViewController *)navVC.viewControllers[0];
    XCTAssertTrue(webviewController.showsNavigationToolbar, @"Navigation toolbar should not be shown for this view.");
}

- (void)testWebViewControllerHasABackButtonInNavigationBar {
    UINavigationController *navVC = [[UIStoryboard storyboardWithName:@"SideMenuStoryboard" bundle:nil] instantiateViewControllerWithIdentifier:@"WebviewNavigationController"];
    VialerWebViewController *webviewController = (VialerWebViewController *)navVC.viewControllers[0];
    XCTAssertTrue([webviewController.navigationItem.leftBarButtonItem.title isEqualToString:NSLocalizedString(@"Back", nil)], @"There should be a back bar button item.");
}
@end
