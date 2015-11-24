//
//  TwoStepCallTests.m
//  Copyright © 2015 VoIPGRID. All rights reserved.
//

#import "AFNetworkActivityLogger.h"
#import <CocoaLumberjack/CocoaLumberjack.h>
#import <OHHTTPStubs/OHHTTPStubs.h>
#import "TwoStepCall.h"
#import "SystemUser.h"
#import "VoIPGRIDRequestOperationManager.h"
#import <XCTest/XCTest.h>

static int ddLogLevel = DDLogLevelVerbose;

//This way private functions of a class are accessable to the test class.
@interface TwoStepCall ()
+ (NSString *)statusStringFromTwoStepCallStatus:(TwoStepCallStatus)callStatus;
+ (TwoStepCallStatus)twoStepCallStatusFromString:(NSString *)callStatus;
+ (NSArray *)callStatusStringArray;
@property (nonatomic)TwoStepCallStatus status;
@end

@interface TwoStepCallTests : XCTestCase
@end

@implementation TwoStepCallTests

- (void)setUp {
    [super setUp];
    DDASLLogger *aslLogger = [DDASLLogger sharedInstance];
    DDTTYLogger *ttyLogger = [DDTTYLogger sharedInstance];
    [ttyLogger setColorsEnabled:YES];

    //Give INFO a color
    UIColor *pink = [UIColor colorWithRed:(255/255.0) green:(58/255.0) blue:(159/255.0) alpha:1.0];
    [[DDTTYLogger sharedInstance] setForegroundColor:pink backgroundColor:nil forFlag:DDLogFlagInfo];

    [DDLog addLogger:aslLogger];
    [DDLog addLogger:ttyLogger];

    //Start the AFNetworkActivity logger
    [[AFNetworkActivityLogger sharedLogger] startLogging];
    [[AFNetworkActivityLogger sharedLogger] setLevel:AFLoggerLevelDebug];

    //Is the user logged in?
    XCTAssert([SystemUser currentUser].isLoggedIn);
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}


//Test to see if a call ID is returned and matches the one supplied in the stubed response
- (void)testSetupTwoStepCall_Succes {
    //GIVEN
    NSString *aNumber = @"+31011111111";
    NSString *bNumber = @"+31022222222";
    NSString *callID = @"TEST_ID_fe078ea57d8d0ad212c7292"; //random ID
    NSString *requestPath = @"/api/mobileapp";

    //Stub the response to requestPath
    [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
        return [request.URL.path isEqualToString:requestPath];
    } withStubResponse:^OHHTTPStubsResponse *(NSURLRequest *request) {
        return [OHHTTPStubsResponse responseWithJSONObject:@{@"callid" : callID,
                                                             }
                                                statusCode:200
                                                   headers:nil];
    }];
    XCTestExpectation *expectation = [self expectationWithDescription:@"Two Step Call"];

    //WHEN
    [[VoIPGRIDRequestOperationManager sharedRequestOperationManager] setupTwoStepCallWithANumber:aNumber
                                                                                         bNumber:bNumber
                                                                                  withCompletion:
     ^(NSString *returnedCallID, NSError *error) {
         //THEN
         XCTAssert([callID isEqualToString:returnedCallID], @"Returned call ID did not match");
         [expectation fulfill];
     }];

    [self waitForExpectationsWithTimeout:5.0 handler:^(NSError *error) {
    }];
}

//Test for "This number is not permitted" error for A number
- (void)testSetupTwoStepCall_ANumberNotPermitted {
    //GIVEN
    NSString *aNumber = @"+31";
    NSString *bNumber = @"+31022222222";
    NSString *requestPath = @"/api/mobileapp";
    NSString *errorString = @"This number is not permitted.";

    //Stub the response to requestPath
    [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
        return [request.URL.path isEqualToString:requestPath];
    } withStubResponse:^OHHTTPStubsResponse *(NSURLRequest* request) {
        NSData *responseData = [errorString dataUsingEncoding:NSUTF8StringEncoding];
        return [OHHTTPStubsResponse responseWithData:responseData
                                          statusCode:400
                                             headers:nil];
    }];
    XCTestExpectation *expectation = [self expectationWithDescription:@"Setup Two Step Call"];

    //WHEN
    [[VoIPGRIDRequestOperationManager sharedRequestOperationManager] setupTwoStepCallWithANumber:aNumber
                                                                                         bNumber:bNumber
                                                                                  withCompletion:
     ^(NSString *returnedCallID, NSError *error) {
         //THEN
         XCTAssert([error.localizedDescription isEqualToString:NSLocalizedString(errorString, nil)]);
         [expectation fulfill];
     }];

    [self waitForExpectationsWithTimeout:5.0 handler:^(NSError *error) {
    }];
}

//Test for "This number is not permitted" error for B number
- (void)testSetupTwoStepCall_BNumberNotPermitted {
    //GIVEN
    NSString *aNumber = @"+31011111111";
    NSString *bNumber = @"+31";
    NSString *requestPath = @"/api/mobileapp";
    NSString *errorString = @"This number is not permitted.";

    //Stub the response to requestPath
    [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
        return [request.URL.path isEqualToString:requestPath];
    } withStubResponse:^OHHTTPStubsResponse *(NSURLRequest *request) {
        NSData *responseData = [errorString dataUsingEncoding:NSUTF8StringEncoding];
        return [OHHTTPStubsResponse responseWithData:responseData
                                          statusCode:400
                                             headers:nil];
    }];
    XCTestExpectation *expectation = [self expectationWithDescription:@"Setup Two Step Call"];

    //WHEN
    [[VoIPGRIDRequestOperationManager sharedRequestOperationManager] setupTwoStepCallWithANumber:aNumber
                                                                                         bNumber:bNumber
                                                                                  withCompletion:
     ^(NSString *returnedCallID, NSError *error) {
         //THEN
         XCTAssert([error.localizedDescription isEqualToString:NSLocalizedString(errorString, nil)]);
         [expectation fulfill];
     }];

    [self waitForExpectationsWithTimeout:5.0 handler:^(NSError * _Nullable error) {
    }];
}

//Test for Extensions or phonenumbers not valid
- (void)testSetupTwoStepCall_NotValidANumber {
    //GIVEN
    NSString *aNumber = @"-3";
    NSString *bNumber = @"+31022222222";
    NSString *requestPath = @"/api/mobileapp";
    NSString *errorString = @"Extensions or phonenumbers not valid";

    //Stub the response to requestPath
    [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
        return [request.URL.path isEqualToString:requestPath];
    } withStubResponse:^OHHTTPStubsResponse *(NSURLRequest *request) {
        NSData *responseData = [errorString dataUsingEncoding:NSUTF8StringEncoding];
        return [OHHTTPStubsResponse responseWithData:responseData
                                          statusCode:400
                                             headers:nil];
    }];
    XCTestExpectation *expectation = [self expectationWithDescription:@"Setup Two Step Call"];

    //WHEN
    [[VoIPGRIDRequestOperationManager sharedRequestOperationManager] setupTwoStepCallWithANumber:aNumber
                                                                                         bNumber:bNumber
                                                                                  withCompletion:
     ^(NSString *returnedCallID, NSError *error) {
         //THEN
         XCTAssert([error.localizedDescription isEqualToString:NSLocalizedString(errorString, nil)]);
         [expectation fulfill];
     }];

    [self waitForExpectationsWithTimeout:5.0 handler:^(NSError *error) {
    }];
}

#pragma mark
//Test checking of status for an invalid Call ID
- (void)testTwoStepCallStatus_invalidCallId {
    //GIVEN
    NSString *callId = @"INVALID_TEST_ID_fd0ad212c7292";
    NSString *requestPath = [NSString stringWithFormat:@"/api/mobileapp/%@/", callId];
    NSString *errorString = @"Two step call failed";

    //Stub the response to requestPath
    [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
        return [request.URL.path isEqualToString:requestPath];
    } withStubResponse:^OHHTTPStubsResponse *(NSURLRequest *request) {
        return [OHHTTPStubsResponse responseWithData:[[NSData alloc] init]
                                          statusCode:404
                                             headers:nil];
    }];
    XCTestExpectation *expectation = [self expectationWithDescription:@"Two Step Call Status request"];

    //WHEN
    [[VoIPGRIDRequestOperationManager sharedRequestOperationManager] twoStepCallStatusForCallId:callId withCompletion:^(NSString *callStatus, NSError *error) {
        //THEN
        XCTAssert([error.localizedDescription isEqualToString:NSLocalizedString(errorString, nil)]);
        [expectation fulfill];
    }];

    [self waitForExpectationsWithTimeout:5.0 handler:^(NSError *error) {
    }];
}

//TODO: incomplete test but can be used, when 2 numbers are entered to test the Two Step Call functionaly.
//The test will stop when the call status is changed to twoStepCallStatusDisconnected.
- (void)xtestTwoStepCall {
    //GIVEN
    NSString *aNumber = @"";
    NSString *bNumber = @"";
    TwoStepCall *call = [[TwoStepCall alloc] initWithANumber:aNumber andBNumber:bNumber];
    [self keyValueObservingExpectationForObject:call keyPath:@"status"
                                        handler:
     ^BOOL(id observedObject, NSDictionary *change) {
         TwoStepCallStatus oldStatus = [[change objectForKey:@"old"] intValue];
         TwoStepCallStatus newStatus = [[change objectForKey:@"new"] intValue];

         DDLogInfo(@"Value change for key:\"callStatus\" old:%@ new:%@",
                   [TwoStepCall statusStringFromTwoStepCallStatus:oldStatus],
                   [TwoStepCall statusStringFromTwoStepCallStatus:newStatus]);

         if (newStatus == TwoStepCallStatusDisconnected) {
             return YES;
         }
         return NO;
     }];


    //WHEN
    [call start];

    [self waitForExpectationsWithTimeout:60.0 handler:^(NSError *error) {
    }];
}

@end
