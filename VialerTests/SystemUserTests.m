//
//  SystemUserTests.m
//  Copyright © 2015 VoIPGRID. All rights reserved.
//

#import <OCMock/OCMock.h>
#import <XCTest/XCTest.h>
#import "SystemUser.h"

@interface SystemUserTests : XCTestCase
@property (nonatomic) SystemUser *user;
@end

@interface SystemUser()
+ (void)persistObject:(id)object forKey:(id)key;
+ (id)readObjectForKey:(id)key;
- (instancetype) initPrivate;

@property (strong, nonatomic)NSString *user;
@property (strong, nonatomic)NSString *sipAccount;
@property (strong, nonatomic)NSString *mobileNumber;
@property (strong, nonatomic)NSString *emailAddress;
@property (strong, nonatomic)NSString *firstName;
@property (strong, nonatomic)NSString *lastName;

@property (nonatomic)BOOL loggedIn;
@property (nonatomic)BOOL isSipAllowed;

@end

@implementation SystemUserTests

- (void)setUp {
    [super setUp];
    self.user = [[SystemUser alloc] initPrivate];
}

- (void)testWriteReadSuccess {
    //Given
    NSString *key = @"testKey1";
    NSString *object = @"testValue1";
    //When
    [SystemUser persistObject:object forKey:key];
    //Then
    XCTAssertTrue([[SystemUser readObjectForKey:key] isEqualToString:object], @"It should be possible to write and read.");
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

- (void)testSystemUserHasNoDisplayNameOnDefault {
    id userDefaultsMock = OCMClassMock([NSUserDefaults class]);
    OCMStub([userDefaultsMock standardUserDefaults]).andReturn(userDefaultsMock);
    OCMStub([userDefaultsMock objectForKey:[OCMArg any]]).andReturn(nil);

    XCTAssertEqualObjects(self.user.displayName, NSLocalizedString(@"No email address configured", nil), @"it should say there is no display information");

    [userDefaultsMock stopMocking];
}

- (void)testSystemUserDisplaysUser {
    id userDefaultsMock = OCMClassMock([NSUserDefaults class]);
    OCMStub([userDefaultsMock standardUserDefaults]).andReturn(userDefaultsMock);
    OCMStub([userDefaultsMock objectForKey:@"User"]).andReturn(@"john@apple.com");

    XCTAssertEqualObjects(self.user.displayName ,@"john@apple.com", @"the user should be displayed");

    [userDefaultsMock stopMocking];
}

- (void)testSystemUserDisplaysFirstName {
    id userDefaultsMock = OCMClassMock([NSUserDefaults class]);
    OCMStub([userDefaultsMock standardUserDefaults]).andReturn(userDefaultsMock);
    OCMStub([userDefaultsMock objectForKey:@"FirstName"]).andReturn(@"John");
    OCMStub([userDefaultsMock objectForKey:@"User"]).andReturn(@"john@apple.com");

    XCTAssertEqualObjects(self.user.displayName, @"John", @"The firstname should be displayed and not the user");

    [userDefaultsMock stopMocking];
}

- (void)testSystemUserDisplaysLastName {
    id userDefaultsMock = OCMClassMock([NSUserDefaults class]);
    OCMStub([userDefaultsMock standardUserDefaults]).andReturn(userDefaultsMock);
    OCMStub([userDefaultsMock objectForKey:@"LastName"]).andReturn(@"Appleseed");
    OCMStub([userDefaultsMock objectForKey:@"User"]).andReturn(@"john@apple.com");

    XCTAssertEqualObjects(self.user.displayName, @"Appleseed", @"The lastname should be displayed and not the user");

    [userDefaultsMock stopMocking];
}

- (void)testSystemUserDisplaysFirstAndLastName {
    id userDefaultsMock = OCMClassMock([NSUserDefaults class]);
    OCMStub([userDefaultsMock standardUserDefaults]).andReturn(userDefaultsMock);
    OCMStub([userDefaultsMock objectForKey:@"FirstName"]).andReturn(@"John");
    OCMStub([userDefaultsMock objectForKey:@"LastName"]).andReturn(@"Appleseed");
    OCMStub([userDefaultsMock objectForKey:@"User"]).andReturn(@"john@apple.com");

    XCTAssertEqualObjects(self.user.displayName, @"John Appleseed", @"The fullname should be displayed and not the user");

    [userDefaultsMock stopMocking];
}

- (void)testSystemUserDisplaysEmailAddress {
    id userDefaultsMock = OCMClassMock([NSUserDefaults class]);
    OCMStub([userDefaultsMock standardUserDefaults]).andReturn(userDefaultsMock);
    OCMStub([userDefaultsMock objectForKey:@"Email"]).andReturn(@"john@apple.com");
    OCMStub([userDefaultsMock objectForKey:@"User"]).andReturn(@"steve@apple.com");

    XCTAssertEqualObjects(self.user.displayName, @"john@apple.com", @"The emailaddress should be displayed and not the user");

    [userDefaultsMock stopMocking];
}

- (void)testSystemUserDisplaysFirstNameBeforeEmail {
    id userDefaultsMock = OCMClassMock([NSUserDefaults class]);
    OCMStub([userDefaultsMock standardUserDefaults]).andReturn(userDefaultsMock);
    OCMStub([userDefaultsMock objectForKey:@"FirstName"]).andReturn(@"John");
    OCMStub([userDefaultsMock objectForKey:@"Email"]).andReturn(@"john@apple.com");

    XCTAssertEqualObjects(self.user.displayName, @"John", @"The firstname should be displayed and not the emailaddress");

    [userDefaultsMock stopMocking];
}

@end
