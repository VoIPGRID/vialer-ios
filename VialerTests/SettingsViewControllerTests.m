//
//  SettingsViewControllerTests.m
//  Copyright © 2015 VoIPGRID. All rights reserved.
//

#import "SettingsViewController.h"

#import <XCTest/XCTest.h>

@interface SettingsViewControllerTests : XCTestCase
@property (nonatomic) SettingsViewController *settingsViewController;
@end

@implementation SettingsViewControllerTests

- (void)setUp {
    [super setUp];
    self.settingsViewController = [[UIStoryboard storyboardWithName:@"SettingsStoryboard" bundle:nil] instantiateViewControllerWithIdentifier:@"SettingsViewController"];
}

- (void)tearDown {
    self.settingsViewController = nil;
    [super tearDown];
}

- (void)testSettingsViewControllerHasBackButton {
    XCTAssertTrue([self.settingsViewController.navigationItem.leftBarButtonItem.title isEqualToString:NSLocalizedString(@"Back", nil)], @"There should be a back button in the navigationbar.");
}
@end
