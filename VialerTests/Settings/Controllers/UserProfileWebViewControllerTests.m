//
//  UserProfileWebViewControllerTests.m
//  Copyright © 2016 VoIPGRID. All rights reserved.
//

#import <OCMock/OCMock.h>
#import "SystemUser.h"
#import "UserProfileWebViewController.h"
#import <XCTest/XCTest.h>

@interface UserProfileWebViewControllerTests : XCTestCase
@property (strong, nonatomic) UserProfileWebViewController *userProfileWVC;
@end

@implementation UserProfileWebViewControllerTests

- (void)setUp {
    [super setUp];
    self.userProfileWVC = [[UIStoryboard storyboardWithName:@"SettingsStoryboard" bundle:nil] instantiateViewControllerWithIdentifier:@"UserProfileWebViewController"];
    [self.userProfileWVC loadViewIfNeeded];
}

- (void)testBackButtonPressedWillCheckSipStatus {
    id mockSystemUser = OCMClassMock([SystemUser class]);
    self.userProfileWVC.currentUser = mockSystemUser;

    [self.userProfileWVC cancelButtonPressed:nil];

    OCMVerify([mockSystemUser getAndActivateSIPAccountWithCompletion:[OCMArg any]]);
}

- (void)testSipCheckFailWillPopViewController {
    id mockSystemUser = OCMClassMock([SystemUser class]);
    OCMStub([mockSystemUser getAndActivateSIPAccountWithCompletion:[OCMArg checkWithBlock:^BOOL(void (^passedBlock)(BOOL success, NSError *error)) {
        passedBlock(NO, nil);
        return YES;
    }]]);
    self.userProfileWVC.currentUser = mockSystemUser;
    id mockUserProfileWVC = OCMPartialMock(self.userProfileWVC);
    id mockNavigationController = OCMClassMock([UINavigationController class]);
    OCMStub([mockUserProfileWVC navigationController]).andReturn(mockNavigationController);

    [self.userProfileWVC cancelButtonPressed:nil];

    OCMVerify([mockNavigationController popViewControllerAnimated:YES]);
}

- (void)testBackgroundButtonWillSegueToRootViewController {
    self.userProfileWVC.backButtonToRootViewController = YES;
    [self.userProfileWVC cancelButtonPressed:nil];

    OCMVerify([self.userProfileWVC performSegueWithIdentifier:@"VialerRootViewControllerSegue" sender:self]);
}

- (void)testSipCheckOkWillUnwindToSettings {
    id mockSystemUser = OCMClassMock([SystemUser class]);
    OCMStub([mockSystemUser sipAccount]).andReturn(@"123400042");
    OCMStub([mockSystemUser getAndActivateSIPAccountWithCompletion:[OCMArg checkWithBlock:^BOOL(void (^passedBlock)(BOOL success, NSError *error)) {
        passedBlock(YES, nil);
        return YES;
    }]]);
    self.userProfileWVC.currentUser = mockSystemUser;
    id mockUserProfileWVC = OCMPartialMock(self.userProfileWVC);

    [self.userProfileWVC cancelButtonPressed:nil];

    OCMVerify([mockUserProfileWVC performSegueWithIdentifier:@"UnwindToSettingsSegue" sender:[OCMArg any]]);
}
@end
