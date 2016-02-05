//
//  APNSHandlerTests.m
//  Copyright © 2016 VoIPGRID. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "APNSHandler.h"
#import <OCMock/OCMock.h>
@import PushKit;

@interface APNSHandler ()
@property (strong, nonatomic) PKPushRegistry *voipRegistry;
@end


@interface APNSHandlerTests : XCTestCase
@property (strong, nonatomic) APNSHandler *apnsHandler;
@end

@implementation APNSHandlerTests

- (void)setUp {
    [super setUp];
    self.apnsHandler = [[APNSHandler alloc] init];
}

- (void)tearDown {
    self.apnsHandler = nil;
    [super tearDown];
}

- (void)testSharedHandlerCreation {
    APNSHandler *createdObject = [APNSHandler sharedHandler];
    XCTAssert([createdObject isKindOfClass:[APNSHandler class]]);

    APNSHandler *createdObject2 = [APNSHandler sharedHandler];
    XCTAssertEqual(createdObject, createdObject2);
}

- (void)testVoIPRegistryCreation {
    //The Assert calls the getter which will lazy load de registry which succeeds the test.
    XCTAssert([self.apnsHandler.voipRegistry isKindOfClass:[PKPushRegistry class]]);
}

- (void)testDidSetPKPushRegistryDelegate {
    //Given
    id pkPushRegistryMock = OCMClassMock([PKPushRegistry class]);
    self.apnsHandler.voipRegistry = pkPushRegistryMock;

    //When
    [self.apnsHandler registerForVoIPNotifications];

    //Then
    OCMVerify([pkPushRegistryMock setDelegate:[OCMArg isEqual:self.apnsHandler]]);
}

- (void)testDidSetDesiredPushTypes {
    //Given
    id pkPushRegistryMock = OCMClassMock([PKPushRegistry class]);
    self.apnsHandler.voipRegistry = pkPushRegistryMock;
    NSSet *desiredTestSet = [NSSet setWithObject:PKPushTypeVoIP];

    //When
    [self.apnsHandler registerForVoIPNotifications];

    //Then
    OCMVerify([pkPushRegistryMock setDesiredPushTypes:[OCMArg isEqual:desiredTestSet]]);
}
@end
