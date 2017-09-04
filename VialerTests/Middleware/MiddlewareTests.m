//
//  MiddlewareTests.m
//  Copyright © 2016 VoIPGRID. All rights reserved.
//

#import "APNSHandler.h"
#import "Configuration.h"
#import "Middleware.h"
#import "MiddlewareRequestOperationManager.h"
#import <OCMock/OCMock.h>
#import "ReachabilityManager.h"
#import "SystemUser.h"
@import XCTest;

@interface Middleware()
@property (strong, nonatomic) MiddlewareRequestOperationManager *commonMiddlewareRequestOperationManager;
@property (strong, nonatomic) ReachabilityManager *reachabilityManager;
@property (weak, nonatomic) SystemUser *systemUser;
@end

@interface MiddlewareTests : XCTestCase
@property (strong, nonatomic) Middleware *middleware;
@end

@implementation MiddlewareTests

- (void)setUp {
    [super setUp];
    self.middleware = [[Middleware alloc] init];
}

- (void)tearDown {
    self.middleware = nil;
    [super tearDown];
}

- (void)testSystemUserGetterCreation {
    SystemUser *sharedCurrentUser = [SystemUser currentUser];
    SystemUser *APNSHandlerPropertyOfSystemUser = self.middleware.systemUser;

    XCTAssertEqualObjects(sharedCurrentUser, APNSHandlerPropertyOfSystemUser, @"System User - Current User instances did not match");
}

- (void)testMiddlewareRequestOperationManagerPropertyCreation {
    MiddlewareRequestOperationManager *createdMiddlewareRequestOperationManager = self.middleware.commonMiddlewareRequestOperationManager;

    XCTAssert([createdMiddlewareRequestOperationManager isKindOfClass:[MiddlewareRequestOperationManager class]]);

    NSString *baseURLFromConfig = [[Configuration defaultConfiguration] UrlForKey:ConfigurationMiddleWareBaseURLString];
    XCTAssert([[createdMiddlewareRequestOperationManager.baseURL absoluteString] isEqualToString:baseURLFromConfig], @"Base URL of the API endpoint did not match %@ and %@", createdMiddlewareRequestOperationManager.baseURL.absoluteString, baseURLFromConfig);

    XCTAssert([createdMiddlewareRequestOperationManager.responseSerializer isKindOfClass:[AFHTTPResponseSerializer class]]);

    NSSet *referenceSet = [NSSet setWithObjects:@"GET", @"HEAD", nil];
    XCTAssert([createdMiddlewareRequestOperationManager.requestSerializer.HTTPMethodsEncodingParametersInURI isEqualToSet:referenceSet],
              @"Only GET and HEAD parameters should be put in URI, the rest in body");
}

- (void)testReachabilityManagerCreation {
    //The Assert calls the getter which will lazy load de registry which succeeds the test.
    XCTAssert([self.middleware.reachabilityManager isKindOfClass:[ReachabilityManager class]]);
}

- (void)testSentAPNSToken {
    //Given
    id mockMiddlewareRequestOperationManager = OCMClassMock([MiddlewareRequestOperationManager class]);
    id mockSystemUser = OCMClassMock([SystemUser class]);
    NSString *mockAPNSToken = @"0000000011111111222222223333333344444444555555556666666677777777";
    NSString *mockSIPAccount = @"012334456";

    //When
    self.middleware.commonMiddlewareRequestOperationManager = mockMiddlewareRequestOperationManager;
    OCMStub([mockSystemUser sipEnabled]).andReturn(YES);
    OCMStub([mockSystemUser sipAccount]).andReturn(mockSIPAccount);
    self.middleware.systemUser = mockSystemUser;
    [self.middleware sentAPNSToken:mockAPNSToken];

    //Then
    OCMVerify([mockMiddlewareRequestOperationManager updateDeviceRecordWithAPNSToken:[OCMArg isEqual:mockAPNSToken] sipAccount:[OCMArg isEqual:mockSIPAccount] withCompletion:[OCMArg any]]);
    [mockMiddlewareRequestOperationManager stopMocking];
    [mockSystemUser stopMocking];
}

- (void)testRegistrationOnAnotherDeviceWithSystemUserSipEnabled {
    // Given
    id mockSystemUser = OCMClassMock([SystemUser class]);
    OCMStub([mockSystemUser sipEnabled]).andReturn(YES);

    // Should me equal to the constants devined in Middleware.m.
    NSString * MiddlewareAPNSPayloadKeyType       = @"type";
    NSString * MiddlewareAPNSPayloadKeyMessage    = @"message";
    NSDictionary *mockDictionary = @{MiddlewareAPNSPayloadKeyType : MiddlewareAPNSPayloadKeyMessage};

    self.middleware.systemUser = mockSystemUser;

    XCTestExpectation *expectation = [self expectationForNotification:MiddlewareRegistrationOnOtherDeviceNotification object:nil handler:^BOOL(NSNotification * _Nonnull notification) {
        // Then
        OCMVerify([mockSystemUser setSipEnabled:NO]);
        [expectation fulfill];
        return YES;
    }];

    // When
    [self.middleware handleReceivedAPNSPayload:mockDictionary];

    // Cleanup
    [self waitForExpectationsWithTimeout:5.0 handler:^(NSError * _Nullable error) {
        [mockSystemUser stopMocking];
    }];
}

- (void)testRegistrationOnAnotherDeviceWithSystemUserSipDisabled {
    // Given
    // This is a strict class mock. It will cause the test to fail when a method is invoked
    // which is not explicitly "stubed" or "expected".
    id mockNSNotificationQueue = OCMStrictClassMock([NSNotificationQueue class]);
    // Mock the NSNotificationQueue class method "defaultQueue to return the mock NotificationQueue.
    OCMStub([mockNSNotificationQueue defaultQueue]).andReturn(mockNSNotificationQueue);

    id mockSystemUser = OCMClassMock([SystemUser class]);
    OCMStub([mockSystemUser sipEnabled]).andReturn(NO);
    self.middleware.systemUser = mockSystemUser;

    // Should be equal to the constants defined in Middleware.m.
    NSString *middlewareAPNSPayloadKeyType = @"type";
    NSString *mockType = @"message";
    NSDictionary *mockDictionary = @{middlewareAPNSPayloadKeyType : mockType};

    // When
    [self.middleware handleReceivedAPNSPayload:mockDictionary];

    // Then
    // The middleware could call [NSNotificationQueue enqueueNotification....] but this method is not
    // stubed. mockNSNotificationQueue being a strict mock will not allow enqueueNotification to be called.
    // So, the test here is that enqueueNotification is not called.
    [mockNSNotificationQueue verify];

    // Cleanup
    [mockSystemUser stopMocking];
    [mockNSNotificationQueue stopMocking];
}

- (void)testAppRespondsToMiddlewareProvidedInPayload {
    // Should be equal to the constants defined in Middleware.m.
    NSString *middlewareAPNSPayloadKeyType = @"type";
    NSString *mockType = @"call";

    NSString *middlewareAPNSPayloadKeyResponseAPI = @"response_api";
    NSString *mockResponseAPI = @"https://mock.response.api.nl/api/call-response/";

    NSString *middlewareResponseKeyUniqueKey = @"unique_key";
    NSString *mockUniqueKey = @"123456";

    NSString *middlewareResponseKeyMessageStartTime = @"message_start_time";
    NSString *mockMessageStartTime = @"1465292030.264119";

    NSDictionary *mockDictionary = @{middlewareAPNSPayloadKeyType : mockType,
                                     middlewareAPNSPayloadKeyResponseAPI : mockResponseAPI,
                                     middlewareResponseKeyUniqueKey : mockUniqueKey,
                                     middlewareResponseKeyMessageStartTime : mockMessageStartTime};

    id mockMiddlewareRequestOperationManager = OCMClassMock([MiddlewareRequestOperationManager class]);
    OCMStub([mockMiddlewareRequestOperationManager alloc]).andReturn(mockMiddlewareRequestOperationManager);

    OCMStub([mockMiddlewareRequestOperationManager initWithBaseURL:[OCMArg checkWithBlock:^BOOL(id obj) {
        NSURL *expectedURL = [[NSURL alloc] initWithString:mockResponseAPI];

        XCTAssertTrue([obj isKindOfClass:[NSURL class]]);
        XCTAssert([(NSURL *)obj isEqual:expectedURL]);

        return YES;
    }]]);

    // When
    [self.middleware handleReceivedAPNSPayload:mockDictionary];

    // Then
    OCMVerifyAll(mockMiddlewareRequestOperationManager);

    [mockMiddlewareRequestOperationManager stopMocking];
}

@end
