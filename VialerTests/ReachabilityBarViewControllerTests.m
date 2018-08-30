////
////  ReachabilityBarViewControllerTests.m
////  Copyright © 2016 VoIPGRID. All rights reserved.
////
//
//#import <XCTest/XCTest.h>
//
//#import <OCMock/OCMock.h>
//#import "ReachabilityManager.h"
//#import "ReachabilityBarViewController.h"
//#import "SystemUser.h"
//#import "TestReachabilityManagerDelegate.h"
//
//@interface ReachabilityBarViewControllerTests : XCTestCase
//@end
//
//@interface ReachabilityBarViewController ()
//@property (strong, nonatomic) ReachabilityManager *reachabilityManager;
//@property (weak, nonatomic) IBOutlet UILabel *informationLabel;
//@property (strong, nonatomic) SystemUser *currentUser;
//
//- (void)updateLayout;
//@end
//
//@implementation ReachabilityBarViewControllerTests
//
//// offline: statusbar displays: "no connection, cannot call".
//- (void)testSipNotAllowedOffline {
//    ReachabilityManagerStatusType reachabilityManagerStatus = ReachabilityManagerStatusOffline;
//    BOOL sipEnabled = NO;
//
//    BOOL statusBarVisible = YES;
//    NSString *expectedInformationLabelText = NSLocalizedString(@"No connection, cannot call.", nil);
//
//    [self performReachabilityBarUpdateLayoutTestWithReachabilityManagerStatus:reachabilityManagerStatus
//                                                     andCurrentUserSipEnabled:sipEnabled
//                                              andExpectedInformationLabelText:expectedInformationLabelText
//                                                           andShouldBeVisible:statusBarVisible];
//}
//
//// User is "allowed to SIP" but has disabled VoIP in settings:
//// 3g: statusbar displays: "VoIP disabled, enable in settings".
//- (void)testSipAllowedButDisabledLowSpeedConnection {
//    ReachabilityManagerStatusType reachabilityManagerStatus = ReachabilityManagerStatusLowSpeed;
//    BOOL sipEnabled = NO;
//
//    BOOL statusBarVisible = YES;
//    NSString *expectedInformationLabelText = NSLocalizedString(@"VoIP disabled, enable in settings", nil);
//
//    [self performReachabilityBarUpdateLayoutTestWithReachabilityManagerStatus:reachabilityManagerStatus
//                                                     andCurrentUserSipEnabled:sipEnabled
//                                              andExpectedInformationLabelText:expectedInformationLabelText
//                                                           andShouldBeVisible:statusBarVisible];
//}
//
//// 4g: statusbar displays: "VoIP disabled, enable in settings".
//// wifi: statusbar displays: "VoIP disabled, enable in settings".
//- (void)testSipAllowedButDisabledHighSpeedConnection {
//    ReachabilityManagerStatusType reachabilityManagerStatus = ReachabilityManagerStatusHighSpeed;
//    BOOL sipEnabled = NO;
//
//    BOOL statusBarVisible = YES;
//    NSString *expectedInformationLabelText = NSLocalizedString(@"VoIP disabled, enable in settings", nil);
//
//    [self performReachabilityBarUpdateLayoutTestWithReachabilityManagerStatus:reachabilityManagerStatus
//                                                     andCurrentUserSipEnabled:sipEnabled
//                                              andExpectedInformationLabelText:expectedInformationLabelText
//                                                           andShouldBeVisible:statusBarVisible];
//}
//
//// offline: statusbar displays: "no connection, cannot call".
//- (void)testSipAllowedButDisabledButOffline {
//    ReachabilityManagerStatusType reachabilityManagerStatus = ReachabilityManagerStatusOffline;
//    BOOL sipEnabled = NO;
//
//    BOOL statusBarVisible = YES;
//    NSString *expectedInformationLabelText = NSLocalizedString(@"No connection, cannot call.", nil);
//
//    [self performReachabilityBarUpdateLayoutTestWithReachabilityManagerStatus:reachabilityManagerStatus
//                                                     andCurrentUserSipEnabled:sipEnabled
//                                              andExpectedInformationLabelText:expectedInformationLabelText
//                                                           andShouldBeVisible:statusBarVisible];
//}
//
//// User is "allowed to SIP" and has enabled VoIP in settings:
//// 3g: statusbar displays: "Poor connection, Two step calling enabled".
//- (void)testSipAllowedAndEnabledLowSpeedConnection {
//    ReachabilityManagerStatusType reachabilityManagerStatus = ReachabilityManagerStatusLowSpeed;
//    BOOL sipEnabled = YES;
//
//    BOOL statusBarVisible = YES;
//    NSString *expectedInformationLabelText = NSLocalizedString(@"Poor connection, Two step calling enabled.", nil);
//
//    [self performReachabilityBarUpdateLayoutTestWithReachabilityManagerStatus:reachabilityManagerStatus
//                                                     andCurrentUserSipEnabled:sipEnabled
//                                              andExpectedInformationLabelText:expectedInformationLabelText
//                                                           andShouldBeVisible:statusBarVisible];
//}
//
//// 4g: no statusbar and no message shown.
//// wifi: no statusbar and no message shown.
//- (void)testSipAllowedAndEnabledHighSpeedConnection {
//    ReachabilityManagerStatusType reachabilityManagerStatus = ReachabilityManagerStatusHighSpeed;
//    BOOL sipEnabled = YES;
//
//    BOOL statusBarVisible = NO;
//    NSString *expectedInformationLabelText = @"";
//
//    [self performReachabilityBarUpdateLayoutTestWithReachabilityManagerStatus:reachabilityManagerStatus
//                                                     andCurrentUserSipEnabled:sipEnabled
//                                              andExpectedInformationLabelText:expectedInformationLabelText
//                                                           andShouldBeVisible:statusBarVisible];
//}
//
//// offline: statusbar displays: "no connection, cannot call.
//- (void)testSipAllowedAndEnabledButOffline {
//    ReachabilityManagerStatusType reachabilityManagerStatus = ReachabilityManagerStatusOffline;
//    BOOL sipEnabled = YES;
//
//    BOOL statusBarVisible = YES;
//    NSString *expectedInformationLabelText = NSLocalizedString(@"No connection, cannot call.", nil);
//
//    [self performReachabilityBarUpdateLayoutTestWithReachabilityManagerStatus:reachabilityManagerStatus
//                                                     andCurrentUserSipEnabled:sipEnabled
//                                              andExpectedInformationLabelText:expectedInformationLabelText
//                                                           andShouldBeVisible:statusBarVisible];
//}
//
///**
// *  A helper function for testing the updateLayout method of the ReachabilityBarViewController.
// *
// *  The following are input parameters:
// *  @param reachabilityMangerStatus The status which the ReachabilityManager should return.
// *  @param sipAllowed               Sip Allowed value for which to run the test.
// *  @param sipEnabled               Sip Enabled value for which to run the test.
// *
// *  These are the expected parameters:
// *  @param informationLabelText     The text which should appear in the information label of the bar.
// *  @param barShouldBeVisible       To test if the bar should be visible for the given input parameters
// */
//- (void)performReachabilityBarUpdateLayoutTestWithReachabilityManagerStatus:(ReachabilityManagerStatusType)reachabilityMangerStatus
//                                                   andCurrentUserSipEnabled:(BOOL)sipEnabled
//                                            andExpectedInformationLabelText:(NSString *)informationLabelText
//                                                         andShouldBeVisible:(BOOL)barShouldBeVisible {
//    // Setup
//    id mockReachabilityManager = OCMClassMock([ReachabilityManager class]);
//
//    ReachabilityBarViewController *reachabilityBarViewControllerUnderTest = [[ReachabilityBarViewController alloc] init];
//    reachabilityBarViewControllerUnderTest.reachabilityManager = mockReachabilityManager;
//
//    id mockCurrentUser = OCMClassMock([SystemUser class]);
//    reachabilityBarViewControllerUnderTest.currentUser = mockCurrentUser;
//
//    id mockReachabilityBarViewControllerDelegate = OCMStrictClassMock([TestReachabilityManagerDelegate class]);
//    reachabilityBarViewControllerUnderTest.delegate = mockReachabilityBarViewControllerDelegate;
//
//    id mockInformationLabel = OCMClassMock([UILabel class]);
//    reachabilityBarViewControllerUnderTest.informationLabel = mockInformationLabel;
//
//    // Given
//    OCMStub([mockReachabilityManager reachabilityStatus]).andReturn(reachabilityMangerStatus);
//    OCMStub([mockCurrentUser sipEnabled]).andReturn(sipEnabled);
//
//    OCMExpect([mockInformationLabel setText:informationLabelText]);
//    OCMExpect([mockReachabilityBarViewControllerDelegate reachabilityBar:reachabilityBarViewControllerUnderTest shouldBeVisible:barShouldBeVisible]);
//    OCMExpect([mockReachabilityBarViewControllerDelegate reachabilityBar:reachabilityBarViewControllerUnderTest
//                                                           statusChanged:reachabilityMangerStatus]);
//
//    // When
//    [reachabilityBarViewControllerUnderTest updateLayout];
//
//    // Then
//    OCMVerifyAllWithDelay(mockInformationLabel, 0.5);
//
//    // Cleanup
//    [mockReachabilityManager stopMocking];
//    reachabilityBarViewControllerUnderTest = nil;
//    [mockCurrentUser stopMocking];
//    [mockReachabilityBarViewControllerDelegate stopMocking];
//}
//
//
//@end
