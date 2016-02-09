//
//  RecentCall+VoIPGRIDTests.m
//  Copyright © 2016 VoIPGRID. All rights reserved.
//

#import <XCTest/XCTest.h>

#import <OCMock/OCMock.h>
#import "RecentCall+VoIPGRID.h"

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

- (void)testCreateRecentCallsFromVoIPGRIDResponseDataWillAskForExistingRecentCall {
    id recentCallMock = OCMClassMock([RecentCall class]);

    [RecentCall createRecentCallsFromVoIGPRIDResponseData:@{@"objects":@[@{@"testKey": @"testValue"}]} inManagedObjectContext:self.mockManagedObjectContext];

    OCMVerify([recentCallMock createRecentCallFromVoIPGRIDDictionary:[OCMArg isEqual:@{@"testKey" : @"testValue"}] inManagedObjectContext:[OCMArg isEqual:self.mockManagedObjectContext]]);
}

- (void)testCreateRecentCallsFromVoIPGRIDResponseDataWillAskForCreatingRecentCall {
    id recentCallMock = OCMClassMock([RecentCall class]);

    [RecentCall createRecentCallsFromVoIGPRIDResponseData:@{@"objects":@[@{@"testKey": @"testValue"}]} inManagedObjectContext:self.mockManagedObjectContext];

    OCMVerify([recentCallMock createRecentCallFromVoIPGRIDDictionary:[OCMArg isEqual:@{@"testKey" : @"testValue"}] inManagedObjectContext:[OCMArg isEqual:self.mockManagedObjectContext]]);
}

- (void)testReturningNewRecentCallsWillReturnRecentCall {
    id recentCallMock = OCMClassMock([RecentCall class]);

    OCMStub([recentCallMock sourceNumber]).andReturn(nil);

    OCMStub([recentCallMock createRecentCallFromVoIPGRIDDictionary:[OCMArg any] inManagedObjectContext:[OCMArg isEqual:self.mockManagedObjectContext]]).andReturn(recentCallMock);

    NSArray *recents = [RecentCall createRecentCallsFromVoIGPRIDResponseData:@{@"objects":@[@{@"testKey": @"testValue"}]} inManagedObjectContext:self.mockManagedObjectContext];

    XCTAssertTrue(recents.count == 1, @"There should be 1 RecentCall");

    XCTAssertEqualObjects(recents[0], recentCallMock, @"The correct RecentCall should be returned.");
}
@end
