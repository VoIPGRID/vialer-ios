//
//  TwoStepCallTests.m
//  Copyright © 2015 VoIPGRID. All rights reserved.
//
#import <XCTest/XCTest.h>

#import <CoreTelephony/CTCallCenter.h>
#import <CoreTelephony/CTCall.h>
#import <OCMock/OCMock.h>
#import "SystemUser.h"
#import "TwoStepCall.h"
#import "VoIPGRIDRequestOperationManager.h"

@interface TwoStepCall (TestImplementation)
@property (strong, nonatomic) NSString *callID;
@property (strong, nonatomic) NSTimer *statusTimer;
@property (nonatomic) TwoStepCallStatus status;
@property (nonatomic) BOOL cancelingCall;
@property (nonatomic) BOOL fetching;
@property (strong, nonatomic) CTCallCenter *callCenter;
@end

@interface TwoStepCallTests : XCTestCase
@end

@implementation TwoStepCallTests

- (void)testTwoStepCallStatusIsUnknownOnDefault {
    TwoStepCall *call = [[TwoStepCall alloc] initWithANumber:@"42" andBNumber:@"43"];
    XCTAssertEqual(call.status, TwoStepCallStatusUnknown, @"The default status should be unknown.");
}

- (void)testTwoStepCallHasNoNumbersOnDefault {
    TwoStepCall *call = [[TwoStepCall alloc] init];
    XCTAssertNil(call.aNumber, @"There should be no A Number set when initialized.");
    XCTAssertNil(call.bNumber, @"There should be no B Number set when initialized.");
}

- (void)testDesignatedInitializedWillSetNumbers {
    TwoStepCall *call = [[TwoStepCall alloc] initWithANumber:@"42" andBNumber:@"43"];
    XCTAssertEqualObjects(call.aNumber, @"42", @"The A number should have been set.");
    XCTAssertEqualObjects(call.bNumber, @"43", @"The B number should have been set.");
}

- (void)testWrongNumberWillNotSetNumber {
    TwoStepCall *call = [[TwoStepCall alloc] initWithANumber:@"wrongnumbera" andBNumber:@"wrongnumberb"];
    XCTAssertNil(call.aNumber, @"The A number should be nil because the number is wrong");
    XCTAssertNil(call.bNumber, @"The B number should be nil because the number is wrong");
}

- (void)testBadFormattedNumberWillCleanNumber {
    TwoStepCall *call = [[TwoStepCall alloc] initWithANumber:@"261-20" andBNumber:@"+(2343) 3434"];
    XCTAssertEqualObjects(call.aNumber, @"26120", @"The A number should be cleaned");
    XCTAssertEqualObjects(call.bNumber, @"+23433434", @"The A number should be cleaned");
}

- (void)testStartWillAskOperationManagerToSetupCall {
    id mockOperationsManager = OCMClassMock([VoIPGRIDRequestOperationManager class]);
    OCMStub([mockOperationsManager setupTwoStepCallWithANumber:[OCMArg any] bNumber:[OCMArg any] withCompletion:[OCMArg invokeBlock]]);
    TwoStepCall *call = [[TwoStepCall alloc] initWithANumber:@"42" andBNumber:@"43"];
    call.operationsManager = mockOperationsManager;

    [call start];

    OCMVerify([mockOperationsManager setupTwoStepCallWithANumber:[OCMArg any] bNumber:[OCMArg any] withCompletion:[OCMArg any]]);
}

- (void)testUnAuthorizedCallWillSetCorrectStatusWhenStart {
    NSError *error = [NSError errorWithDomain:@"testDomain" code:VGTwoStepCallErrorStatusUnAuthorized userInfo:nil];
    id mockOperationsManager = OCMClassMock([VoIPGRIDRequestOperationManager class]);
    OCMStub([mockOperationsManager setupTwoStepCallWithANumber:[OCMArg any] bNumber:[OCMArg any] withCompletion:([OCMArg invokeBlockWithArgs:@"1", error, nil])]);
    TwoStepCall *call = [[TwoStepCall alloc] initWithANumber:@"42" andBNumber:@"43"];
    call.operationsManager = mockOperationsManager;

    [call start];

    XCTAssertEqual(call.status, TwoStepCallStatusUnAuthorized, @"Status should be unauthorized.");
}

- (void)testInvalidNumberWillSetCorrectStatusWhenStart {
    NSError *error = [NSError errorWithDomain:@"testDomain" code:VGTwoStepCallInvalidNumber userInfo:nil];
    id mockOperationsManager = OCMClassMock([VoIPGRIDRequestOperationManager class]);
    OCMStub([mockOperationsManager setupTwoStepCallWithANumber:[OCMArg any] bNumber:[OCMArg any] withCompletion:([OCMArg invokeBlockWithArgs:@"1", error, nil])]);
    TwoStepCall *call = [[TwoStepCall alloc] initWithANumber:@"42" andBNumber:@"43"];
    call.operationsManager = mockOperationsManager;

    [call start];

    XCTAssertEqual(call.status, TwoStepCallStatusInvalidNumber, @"Status should be invalid number.");
}

- (void)testUnknownErrorWillSetCorrectStatusWhenStart {
    NSError *error = [NSError errorWithDomain:@"testDomain" code:100 userInfo:nil];
    id mockOperationsManager = OCMClassMock([VoIPGRIDRequestOperationManager class]);
    OCMStub([mockOperationsManager setupTwoStepCallWithANumber:[OCMArg any] bNumber:[OCMArg any] withCompletion:([OCMArg invokeBlockWithArgs:@"1", error, nil])]);
    TwoStepCall *call = [[TwoStepCall alloc] initWithANumber:@"42" andBNumber:@"43"];
    call.operationsManager = mockOperationsManager;

    [call start];

    XCTAssertEqual(call.status, TwoStepCallStatusFailedSetup, @"Status should be invalid number.");
}

- (void)testSuccessfullStartShouldCallStatusForCorrectCallId {
    id mockOperationsManager = OCMClassMock([VoIPGRIDRequestOperationManager class]);
    // Return faked callId.
    OCMStub([mockOperationsManager setupTwoStepCallWithANumber:[OCMArg any] bNumber:[OCMArg any] withCompletion:[OCMArg checkWithBlock:^BOOL(void (^passedBlock)(NSString *, NSError *)) {
        passedBlock(@"142", nil);
        return YES;
    }]]);

    // Check if status will be fetched.
    XCTestExpectation *expectation = [self expectationWithDescription:@"Expect status call from TwoStepCall."];
    OCMStub([mockOperationsManager twoStepCallStatusForCallId:[OCMArg isEqual:@"142"] withCompletion:[OCMArg checkWithBlock:^BOOL(id obj) {
        [expectation fulfill];
        return YES;
    }]]);

    // Setup TwoStepCall.
    TwoStepCall *call = [[TwoStepCall alloc] initWithANumber:@"42" andBNumber:@"43"];
    call.operationsManager = mockOperationsManager;

    [call start];

    // Check if status is fetched.
    [self waitForExpectationsWithTimeout:2.0 handler:^(NSError * _Nullable error) {
        if (error != nil) {
            NSLog(@"Error: %@", error);
        }
    }];
}

- (void)testFailedFetchingCallStatusWillSetError {
    id mockOperationsManager = OCMClassMock([VoIPGRIDRequestOperationManager class]);

    // Return the error.
    NSError *error = [NSError errorWithDomain:@"testDomain" code:100 userInfo:nil];
    OCMStub([mockOperationsManager twoStepCallStatusForCallId:[OCMArg isEqual:@"142"] withCompletion:[OCMArg checkWithBlock:^BOOL(void (^passedBlock)(NSString *, NSError *)) {
        passedBlock(nil, error);
        return YES;
    }]]);

    // Setup TwoStepCall.
    TwoStepCall *call = [[TwoStepCall alloc] initWithANumber:@"42" andBNumber:@"43"];
    call.operationsManager = mockOperationsManager;
    call.callID = @"142";

    [call fetchCallStatus:nil];

    XCTAssertEqual(call.error, error, @"The error should have been set.");
}

- (void)testFetchedCallStatusDailingAWillSetCorrectStatus {
    id mockOperationsManager = OCMClassMock([VoIPGRIDRequestOperationManager class]);

    // Return the error.
    OCMStub([mockOperationsManager twoStepCallStatusForCallId:[OCMArg isEqual:@"142"] withCompletion:[OCMArg checkWithBlock:^BOOL(void (^passedBlock)(NSString *, NSError *)) {
        passedBlock(@"dialing_a", nil);
        return YES;
    }]]);

    // Setup TwoStepCall.
    TwoStepCall *call = [[TwoStepCall alloc] initWithANumber:@"42" andBNumber:@"43"];
    call.operationsManager = mockOperationsManager;
    call.callID = @"142";

    [call fetchCallStatus:nil];

    XCTAssertEqual(call.status, TwoStepCallStatusDialing_a, @"The status should be Dialing a.");
}

- (void)testFetchedCallStatusDailingBWillSetCorrectStatus {
    id mockOperationsManager = OCMClassMock([VoIPGRIDRequestOperationManager class]);

    // Return the error.
    OCMStub([mockOperationsManager twoStepCallStatusForCallId:[OCMArg isEqual:@"142"] withCompletion:[OCMArg checkWithBlock:^BOOL(void (^passedBlock)(NSString *, NSError *)) {
        passedBlock(@"dialing_b", nil);
        return YES;
    }]]);

    // Setup TwoStepCall.
    TwoStepCall *call = [[TwoStepCall alloc] initWithANumber:@"42" andBNumber:@"43"];
    call.operationsManager = mockOperationsManager;
    call.callID = @"142";

    [call fetchCallStatus:nil];

    XCTAssertEqual(call.status, TwoStepCallStatusDialing_b, @"The status should be Dialing b.");
}

- (void)testFetchedCallStatusConnectedWillSetCorrectStatus {
    id mockOperationsManager = OCMClassMock([VoIPGRIDRequestOperationManager class]);

    // Return the error.
    OCMStub([mockOperationsManager twoStepCallStatusForCallId:[OCMArg isEqual:@"142"] withCompletion:[OCMArg checkWithBlock:^BOOL(void (^passedBlock)(NSString *, NSError *)) {
        passedBlock(@"connected", nil);
        return YES;
    }]]);

    // Setup TwoStepCall.
    TwoStepCall *call = [[TwoStepCall alloc] initWithANumber:@"42" andBNumber:@"43"];
    call.operationsManager = mockOperationsManager;
    call.callID = @"142";

    [call fetchCallStatus:nil];

    XCTAssertEqual(call.status, TwoStepCallStatusConnected, @"The status should be connected.");
}

- (void)testFetchedCallStatusDisconnetedWillSetCorrectStatus {
    id mockOperationsManager = OCMClassMock([VoIPGRIDRequestOperationManager class]);

    // Return the error.
    OCMStub([mockOperationsManager twoStepCallStatusForCallId:[OCMArg isEqual:@"142"] withCompletion:[OCMArg checkWithBlock:^BOOL(void (^passedBlock)(NSString *, NSError *)) {
        passedBlock(@"disconnected", nil);
        return YES;
    }]]);

    // Setup TwoStepCall.
    TwoStepCall *call = [[TwoStepCall alloc] initWithANumber:@"42" andBNumber:@"43"];
    call.operationsManager = mockOperationsManager;
    call.callID = @"142";

    [call fetchCallStatus:nil];

    XCTAssertEqual(call.status, TwoStepCallStatusDisconnected, @"The status should be disconnected.");
}

- (void)testFetchedCallStatusFailedAWillSetCorrectStatus {
    id mockOperationsManager = OCMClassMock([VoIPGRIDRequestOperationManager class]);

    // Return the error.
    OCMStub([mockOperationsManager twoStepCallStatusForCallId:[OCMArg isEqual:@"142"] withCompletion:[OCMArg checkWithBlock:^BOOL(void (^passedBlock)(NSString *, NSError *)) {
        passedBlock(@"failed_a", nil);
        return YES;
    }]]);

    // Setup TwoStepCall.
    TwoStepCall *call = [[TwoStepCall alloc] initWithANumber:@"42" andBNumber:@"43"];
    call.operationsManager = mockOperationsManager;
    call.callID = @"142";

    [call fetchCallStatus:nil];

    XCTAssertEqual(call.status, TwoStepCallStatusFailed_a, @"The status should be failed_a.");
}

- (void)testFetchedCallStatusFailedBWillSetCorrectStatus {
    id mockOperationsManager = OCMClassMock([VoIPGRIDRequestOperationManager class]);

    // Return the error.
    OCMStub([mockOperationsManager twoStepCallStatusForCallId:[OCMArg isEqual:@"142"] withCompletion:[OCMArg checkWithBlock:^BOOL(void (^passedBlock)(NSString *, NSError *)) {
        passedBlock(@"failed_b", nil);
        return YES;
    }]]);

    // Setup TwoStepCall.
    TwoStepCall *call = [[TwoStepCall alloc] initWithANumber:@"42" andBNumber:@"43"];
    call.operationsManager = mockOperationsManager;
    call.callID = @"142";

    [call fetchCallStatus:nil];

    XCTAssertEqual(call.status, TwoStepCallStatusFailed_b, @"The status should be failed_b.");
}

- (void)testFetchedCallStatusUnknownStatusBWillSetCorrectStatus {
    id mockOperationsManager = OCMClassMock([VoIPGRIDRequestOperationManager class]);

    // Return the error.
    OCMStub([mockOperationsManager twoStepCallStatusForCallId:[OCMArg isEqual:@"142"] withCompletion:[OCMArg checkWithBlock:^BOOL(void (^passedBlock)(NSString *, NSError *)) {
        passedBlock(@"Unknown_Status", nil);
        return YES;
    }]]);

    // Setup TwoStepCall.
    TwoStepCall *call = [[TwoStepCall alloc] initWithANumber:@"42" andBNumber:@"43"];
    call.operationsManager = mockOperationsManager;
    call.callID = @"142";

    [call fetchCallStatus:nil];

    XCTAssertEqual(call.status, TwoStepCallStatusUnknown, @"The status should be unknown status.");
}

- (void)testFetchedCallStatusDisconnectedWIllInvalidateTimer {
    id mockOperationsManager = OCMClassMock([VoIPGRIDRequestOperationManager class]);

    // Return the error.
    OCMStub([mockOperationsManager twoStepCallStatusForCallId:[OCMArg isEqual:@"142"] withCompletion:[OCMArg checkWithBlock:^BOOL(void (^passedBlock)(NSString *, NSError *)) {
        passedBlock(@"disconnected", nil);
        return YES;
    }]]);

    // Setup TwoStepCall.
    TwoStepCall *call = [[TwoStepCall alloc] initWithANumber:@"42" andBNumber:@"43"];
    call.operationsManager = mockOperationsManager;
    call.callID = @"142";

    // Mock the timer.
    id mockTimer = OCMClassMock([NSTimer class]);

    [call fetchCallStatus:mockTimer];

    OCMExpect([mockTimer invalidate]);
}

- (void)testFetchedCallStatusFailedAWIllInvalidateTimer {
    id mockOperationsManager = OCMClassMock([VoIPGRIDRequestOperationManager class]);

    // Return the error.
    OCMStub([mockOperationsManager twoStepCallStatusForCallId:[OCMArg isEqual:@"142"] withCompletion:[OCMArg checkWithBlock:^BOOL(void (^passedBlock)(NSString *, NSError *)) {
        passedBlock(@"failed_a", nil);
        return YES;
    }]]);

    // Setup TwoStepCall.
    TwoStepCall *call = [[TwoStepCall alloc] initWithANumber:@"42" andBNumber:@"43"];
    call.operationsManager = mockOperationsManager;
    call.callID = @"142";

    // Mock the timer.
    id mockTimer = OCMClassMock([NSTimer class]);

    [call fetchCallStatus:mockTimer];

    OCMExpect([mockTimer invalidate]);
}

- (void)testFetchedCallStatusFailedBWIllInvalidateTimer {
    id mockOperationsManager = OCMClassMock([VoIPGRIDRequestOperationManager class]);

    // Return the error.
    OCMStub([mockOperationsManager twoStepCallStatusForCallId:[OCMArg isEqual:@"142"] withCompletion:[OCMArg checkWithBlock:^BOOL(void (^passedBlock)(NSString *, NSError *)) {
        passedBlock(@"failed_b", nil);
        return YES;
    }]]);

    // Setup TwoStepCall.
    TwoStepCall *call = [[TwoStepCall alloc] initWithANumber:@"42" andBNumber:@"43"];
    call.operationsManager = mockOperationsManager;
    call.callID = @"142";

    // Mock the timer.
    id mockTimer = OCMClassMock([NSTimer class]);

    [call fetchCallStatus:mockTimer];

    OCMExpect([mockTimer invalidate]);
}

- (void)testCanCancelWhenStatusIsUknown {
    TwoStepCall *call = [[TwoStepCall alloc] initWithANumber:@"42" andBNumber:@"43"];
    call.status = TwoStepCallStatusUnknown;

    XCTAssertTrue(call.canCancel, @"It should be possible to can call when the status is unknown.");
}

- (void)testCanCancelWhenStatusIsSetupCall {
    TwoStepCall *call = [[TwoStepCall alloc] initWithANumber:@"42" andBNumber:@"43"];
    call.status = TwoStepCallStatusSetupCall;

    XCTAssertTrue(call.canCancel, @"It should be possible to can call when the status is setup.");
}

- (void)testCanCancelWhenStatusIsDialingA {
    TwoStepCall *call = [[TwoStepCall alloc] initWithANumber:@"42" andBNumber:@"43"];
    call.status = TwoStepCallStatusDialing_a;

    XCTAssertTrue(call.canCancel, @"It should be possible to can call when the status is dialing a.");
}

- (void)testCanCancelWhenStatusIsDialingB {
    TwoStepCall *call = [[TwoStepCall alloc] initWithANumber:@"42" andBNumber:@"43"];
    call.status = TwoStepCallStatusDialing_b;

    XCTAssertTrue(call.canCancel, @"It should be possible to can call when the status is dialing b.");
}

- (void)testCanCancelWhenStatusIsConnected {
    TwoStepCall *call = [[TwoStepCall alloc] initWithANumber:@"42" andBNumber:@"43"];
    call.status = TwoStepCallStatusConnected;

    XCTAssertTrue(call.canCancel, @"It should be possible to can call when the status is connected.");
}

- (void)testCannotCancelWhenStatusIsUnAuthorized {
    TwoStepCall *call = [[TwoStepCall alloc] initWithANumber:@"42" andBNumber:@"43"];
    call.status = TwoStepCallStatusUnAuthorized;

    XCTAssertFalse(call.canCancel, @"It should not be possible to can call when the status is unauthorized.");
}

- (void)testCannotCancelWhenStatusIsDisconnected {
    TwoStepCall *call = [[TwoStepCall alloc] initWithANumber:@"42" andBNumber:@"43"];
    call.status = TwoStepCallStatusDisconnected;

    XCTAssertFalse(call.canCancel, @"It should not be possible to can call when the status is disconnected.");
}

- (void)testCannotCancelWhenStatusIsFailedA {
    TwoStepCall *call = [[TwoStepCall alloc] initWithANumber:@"42" andBNumber:@"43"];
    call.status = TwoStepCallStatusFailed_a;

    XCTAssertFalse(call.canCancel, @"It should not be possible to can call when the status is failed a.");
}

- (void)testCannotCancelWhenStatusIsFailedB {
    TwoStepCall *call = [[TwoStepCall alloc] initWithANumber:@"42" andBNumber:@"43"];
    call.status = TwoStepCallStatusFailed_b;

    XCTAssertFalse(call.canCancel, @"It should not be possible to can call when the status is failed b.");
}

- (void)testCannotCancelWhenStatusIsFailedSetup {
    TwoStepCall *call = [[TwoStepCall alloc] initWithANumber:@"42" andBNumber:@"43"];
    call.status = TwoStepCallStatusFailedSetup;

    XCTAssertFalse(call.canCancel, @"It should not be possible to can call when the status is failed setup.");
}

- (void)testCannotCancelWhenStatusIsInvalidNumber {
    TwoStepCall *call = [[TwoStepCall alloc] initWithANumber:@"42" andBNumber:@"43"];
    call.status = TwoStepCallStatusInvalidNumber;

    XCTAssertFalse(call.canCancel, @"It should not be possible to can call when the status is invalid number.");
}

- (void)testCannotCancelWhenStatusIsCanceled {
    TwoStepCall *call = [[TwoStepCall alloc] initWithANumber:@"42" andBNumber:@"43"];
    call.status = TwoStepCallStatusCanceled;

    XCTAssertFalse(call.canCancel, @"It should not be possible to can call when the status is canceled.");
}

- (void)testCancelCallWillInvalidateTimer {
    id mockOperationsManager = OCMClassMock([VoIPGRIDRequestOperationManager class]);
    // Setup TwoStepCall.
    TwoStepCall *call = [[TwoStepCall alloc] initWithANumber:@"42" andBNumber:@"43"];
    call.operationsManager = mockOperationsManager;
    call.callID = @"142";

    // Mock the timer.
    id mockTimer = OCMClassMock([NSTimer class]);
    call.statusTimer = mockTimer;

    [call cancel];

    OCMExpect([mockTimer invalidate]);
}

- (void)testCancelCallWillCancelCallRemote {
    id mockOperationsManager = OCMClassMock([VoIPGRIDRequestOperationManager class]);
    // Setup TwoStepCall.
    TwoStepCall *call = [[TwoStepCall alloc] initWithANumber:@"42" andBNumber:@"43"];
    call.operationsManager = mockOperationsManager;
    call.callID = @"142";

    [call cancel];

    OCMExpect([mockOperationsManager cancelTwoStepCallForCallId:[OCMArg isEqual:@"142"] withCompletion:[OCMArg any]]);
}

- (void)testCancelCallWillNotCancelCallIfNoCallIdIsSet {
    id mockOperationsManager = OCMClassMock([VoIPGRIDRequestOperationManager class]);

    // Setup TwoStepCall.
    TwoStepCall *call = [[TwoStepCall alloc] initWithANumber:@"42" andBNumber:@"43"];
    call.operationsManager = mockOperationsManager;

    [call cancel];

    [[mockOperationsManager reject] cancelTwoStepCallForCallId:[OCMArg any] withCompletion:[OCMArg any]];
}

- (void)testCancelCallWillCancelCallWhenPossible {
    id mockOperationsManager = OCMClassMock([VoIPGRIDRequestOperationManager class]);
    OCMStub([mockOperationsManager setupTwoStepCallWithANumber:[OCMArg any] bNumber:[OCMArg any] withCompletion:[OCMArg checkWithBlock:^BOOL(void (^passedBlock)(NSString *, NSError *)) {
        passedBlock(@"142", nil);
        return YES;
    }]]);

    // Setup TwoStepCall.
    TwoStepCall *call = [[TwoStepCall alloc] initWithANumber:@"42" andBNumber:@"43"];
    call.operationsManager = mockOperationsManager;

    [call cancel];
    [call start];

    OCMExpect([mockOperationsManager cancelTwoStepCallForCallId:[OCMArg isEqual:@"142"] withCompletion:[OCMArg any]]);
}

- (void)testWhenCancelingCallCannotCancelTwice {
    id mockOperationsManager = OCMClassMock([VoIPGRIDRequestOperationManager class]);
    [[mockOperationsManager reject] cancelTwoStepCallForCallId:[OCMArg any] withCompletion:[OCMArg any]];

    TwoStepCall *call = [[TwoStepCall alloc] initWithANumber:@"42" andBNumber:@"43"];
    call.operationsManager = mockOperationsManager;
    call.callID = @"142";
    call.cancelingCall = YES;

    [call cancel];
}

- (void)testWhenFetchingCallStatusDoNotFetchTwice {
    id mockOperationsManager = OCMClassMock([VoIPGRIDRequestOperationManager class]);
    [[mockOperationsManager reject] twoStepCallStatusForCallId:[OCMArg any] withCompletion:[OCMArg any]];

    TwoStepCall *call = [[TwoStepCall alloc] initWithANumber:@"42" andBNumber:@"43"];
    call.operationsManager = mockOperationsManager;
    call.callID = @"142";
    call.fetching = YES;

    [call fetchCallStatus:nil];
}

- (void)testNotificationObserverEnterBackgroundAddedWhenInitialised {
    id mockNotificationCenter = OCMClassMock([NSNotificationCenter class]);
    OCMStub([mockNotificationCenter defaultCenter]).andReturn(mockNotificationCenter);

    TwoStepCall *call = [[TwoStepCall alloc] initWithANumber:@"42" andBNumber:@"43"];

    OCMVerify([mockNotificationCenter addObserver:[OCMArg isEqual:call] selector:[OCMArg anySelector] name:[OCMArg isEqual:UIApplicationDidEnterBackgroundNotification] object:[OCMArg any]]);

    [mockNotificationCenter stopMocking];
}

- (void)testNotificationObserverBecomeActiveAddedWhenInitialised {
    id mockNotificationCenter = OCMClassMock([NSNotificationCenter class]);
    OCMStub([mockNotificationCenter defaultCenter]).andReturn(mockNotificationCenter);

    TwoStepCall *call = [[TwoStepCall alloc] initWithANumber:@"42" andBNumber:@"43"];

    OCMVerify([mockNotificationCenter addObserver:[OCMArg isEqual:call] selector:[OCMArg anySelector] name:[OCMArg isEqual:UIApplicationDidBecomeActiveNotification] object:[OCMArg any]]);

    [mockNotificationCenter stopMocking];
}

- (void)testNotificationObserverIsRemovedWhenDealloced {
    id mockNotificationCenter = OCMClassMock([NSNotificationCenter class]);
    OCMStub([mockNotificationCenter defaultCenter]).andReturn(mockNotificationCenter);

    TwoStepCall *call = [[TwoStepCall alloc] initWithANumber:@"42" andBNumber:@"43"];
    call = nil;

    OCMVerify([mockNotificationCenter removeObserver:[OCMArg any]]);

    [mockNotificationCenter stopMocking];
}

- (void)testWhenAppWentInBackgroundTimerIsInvalidated {
    id mockTimer = OCMClassMock([NSTimer class]);
    TwoStepCall *call = [[TwoStepCall alloc] initWithANumber:@"42" andBNumber:@"43"];
    call.callID = @"142";
    call.statusTimer = mockTimer;

    NSNotification *notification = [NSNotification notificationWithName:UIApplicationDidEnterBackgroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] postNotification:notification];

    OCMVerify([mockTimer invalidate]);
}

- (void)testWhenAppBecameActiveTimerIsSetup {
    TwoStepCall *call = [[TwoStepCall alloc] initWithANumber:@"42" andBNumber:@"43"];
    call.callID = @"142";

    XCTAssertNil(call.statusTimer);

    NSNotification *notification = [NSNotification notificationWithName:UIApplicationDidBecomeActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] postNotification:notification];

    XCTAssertNotNil(call.statusTimer);
}

- (void)testWhenCallIsStartedTheCallCenterCallBackIsSet {
    // Mock OperationsManager.
    id mockOperationsManager = OCMClassMock([VoIPGRIDRequestOperationManager class]);
    TwoStepCall *call = [[TwoStepCall alloc] initWithANumber:@"42" andBNumber:@"43"];
    call.operationsManager = mockOperationsManager;

    // Mock response from operationsManager.
    OCMStub([mockOperationsManager setupTwoStepCallWithANumber:[OCMArg any] bNumber:[OCMArg any] withCompletion:[OCMArg checkWithBlock:^BOOL(void (^passedBlock)(NSString *, NSError *)) {
        passedBlock(@"142", nil);
        return YES;
    }]]);

    // Mock callCenter.
    id mockCallCenter = OCMClassMock([CTCallCenter class]);
    call.callCenter = mockCallCenter;

    [call start];

    OCMVerify([mockCallCenter setCallEventHandler:[OCMArg any]]);
}

- (void)testWhenCallIsConnectedPauseStatusFetching {
    id mockOperationsManager = OCMClassMock([VoIPGRIDRequestOperationManager class]);
    TwoStepCall *call = [[TwoStepCall alloc] initWithANumber:@"42" andBNumber:@"43"];
    call.operationsManager = mockOperationsManager;

    // Mock response from operationsManager.
    OCMStub([mockOperationsManager setupTwoStepCallWithANumber:[OCMArg any] bNumber:[OCMArg any] withCompletion:[OCMArg checkWithBlock:^BOOL(void (^passedBlock)(NSString *, NSError *)) {
        passedBlock(@"142", nil);
        return YES;
    }]]);

    [call start];

    // Mock the timer after the start.
    id mockTimer = OCMClassMock([NSTimer class]);
    call.statusTimer = mockTimer;

    // Mock incoming phonecall.
    CTCall *mockCall = OCMClassMock([CTCall class]);
    OCMStub([mockCall callState]).andReturn(CTCallStateConnected);
    call.callCenter.callEventHandler(mockCall);

    // Check if timer is invalidated.
    OCMVerify([mockTimer invalidate]);
}

- (void)testWhenCallIsDisConnectedRestartFetching {
    id mockOperationsManager = OCMClassMock([VoIPGRIDRequestOperationManager class]);
    TwoStepCall *call = [[TwoStepCall alloc] initWithANumber:@"42" andBNumber:@"43"];
    call.operationsManager = mockOperationsManager;
    call.callID = @"142";
    // Mock response from operationsManager.
    OCMStub([mockOperationsManager setupTwoStepCallWithANumber:[OCMArg any] bNumber:[OCMArg any] withCompletion:[OCMArg checkWithBlock:^BOOL(void (^passedBlock)(NSString *, NSError *)) {
        passedBlock(@"142", nil);
        return YES;
    }]]);

    [call start];

    // Mock the timer after the start.
    [call.statusTimer invalidate];
    call.statusTimer = nil;

    // Mock incoming phonecall.
    CTCall *mockCall = OCMClassMock([CTCall class]);
    OCMStub([mockCall callState]).andReturn(CTCallStateDisconnected);
    call.callCenter.callEventHandler(mockCall);

    // Check if timer is invalidated.
    XCTAssertNotNil(call.statusTimer, @"There should be a new timer");
    OCMVerify([mockOperationsManager twoStepCallStatusForCallId:[OCMArg isEqual:@"142"] withCompletion:[OCMArg any]]);
}

- (void)testWhenCallIsDisConnectedDisconnectedStateIsSetAfterThreeSeconds {
    id mockOperationsManager = OCMClassMock([VoIPGRIDRequestOperationManager class]);
    TwoStepCall *call = [[TwoStepCall alloc] initWithANumber:@"42" andBNumber:@"43"];
    call.operationsManager = mockOperationsManager;

    // Mock response from operationsManager.
    OCMStub([mockOperationsManager setupTwoStepCallWithANumber:[OCMArg any] bNumber:[OCMArg any] withCompletion:[OCMArg checkWithBlock:^BOOL(void (^passedBlock)(NSString *, NSError *)) {
        passedBlock(@"142", nil);
        return YES;
    }]]);

    XCTestExpectation *expectation = [self expectationWithDescription:@"Should fetch callStatus again"];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [expectation fulfill];
    });
    [call start];

    // Mock the timer after the start.
    [call.statusTimer invalidate];
    call.statusTimer = nil;

    // Mock incoming phonecall.
    CTCall *mockCall = OCMClassMock([CTCall class]);
    OCMStub([mockCall callState]).andReturn(CTCallStateDisconnected);
    call.callCenter.callEventHandler(mockCall);

    [self waitForExpectationsWithTimeout:4.0 handler:^(NSError * _Nullable error) {
        XCTAssertEqual(call.status, TwoStepCallStatusDisconnected);
        if (error) {
            NSLog(@"Error: %@", error);
        }
    }];
}

@end
