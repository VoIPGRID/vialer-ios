//
//  SIPIncomingCallViewControllerTests.m
//  Vialer
//
//  Created by Redmer Loen on 23-02-16.
//  Copyright © 2016 VoIPGRID. All rights reserved.
//

#import <OCMock/OCMock.h>
#import "SIPIncomingCallViewController.h"
#import <XCTest/XCTest.h>

@interface SIPIncomingCallViewController (PrivateImplementation)
@property (strong, nonatomic) VSLCall *call;
@property (weak, nonatomic) UILabel *incomingCallStatusLabel;
@end

@interface SIPIncomingCallViewControllerTests : XCTestCase
@property (strong, nonatomic) SIPIncomingCallViewController *sipIncomingCallVC;
@property (strong, nonatomic) id mockCall;
@end

@implementation SIPIncomingCallViewControllerTests

- (void)setUp {
    [super setUp];
    self.sipIncomingCallVC = (SIPIncomingCallViewController *)[[UIStoryboard storyboardWithName:@"SIPIncomingCallStoryboard" bundle:nil] instantiateInitialViewController];
    self.mockCall = OCMClassMock([VSLCall class]);
}

- (void)testCallIsDeclinedWillDismissViewController {
    self.sipIncomingCallVC.call = self.mockCall;

    id mockSipIncomingCallVC = OCMPartialMock(self.sipIncomingCallVC);

    XCTestExpectation *expectation = [self expectationWithDescription:@"Should wait before dismissing the view"];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [expectation fulfill];
    });

    id mockButton = OCMClassMock([UIButton class]);
    [self.sipIncomingCallVC declineCallButtonPressed:mockButton];

    [self waitForExpectationsWithTimeout:4.0 handler:^(NSError * _Nullable error) {
        OCMVerify([mockSipIncomingCallVC dismissViewControllerAnimated:NO completion:[OCMArg any]]);
    }];
}

- (void)testControllerDeclinesWillAskCallToEndCall {
    self.sipIncomingCallVC.call = self.mockCall;
    id mockButton = OCMClassMock([UIButton class]);

    [self.sipIncomingCallVC declineCallButtonPressed:mockButton];
    OCMVerify([self.mockCall hangup:[OCMArg anyObjectRef]]);
}

- (void)testControllerDeclinesWillDisplayMessage {
    id mockLabel = OCMClassMock([UILabel class]);
    self.sipIncomingCallVC.incomingCallStatusLabel = mockLabel;

    id mockButton = OCMClassMock([UIButton class]);
    [self.sipIncomingCallVC declineCallButtonPressed:mockButton];

    OCMVerify([mockLabel setText:[OCMArg any]]);
}

- (void)testAcceptCallButtonPressetMovesToSegue {
    id mockSipIncomingCallVC = OCMPartialMock(self.sipIncomingCallVC);

    id mockButton = OCMClassMock([UIButton class]);
    [self.sipIncomingCallVC acceptCallButtonPressed:mockButton];

    OCMVerify([mockSipIncomingCallVC performSegueWithIdentifier:@"SIPCallingSegue" sender:[OCMArg any]]);
}

@end
