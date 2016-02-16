//
//  SIPCallingViewControllerTests.m
//  Copyright © 2016 VoIPGRID. All rights reserved.
//

#import <OCMock/OCMock.h>
#import "SIPCallingViewController.h"
#import <XCTest/XCTest.h>

@interface SIPCallingViewController (PrivateImplementation)
@property (weak, nonatomic) UILabel *callStatusLabel;
@property (strong, nonatomic) VSLCall *call;
@property (weak, nonatomic) UIViewController *presentingViewController;
@end

@interface SIPCallingViewControllerTests : XCTestCase

@property (strong, nonatomic) SIPCallingViewController *sipCallingVC;
@property (strong, nonatomic) id mockCall;
@end

@implementation SIPCallingViewControllerTests

- (void)setUp {
    [super setUp];
    self.sipCallingVC = (SIPCallingViewController *)[[UIStoryboard storyboardWithName:@"SIPCallingStoryboard" bundle:nil] instantiateInitialViewController];
    self.mockCall = OCMClassMock([VSLCall class]);
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

    XCTestExpectation *expectation = [self expectationWithDescription:@"Should fetch callStatus again"];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [expectation fulfill];
    });

    [self.sipCallingVC observeValueForKeyPath:@"callState" ofObject:self.mockCall change:nil context:nil];

    // Check if view is dismissed.
    [self waitForExpectationsWithTimeout:4.0 handler:^(NSError * _Nullable error) {
        OCMVerify([viewMock dismissViewControllerAnimated:YES completion:nil]);
    }];
}

@end
