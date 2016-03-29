//
//  RecentCall+VoIPGRIDTests.m
//  Copyright © 2016 VoIPGRID. All rights reserved.
//

#import <OCMock/OCMock.h>
#import "RecentCall+VoIPGRID.h"
@import XCTest;

@interface RecentCall_VoIPGRIDTests : XCTestCase
@property (strong, nonatomic) id mockManagedObjectContext;
@property (strong, nonatomic) id mockEntityDescription;
@end

@implementation RecentCall_VoIPGRIDTests

- (void)setUp {
    [super setUp];
    self.mockManagedObjectContext = OCMClassMock([NSManagedObjectContext class]);
    self.mockEntityDescription = OCMClassMock([NSEntityDescription class]);
    OCMStub([self.mockEntityDescription entityForName:[OCMArg any] inManagedObjectContext:[OCMArg any]]).andReturn(self.mockEntityDescription);
}

- (void)tearDown {
    [self.mockManagedObjectContext stopMocking];
    self.mockManagedObjectContext = nil;
    [self.mockEntityDescription stopMocking];
    self.mockEntityDescription = nil;
    [super tearDown];
}

- (void)testCreateRecentCallsFromVoIPGRIDResponseDataWillAskForExistingRecentCall {
    id recentCallMock = OCMClassMock([RecentCall class]);

    OCMExpect([recentCallMock createRecentCallFromVoIPGRIDDictionary:[OCMArg isEqual:@{@"testKey" : @"testValue"}] inManagedObjectContext:[OCMArg isEqual:self.mockManagedObjectContext]]);

    [RecentCall createRecentCallsFromVoIGPRIDResponseData:@{@"objects":@[@{@"testKey": @"testValue"}]} inManagedObjectContext:self.mockManagedObjectContext];
    OCMVerifyAll(recentCallMock);

    [recentCallMock stopMocking];
}

- (void)testCreateRecentCallsFromVoIPGRIDResponseDataWillAskForCreatingRecentCall {
    id recentCallMock = OCMClassMock([RecentCall class]);

    OCMExpect([recentCallMock createRecentCallFromVoIPGRIDDictionary:[OCMArg isEqual:@{@"testKey" : @"testValue"}] inManagedObjectContext:[OCMArg isEqual:self.mockManagedObjectContext]]);
    [RecentCall createRecentCallsFromVoIGPRIDResponseData:@{@"objects":@[@{@"testKey": @"testValue"}]} inManagedObjectContext:self.mockManagedObjectContext];

    OCMVerifyAll(recentCallMock);
    [recentCallMock stopMocking];
}

- (void)testReturningNewRecentCallsWillReturnRecentCall {
    id recentCallMock = OCMClassMock([RecentCall class]);

    OCMStub([recentCallMock sourceNumber]).andReturn(nil);

    OCMStub([recentCallMock createRecentCallFromVoIPGRIDDictionary:[OCMArg any] inManagedObjectContext:[OCMArg isEqual:self.mockManagedObjectContext]]).andReturn(recentCallMock);

    NSArray *recents = [RecentCall createRecentCallsFromVoIGPRIDResponseData:@{@"objects":@[@{@"testKey": @"testValue"}]} inManagedObjectContext:self.mockManagedObjectContext];

    XCTAssertTrue(recents.count == 1, @"There should be 1 RecentCall");
    XCTAssertEqualObjects(recents[0], recentCallMock, @"The correct RecentCall should be returned.");

    [recentCallMock stopMocking];
}
@end
