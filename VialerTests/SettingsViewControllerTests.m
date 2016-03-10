//
//  SettingsViewControllerTests.m
//  Copyright © 2015 VoIPGRID. All rights reserved.
//

#import "SettingsViewController.h"

#import <OCMock/OCMock.h>
#import "SVProgressHUD.h"
#import "SystemUser.h"
#import <XCTest/XCTest.h>

@interface SettingsViewController ()
@property (strong, nonatomic) SystemUser *currentUser;
@end

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

- (void)testChangeSwitchToOffWillSetSipEnabledToOff {
    id mockSystemUser = OCMClassMock([SystemUser class]);
    self.settingsViewController.currentUser = mockSystemUser;
    id mockSwitch = OCMClassMock([UISwitch class]);
    OCMStub([mockSwitch isOn]).andReturn(NO);
    OCMStub([mockSwitch tag]).andReturn(1001);

    [self.settingsViewController didChangeSwitch:mockSwitch];

    XCTestExpectation *expectation = [self expectationWithDescription:@"Should fetch diable sip"];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [expectation fulfill];
    });

    [self waitForExpectationsWithTimeout:0.2 handler:^(NSError * _Nullable error) {
        if (error) {
            NSLog(@"Error: %@", error);
        }
        OCMVerify([mockSystemUser setSipEnabled:NO]);
    }];
}

- (void)testChangeSwitchToOffWillReloadTable {
    id mockSystemUser = OCMClassMock([SystemUser class]);
    id mockTableView = OCMClassMock([UITableView class]);
    self.settingsViewController.currentUser = mockSystemUser;
    self.settingsViewController.tableView = mockTableView;
    id mockSwitch = OCMClassMock([UISwitch class]);
    OCMStub([mockSwitch isOn]).andReturn(NO);
    OCMStub([mockSwitch tag]).andReturn(1001);

    [self.settingsViewController didChangeSwitch:mockSwitch];

    XCTestExpectation *expectation = [self expectationWithDescription:@"Should fetch disable sip"];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [expectation fulfill];
    });

    [self waitForExpectationsWithTimeout:0.2 handler:^(NSError * _Nullable error) {
        if (error) {
            NSLog(@"Error: %@", error);
        }
        OCMVerify([mockTableView reloadSections:[OCMArg any] withRowAnimation:UITableViewRowAnimationAutomatic]);
    }];
}

- (void)testChangeSwitchToOffWillShowSpinner {
    id mockSystemUser = OCMClassMock([SystemUser class]);
    self.settingsViewController.currentUser = mockSystemUser;
    id mockSwitch = OCMClassMock([UISwitch class]);
    id progressMock = OCMClassMock([SVProgressHUD class]);
    OCMStub([mockSwitch isOn]).andReturn(NO);
    OCMStub([mockSwitch tag]).andReturn(1001);

    [self.settingsViewController didChangeSwitch:mockSwitch];

    XCTestExpectation *expectation = [self expectationWithDescription:@"Should fetch disable sip"];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [expectation fulfill];
    });

    [self waitForExpectationsWithTimeout:0.2 handler:^(NSError * _Nullable error) {
        if (error) {
            NSLog(@"Error: %@", error);
        }
        OCMVerify([progressMock showWithStatus:[OCMArg any] maskType:SVProgressHUDMaskTypeGradient]);
    }];

    [progressMock stopMocking];
}
- (void)testChangeSwitchToOnWillAskUserToGetSipAccount {
    id mockSystemUser = OCMClassMock([SystemUser class]);
    self.settingsViewController.currentUser = mockSystemUser;
    id mockSwitch = OCMClassMock([UISwitch class]);
    OCMStub([mockSwitch isOn]).andReturn(YES);
    OCMStub([mockSwitch tag]).andReturn(1001);

    [self.settingsViewController didChangeSwitch:mockSwitch];

    OCMVerify([mockSystemUser getAndActivateSIPAccountWithCompletion:[OCMArg any]]);
}

- (void)testSystemUserWillReturnErrorWhenFetchingSipAccount {
    id mockSystemUser = OCMClassMock([SystemUser class]);
    OCMStub([mockSystemUser getAndActivateSIPAccountWithCompletion:[OCMArg checkWithBlock:^BOOL(void (^passedBlock)(BOOL success, NSError *error)) {
        passedBlock(NO, [NSError errorWithDomain:@"testDomain" code:-1 userInfo:nil]);
        return YES;
    }]]);

    self.settingsViewController.currentUser = mockSystemUser;
    id mockSwitch = OCMClassMock([UISwitch class]);
    OCMStub([mockSwitch isOn]).andReturn(YES);
    OCMStub([mockSwitch tag]).andReturn(1001);

    [self.settingsViewController didChangeSwitch:mockSwitch];

    OCMVerify([mockSwitch setOn:NO]);
}

- (void)testSystemUserWillReturnNoSuccessWhenFetchingSipAccount {
    id mockSystemUser = OCMClassMock([SystemUser class]);
    OCMStub([mockSystemUser getAndActivateSIPAccountWithCompletion:[OCMArg checkWithBlock:^BOOL(void (^passedBlock)(BOOL success, NSError *error)) {
        passedBlock(NO, nil);
        return YES;
    }]]);
    self.settingsViewController.currentUser = mockSystemUser;

    id mockSwitch = OCMClassMock([UISwitch class]);
    OCMStub([mockSwitch isOn]).andReturn(YES);
    OCMStub([mockSwitch tag]).andReturn(1001);

    [self.settingsViewController didChangeSwitch:mockSwitch];

    OCMVerify([mockSwitch setOn:NO]);
}

- (void)testSegueWillHappenIfAccountCouldNotBeFetched {
    id mockSystemUser = OCMClassMock([SystemUser class]);
    OCMStub([mockSystemUser getAndActivateSIPAccountWithCompletion:[OCMArg checkWithBlock:^BOOL(void (^passedBlock)(BOOL success, NSError *error)) {
        passedBlock(NO, nil);
        return YES;
    }]]);
    self.settingsViewController.currentUser = mockSystemUser;

    id mockSettingsVC = OCMPartialMock(self.settingsViewController);

    id mockSwitch = OCMClassMock([UISwitch class]);
    OCMStub([mockSwitch isOn]).andReturn(YES);
    OCMStub([mockSwitch tag]).andReturn(1001);

    [self.settingsViewController didChangeSwitch:mockSwitch];

    OCMVerify([mockSettingsVC performSegueWithIdentifier:@"ShowActivateSIPAccount" sender:[OCMArg any]]);

    [mockSettingsVC stopMocking];
}

- (void)testWhenSipAccountIsFetchedReloadTable {
    id mockSystemUser = OCMClassMock([SystemUser class]);
    OCMStub([mockSystemUser getAndActivateSIPAccountWithCompletion:[OCMArg checkWithBlock:^BOOL(void (^passedBlock)(BOOL success, NSError *error)) {
        passedBlock(YES, nil);
        return YES;
    }]]);
    id mockTableView = OCMClassMock([UITableView class]);
    self.settingsViewController.currentUser = mockSystemUser;
    self.settingsViewController.tableView = mockTableView;
    id mockSwitch = OCMClassMock([UISwitch class]);
    OCMStub([mockSwitch isOn]).andReturn(YES);
    OCMStub([mockSwitch tag]).andReturn(1001);

    [self.settingsViewController didChangeSwitch:mockSwitch];

    OCMVerify([mockTableView reloadSections:[OCMArg any] withRowAnimation:UITableViewRowAnimationAutomatic]);
}

- (void)testNoSIPAccountFromLoginControllerSegueToActivateSIPAccount {
    self.settingsViewController.showSIPAccountWebview = YES;
    OCMVerify([self.settingsViewController performSegueWithIdentifier:@"ShowActivateSIPAccount" sender:self]);
}

@end
