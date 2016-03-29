//
//  RecentCallTests.m
//  Copyright © 2016 VoIPGRID. All rights reserved.
//

#import <CoreData/CoreData.h>
#import <OCMock/OCMock.h>
#import "RecentCall.h"
@import XCTest;

@interface RecentCallTests : XCTestCase
@property (strong, nonatomic) id mockManagedObjectContext;
@property (strong, nonatomic) id mockEntityDescription;
@end

@implementation RecentCallTests

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

- (void)testGetLatestCallWillTryToFetchFromManagedObjectContext {
    OCMExpect([self.mockManagedObjectContext executeFetchRequest:[OCMArg checkWithBlock:^BOOL(NSFetchRequest *fetchRequest) {

        XCTAssertEqual(fetchRequest.sortDescriptors.count, 1, @"There should be one sort descriptor.");

        NSSortDescriptor *sort = fetchRequest.sortDescriptors[0];
        XCTAssertEqualObjects(sort.key, @"callDate", @"The sorting should take place on the callDate.");
        XCTAssertFalse(sort.ascending, @"Sorting should be descending.");
        XCTAssertEqual(fetchRequest.fetchLimit, 1, @"The fetch limit should be 1.");
        return YES;
    }] error:[OCMArg anyObjectRef]]);

    [RecentCall latestCallInManagedObjectContext:self.mockManagedObjectContext];

    OCMVerify([self.mockEntityDescription entityForName:[OCMArg isEqual:@"RecentCall"] inManagedObjectContext:[OCMArg isEqual:self.mockManagedObjectContext]]);

    OCMVerifyAll(self.mockManagedObjectContext);
}

// VIALI-3154
// rewrite this test, and all other core data test to use a test specific "in memory" database instead of mocking the classes
// For inspiration see: http://stackoverflow.com/a/23988116
- (void)testGetLatestCallWillReturnTheCall {
    RecentCall *recent = [[RecentCall alloc] init];
    OCMStub([self.mockManagedObjectContext executeFetchRequest:[OCMArg any] error:[OCMArg anyObjectRef]]).andReturn(@[recent]);

    RecentCall *fetchedRecent = [RecentCall latestCallInManagedObjectContext:self.mockManagedObjectContext];

    XCTAssertEqualObjects(recent, fetchedRecent, @"The correct RecentCall should have been returned");
}

- (void)testGetLatestCallWillReturnNil {
    OCMStub([self.mockManagedObjectContext executeFetchRequest:[OCMArg any] error:[OCMArg anyObjectRef]]).andReturn(nil);

    RecentCall *fetchedRecent = [RecentCall latestCallInManagedObjectContext:self.mockManagedObjectContext];

    XCTAssertNil(fetchedRecent, @"The correct RecentCall should have been returned");
}

- (void)testErrorFetchingWillReturnNil {
    NSError *mockError = [NSError errorWithDomain:@"test" code:0 userInfo:nil];
    OCMStub([self.mockManagedObjectContext executeFetchRequest:[OCMArg any] error:[OCMArg setTo:mockError]]).andReturn(nil);

    RecentCall *fetchedRecent = [RecentCall latestCallInManagedObjectContext:self.mockManagedObjectContext];

    XCTAssertNil(fetchedRecent, @"The correct RecentCall should have been returned");
}

@end
