////
////  SIPIncomingCallViewControllerTests.m
////  Copyright © 2016 VoIPGRID. All rights reserved.
////
//
//#import <OCMock/OCMock.h>
//#import "SIPIncomingCallViewController.h"
//#import "SystemUser.h"
//@import XCTest;
//
//@interface SIPIncomingCallViewController (PrivateImplementation)
//@property (strong, nonatomic) VSLCall *call;
//@property (weak, nonatomic) UILabel *incomingCallStatusLabel;
//@end
//
//@interface SIPIncomingCallViewControllerTests : XCTestCase
//@property (strong, nonatomic) SIPIncomingCallViewController *sipIncomingCallVC;
//@property (strong, nonatomic) id mockCall;
//@property (strong, nonatomic) id mockSystemUser;
//@end
//
//@implementation SIPIncomingCallViewControllerTests
//
//- (void)setUp {
//    [super setUp];
//    self.sipIncomingCallVC = (SIPIncomingCallViewController *)[[UIStoryboard storyboardWithName:@"SIPIncomingCallStoryboard" bundle:nil] instantiateInitialViewController];
//    [self.sipIncomingCallVC loadViewIfNeeded];
//    self.mockCall = OCMClassMock([VSLCall class]);
//
//    self.mockSystemUser = OCMClassMock([SystemUser class]);
//    OCMStub([self.mockSystemUser currentUser]).andReturn(self.mockSystemUser);
//    NSString *mockSIPAccount = @"012334456";
//    OCMStub([self.mockSystemUser sipAccount]).andReturn(mockSIPAccount);
//}
//
//- (void)tearDown {
//    [self.mockCall stopMocking];
//    self.mockCall = nil;
//    self.sipIncomingCallVC = nil;
//    [self.mockSystemUser stopMocking];
//    [super tearDown];
//}
//
//- (void)testCallIsDeclinedWillDismissViewController {
//    self.sipIncomingCallVC.call = self.mockCall;
//
//    id mockSipIncomingCallVC = OCMPartialMock(self.sipIncomingCallVC);
//
//    OCMStub([self.mockCall callState]).andReturn(VSLCallStateDisconnected);
//
//    XCTestExpectation *expectation = [self expectationWithDescription:@"Should wait before dismissing the view"];
//    OCMStub([mockSipIncomingCallVC dismissViewControllerAnimated:NO completion:[OCMArg any]]).andDo(^(NSInvocation *invocation) {
//        [expectation fulfill];
//    });
//
//    id mockButton = OCMClassMock([UIButton class]);
//    [self.sipIncomingCallVC declineCallButtonPressed:mockButton];
//
//    [self.sipIncomingCallVC observeValueForKeyPath:@"callState" ofObject:self.mockCall change:nil context:nil];
//
//    [self waitForExpectationsWithTimeout:5.0 handler:^(NSError * _Nullable error) {
//        OCMVerify([mockSipIncomingCallVC dismissViewControllerAnimated:NO completion:[OCMArg any]]);
//        [mockButton stopMocking];
//        [mockSipIncomingCallVC stopMocking];
//    }];
//}
//
//- (void)testControllerDeclinesWillAskCallToEndCall {
//    self.sipIncomingCallVC.call = self.mockCall;
//    id mockButton = OCMClassMock([UIButton class]);
//
//    [self.sipIncomingCallVC declineCallButtonPressed:mockButton];
//    OCMVerify([self.mockCall decline:[OCMArg anyObjectRef]]);
//    [mockButton stopMocking];
//}
//
//- (void)testControllerDeclinesWillDisplayMessage {
//    id mockLabel = OCMClassMock([UILabel class]);
//    self.sipIncomingCallVC.incomingCallStatusLabel = mockLabel;
//
//    id mockButton = OCMClassMock([UIButton class]);
//    [self.sipIncomingCallVC declineCallButtonPressed:mockButton];
//
//    OCMVerify([mockLabel setText:[OCMArg any]]);
//    [mockButton stopMocking];
//    [mockLabel stopMocking];
//}
//
//- (void)testAcceptCallButtonPressedMovesToSegue {
//    self.sipIncomingCallVC.call = self.mockCall;
//    OCMStub([self.mockCall answerWithCompletion:([OCMArg invokeBlockWithArgs:[NSNull null], nil])]);
//    
//    id mockSipIncomingCallVC = OCMPartialMock(self.sipIncomingCallVC);
//
//    id mockButton = OCMClassMock([UIButton class]);
//    [self.sipIncomingCallVC acceptCallButtonPressed:mockButton];
//    
//    //Run the main loop briefly to let it call the async block. https://stackoverflow.com/questions/12463733/objective-c-unit-testing-dispatch-async-block
//    [[NSRunLoop mainRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.01]];
//    OCMVerify([mockSipIncomingCallVC performSegueWithIdentifier:@"SIPCallingSegue" sender:[OCMArg any]]);
//    
//    [mockButton stopMocking];
//    [mockSipIncomingCallVC stopMocking];
//}
//
//@end
