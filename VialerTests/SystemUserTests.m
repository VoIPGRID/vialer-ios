//
//  SystemUserTests.m
//  Copyright © 2015 VoIPGRID. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "SystemUser.h"

@interface SystemUserTests : XCTestCase

@end

@interface SystemUser()
+ (void)persistObject:(id)object forKey:(id)key;
+ (id)readObjectForKey:(id)key;
@end

@implementation SystemUserTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testWriteReadSuccess {
    //Given
    NSString *key = @"testKey1";
    NSString *object = @"testValue1";
    //When
    [SystemUser persistObject:object forKey:key];
    //Then
    XCTAssertEqual([SystemUser readObjectForKey:key], object);
}

- (void)testWrtieReadNilValue {
    //Given
    NSString *key = @"testKey1";
    id object = nil;
    //When
    [SystemUser persistObject:object forKey:key];
    //Then
    XCTAssertNil([SystemUser readObjectForKey:key]);
}

- (void)testWriteReadNSNullInstance {
    //Given
    NSString *key = @"testKey1";
    id object = [NSNull null];
    //When
    [SystemUser persistObject:object forKey:key];
    //Then
    XCTAssertNil([SystemUser readObjectForKey:key]);
}


@end
