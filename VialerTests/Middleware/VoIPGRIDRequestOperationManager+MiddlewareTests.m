//
//  VoIPGRIDRequestOperationManager+MiddlewareTests.m
//  Copyright © 2016 VoIPGRID. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "Configuration.h"
#import "Middleware.h"
#import <OCMock/OCMock.h>
#import <OHHTTPStubs/OHHTTPStubs.h>
#import "VoIPGRIDRequestOperationManager+Middleware.h"

@interface Middleware()
- (VoIPGRIDRequestOperationManager *)middlewareAPI;
@end

@interface VoIPGRIDRequestOperationManager_MiddlewareTests : XCTestCase
@property (strong, nonatomic) VoIPGRIDRequestOperationManager *middlewareAPI;
@property (strong, nonatomic) NSString *middlewareBaseURLAsString;
@end

@implementation VoIPGRIDRequestOperationManager_MiddlewareTests

- (void)setUp {
    [super setUp];

    //To ensure an equal middleware API setup as actually used by the middleware class.
    Middleware *aMiddlewareInstance = [[Middleware alloc] init];
    self.middlewareAPI = [aMiddlewareInstance middlewareAPI];

    self.middlewareBaseURLAsString = [Configuration UrlForKey:ConfigurationMiddleWareBaseURLString];
}

- (void)tearDown {
    [OHHTTPStubs removeAllStubs];
    [super tearDown];
}

- (void)testUpdateDeviceRecordFail502 {
    //Given
    NSString *mockAPNSToken = @"0000000011111111222222223333333344444444555555556666666677777777";
    NSString *mockSIPAccount = @"42";
    int statusCodeToReturn = 502;

    [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
        NSString *requestSchemeAndHost = [NSString stringWithFormat:@"%@://%@", request.URL.scheme, request.URL.host];
        return [requestSchemeAndHost  isEqualToString:self.middlewareBaseURLAsString];
    } withStubResponse:^OHHTTPStubsResponse *(NSURLRequest *request) {
        return [OHHTTPStubsResponse responseWithData:[NSData data] statusCode:statusCodeToReturn headers:nil];
    }];

    XCTestExpectation *expectation = [self expectationWithDescription:@"Creating device record"];

    //When
    [self.middlewareAPI updateDeviceRecordWithAPNSToken:mockAPNSToken sipAccount:mockSIPAccount withCompletion:^(NSError *error) {
        if (!error) {
            XCTFail(@"An error should occur.");
        } else {
            //Then
            XCTAssert([error.localizedDescription isEqualToString:@"Request failed: bad gateway (502)"],
                      @"Test should fail with \"Request failed: bad gateway (502)\"");
        }
        [expectation fulfill];
    }];

    [self waitForExpectationsWithTimeout:5.0 handler:^(NSError *error) {
        if (error) {
            XCTFail(@"Expectation error");
        }
    }];
}

@end
