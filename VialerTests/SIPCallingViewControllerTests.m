//
//  SIPCallingViewControllerTests.m
//  Copyright © 2016 VoIPGRID. All rights reserved.
//

#import "DurationTimer.h"
#import <OCMock/OCMock.h>
#import "SIPCallingViewController.h"
#import "SIPCallingButtonsViewController.h"
#import <XCTest/XCTest.h>

@interface SIPCallingViewController (PrivateImplementation)
@property (weak, nonatomic) UILabel *phoneNumberLabel;
@property (weak, nonatomic) UILabel *callStatusLabel;
@property (weak, nonatomic) UIViewController *presentingViewController;
@property (weak, nonatomic) SipCallingButtonsViewController *sipCallingButtonsVC;
@property (strong, nonatomic) VSLCall *call;
@property (strong, nonatomic) NSString *phoneNumber;
@end

@interface SIPCallingViewControllerTests : XCTestCase
@property (strong, nonatomic) SIPCallingViewController *sipCallingVC;
@property (strong, nonatomic) id mockCall;
@end

@implementation SIPCallingViewControllerTests

- (void)setUp {
    [super setUp];
    self.sipCallingVC = (SIPCallingViewController *)[[UIStoryboard storyboardWithName:@"SIPCallingStoryboard" bundle:nil] instantiateInitialViewController];
    [self.sipCallingVC loadViewIfNeeded];
    self.mockCall = OCMClassMock([VSLCall class]);
}

- (void)tearDown {
    self.mockCall = nil;
    self.sipCallingVC = nil;
    [super tearDown];
}

- (void)testControllerHangsUpWillDisplayMessage {
    id mockLabel = OCMClassMock([UILabel class]);
    self.sipCallingVC.callStatusLabel = mockLabel;

    id mockButton = OCMClassMock([UIButton class]);

    [self.sipCallingVC endCallButtonPressed:mockButton];

    OCMVerify([mockLabel setText:[OCMArg any]]);
}

- (void)testWhenCallIsDisconnectedWillNotEndCallAgain {
    id mockLabel = OCMClassMock([UILabel class]);
    self.sipCallingVC.callStatusLabel = mockLabel;
    OCMStub([self.mockCall callState]).andReturn(VSLCallStateDisconnected);
    self.sipCallingVC.call = self.mockCall;

    id mockButton = OCMClassMock([UIButton class]);

    [[mockLabel reject] setText:[OCMArg any]];
    [[self.mockCall reject] hangup:[OCMArg anyObjectRef]];

    [self.sipCallingVC endCallButtonPressed:mockButton];
}

- (void)testControllerHangsUpWillAskCallToEndCall {
    self.sipCallingVC.call = self.mockCall;
    id mockButton = OCMClassMock([UIButton class]);

    [self.sipCallingVC endCallButtonPressed:mockButton];

    OCMVerify([self.mockCall hangup:[OCMArg anyObjectRef]]);
}

- (void)testCallIsEndedWillDismissViewController {
    self.sipCallingVC.call = self.mockCall;
    OCMStub([self.mockCall callState]).andReturn(VSLCallStateDisconnected);
    id sipMock = OCMPartialMock(self.sipCallingVC);
    id viewMock = OCMClassMock([UIViewController class]);
    OCMStub([sipMock presentingViewController]).andReturn(viewMock);

    XCTestExpectation *expectation = [self expectationWithDescription:@"Should dismiss view"];
    OCMStub([viewMock dismissViewControllerAnimated:YES completion:[OCMArg any]]).andDo(^(NSInvocation *invocation) {
        [expectation fulfill];
    });

    [self.sipCallingVC observeValueForKeyPath:@"callState" ofObject:self.mockCall change:nil context:nil];

    // Check if view is dismissed.
    [self waitForExpectationsWithTimeout:4.0 handler:^(NSError * _Nullable error) {
        OCMVerify([viewMock dismissViewControllerAnimated:YES completion:nil]);
    }];
}

- (void)testHideButtonIsHiddenOnDefault {
    XCTAssertTrue(self.sipCallingVC.hideButton.hidden, @"The hide button is hidden on default");
}

- (void)testHideButtonIsShownWhenAsked {
    [self.sipCallingVC keypadChangedVisibility:YES];
    XCTAssertFalse(self.sipCallingVC.hideButton.hidden, @"The hide button should be shown when asked");
}

- (void)testButtonsVCIsAskedToHideButtons {
    id mockButtonsVC = OCMClassMock([SipCallingButtonsViewController class]);
    self.sipCallingVC.sipCallingButtonsVC = mockButtonsVC;

    [self.sipCallingVC hideNumberpad:nil];

    OCMVerify([mockButtonsVC hideNumberpad]);

    [mockButtonsVC stopMocking];
}

- (void)testPhonenumberSetWillSetLabel {
    self.sipCallingVC.phoneNumber = @"242";
    XCTAssertEqualObjects(self.sipCallingVC.phoneNumberLabel.text, @"242", @"The phonenumber should be visible again");
}

- (void)testDTMFTonesWillSetLabel {
    self.sipCallingVC.phoneNumber = @"242";

    [self.sipCallingVC DTMFSend:@"1"];
    [self.sipCallingVC DTMFSend:@"2"];
    [self.sipCallingVC DTMFSend:@"3"];

    XCTAssertEqualObjects(self.sipCallingVC.phoneNumberLabel.text, @"123", @"The dtmf characters should be visible in the phonenumber label.");
}

- (void)testPhonenumberLabelWillResetToPhonenumberAfterKeypadBecameInvisible {
    self.sipCallingVC.phoneNumber = @"242";
    self.sipCallingVC.phoneNumberLabel.text = @"123";

    [self.sipCallingVC keypadChangedVisibility:NO];

    XCTAssertEqualObjects(self.sipCallingVC.phoneNumberLabel.text, @"242", @"The phonenumber should be visible again");
}

- (void)testCallConnectedDurationTimerIsRunning {
    self.sipCallingVC.call = self.mockCall;
    OCMStub([self.mockCall callState]).andReturn(VSLCallStateConfirmed);

    [self.sipCallingVC observeValueForKeyPath:@"callState" ofObject:self.mockCall change:nil context:nil];

    OCMVerify([[DurationTimer alloc] initAndStartDurationTimerWithTimeInterval:1.0 andDurationTimerStatusUpdateBlock:nil]);
}

- (void)testCallDisconnectedDurationTimerIsStopped {
    DurationTimer *durationTimer = [[DurationTimer alloc] initAndStartDurationTimerWithTimeInterval:1.0 andDurationTimerStatusUpdateBlock:nil];

    self.sipCallingVC.call = self.mockCall;
    OCMStub([self.mockCall callState]).andReturn(VSLCallStateDisconnected);

    [self.sipCallingVC observeValueForKeyPath:@"callState" ofObject:self.mockCall change:nil context:nil];

    OCMVerify([durationTimer stop]);
}

@end
