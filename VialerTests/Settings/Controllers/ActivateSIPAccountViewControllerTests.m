//
//  ActivateSIPAccountViewControllerTests.m
//  Copyright © 2016 VoIPGRID. All rights reserved.
//

#import "ActivateSIPAccountViewController.h"
#import <OCMock/OCMock.h>
#import "UserProfileWebViewController.h"
#import <XCTest/XCTest.h>

@interface ActivateSIPAccountViewControllerTests : XCTestCase
@property (strong, nonatomic) ActivateSIPAccountViewController *activateSIPAccountVC;
@end

@implementation ActivateSIPAccountViewControllerTests

- (void)setUp {
    [super setUp];
    self.activateSIPAccountVC = [[UIStoryboard storyboardWithName:@"SettingsStoryboard" bundle:nil] instantiateViewControllerWithIdentifier:@"ActivateSIPAccountViewController"];
    [self.activateSIPAccountVC loadViewIfNeeded];
}

- (void)testBackButtonWillPopViewController {
    id mockActivateSIPAccountVC = OCMPartialMock(self.activateSIPAccountVC);
    id mockNavigationController = OCMClassMock([UINavigationController class]);
    OCMStub([mockActivateSIPAccountVC navigationController]).andReturn(mockNavigationController);

    [self.activateSIPAccountVC backButtonPressed:nil];

    OCMVerify([mockNavigationController popViewControllerAnimated:YES]);
}

- (void)testPrepareForSegueWillSetNextURL {
    id mockUserProfileWVC = OCMClassMock([UserProfileWebViewController class]);
    id mockSegue = OCMClassMock([UIStoryboardSegue class]);
    OCMStub([mockSegue destinationViewController]).andReturn(mockUserProfileWVC);

    [self.activateSIPAccountVC prepareForSegue:mockSegue sender:nil];

    OCMVerify([mockUserProfileWVC setNextUrl:[OCMArg isEqual:@"/user/change/"]]);
}

@end
