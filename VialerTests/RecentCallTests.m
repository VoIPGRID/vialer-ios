//
//  RecentCallTests.m
//  Copyright © 2016 VoIPGRID. All rights reserved.
//

#import <CoreData/CoreData.h>
#import <OCMock/OCMock.h>
#import "RecentCall.h"
@import XCTest;

@interface RecentCallTests : XCTestCase
@property (strong, nonatomic) NSManagedObjectContext *moc;
@end

@implementation RecentCallTests

- (void)setUp {
    [super setUp];
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"VialerModel" withExtension:@"momd"];
    NSManagedObjectModel *mom = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    NSPersistentStoreCoordinator *psc = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:mom];
    XCTAssertTrue([psc addPersistentStoreWithType:NSInMemoryStoreType configuration:nil URL:nil options:nil error:NULL] ? YES : NO, @"Should be able to add in-memory store");
    self.moc = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
    self.moc.persistentStoreCoordinator = psc;
}

- (void)tearDown {
    self.moc = nil;
    [super tearDown];
}

- (void)testGetLatestCallWillReturnTheCall {
    // Given
    RecentCall *recent = [NSEntityDescription insertNewObjectForEntityForName:@"RecentCall" inManagedObjectContext:self.moc];

    // When
    RecentCall *fetchedRecent = [RecentCall latestCallInManagedObjectContext:self.moc];

    //Then
    XCTAssertEqualObjects(recent, fetchedRecent, @"The correct RecentCall should have been returned");
}

- (void)testLatestCallReturnsNilWhenDatabaseEmpty {
    RecentCall *fetchedRecent = [RecentCall latestCallInManagedObjectContext:self.moc];
    XCTAssertNil(fetchedRecent, @"Database should have been empty, no object should have been returned");
}

- (void)testRecentInboundCallIsSuppressed {
    // Given
    RecentCall *recent = [NSEntityDescription insertNewObjectForEntityForName:@"RecentCall" inManagedObjectContext:self.moc];

    // When
    recent.inbound = @YES;
    recent.sourceNumber = @"+31222xxxxxx";

    // Then
    XCTAssertTrue([recent suppressed], @"The given inbound recent should have indicated that it is suppressed");
}
- (void)testRecentInboundCallButNotASuppressedNumber {
    //Given
    RecentCall *recent = [NSEntityDescription insertNewObjectForEntityForName:@"RecentCall" inManagedObjectContext:self.moc];

    // When
    recent.inbound = @YES;
    recent.sourceNumber = @"+31222333333";

    // Then
    XCTAssertFalse([recent suppressed], @"The given inbound recent should NOT indicated as being suppressed");
}

- (void)testRecentOuboundCallCannotIndicateBeingSuppressed {
    // Given
    RecentCall *recent = [NSEntityDescription insertNewObjectForEntityForName:@"RecentCall" inManagedObjectContext:self.moc];

    // When
    recent.inbound = @NO;
    recent.sourceNumber = @"+31222xxxxxx";

    // Then
    XCTAssertFalse([recent suppressed], @"An outbound call can never indicate as being suppressed.");
}

- (void)testRecentInboundCallIsNotSuppressed {
    // Given
    RecentCall *recent = [NSEntityDescription insertNewObjectForEntityForName:@"RecentCall" inManagedObjectContext:self.moc];

    // When
    recent.inbound = @NO;
    recent.sourceNumber = @"+31222333333";

    // Then
    XCTAssertFalse([recent suppressed], @"The given recents should not indicate that it is suppressed");
}

@end
