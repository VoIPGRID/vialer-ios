//
//  APNSHandlerTests.m
//  Copyright © 2016 VoIPGRID. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "APNSHandler.h"
#import "Middleware.h"
#import <OCMock/OCMock.h>
@import PushKit;

@interface APNSHandler ()
@property (strong, nonatomic) PKPushRegistry *voipRegistry;
@property (weak, nonatomic) Middleware *middleware;

- (NSString *)nsStringFromNSData:(NSData *)data;
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

- (void)testMiddlewareGetter {
    //The Assert calls the getter which will lazy load de registry which succeeds the test.
    XCTAssert([self.apnsHandler.middleware isKindOfClass:[Middleware class]]);
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

- (void)testReceiptOfAPNSToken {
    //Given
    NSString *tokenString = @"0000000011111111222222223333333344444444555555556666666677777777";
    NSData *mockToken = [self nsDataFromHexString:tokenString];

    id mockCredentials = OCMClassMock([PKPushCredentials class]);
    OCMStub([mockCredentials token]).andReturn(mockToken);

    id mockMiddleware = OCMClassMock([Middleware class]);
    self.apnsHandler.middleware = mockMiddleware;

    //Then
    OCMExpect([mockMiddleware sentAPNSToken:[OCMArg checkWithSelector:@selector(isEqualToString:) onObject:tokenString]]);

    //When
    [self.apnsHandler pushRegistry:nil didUpdatePushCredentials:mockCredentials forType:PKPushTypeVoIP];
    OCMVerifyAll(mockMiddleware);
}

- (void)testRetrievingStoredAPNSToken {
    //Given
    NSString *givenToken = @"0000000011111111222222223333333344444444555555556666666677777777";
    NSData *mockToken = [self nsDataFromHexString:givenToken];

    id pkPushRegistryMock = OCMClassMock([PKPushRegistry class]);
    OCMStub([pkPushRegistryMock pushTokenForType:[OCMArg any]]).andReturn(mockToken);

    //When
    self.apnsHandler.voipRegistry = pkPushRegistryMock;
    NSString *storedToken = [APNSHandler storedAPNSToken];

    //Then
    XCTAssert([givenToken isEqualToString:storedToken], @"Tokens did not match");
}

- (void)testRetrievingStoredAPNSTokenWhenNonSet {
    //Given
    NSData *mockToken = nil;

    id pkPushRegistryMock = OCMClassMock([PKPushRegistry class]);
    OCMStub([pkPushRegistryMock pushTokenForType:[OCMArg any]]).andReturn(mockToken);

    //When
    self.apnsHandler.voipRegistry = pkPushRegistryMock;
    NSString *storedToken = [APNSHandler storedAPNSToken];

    //Then
    XCTAssert(storedToken == nil, @"Tokens did not match");
}

- (void)testHexNSStringToNSDataAndBack {
    //Given
    NSString *hexString = [[@"00001111 22223333 44445555 66667777 88889999 aaAAbbBB ccCCddDD eeEEffFF" stringByReplacingOccurrencesOfString:@" " withString:@""] lowercaseString];

    //When
    NSData *data = [self nsDataFromHexString:hexString];
    NSLog(@"%@", data);
    NSString *returnedString = [self.apnsHandler nsStringFromNSData:data];

    //Then
    XCTAssert([hexString isEqualToString:returnedString], @"Conversion from NSString to NSData and back failed");
}

#pragma mark - Helper functions
/**
 *  Function converts a NSString which represents an APNS token e.g. <00000000 11111111 22222222 ...>
 *  into an NSData object
 *
 *  @param string The NSString representing the APNS token
 *
 *  @return an NSData object which also represents the give APNS token.
 */
- (NSData *)nsDataFromHexString:(NSString *)hexString {
    hexString = [hexString lowercaseString];
    NSMutableData *data= [NSMutableData new];
    unsigned char whole_byte;
    char byte_chars[3] = {'\0','\0','\0'};
    int i = 0;
    NSUInteger length = hexString.length;
    while (i < length-1) {
        char c = [hexString characterAtIndex:i++];
        if (c < '0' || (c > '9' && c < 'a') || c > 'f')
            continue;
        byte_chars[0] = c;
        byte_chars[1] = [hexString characterAtIndex:i++];
        whole_byte = strtol(byte_chars, NULL, 16);
        [data appendBytes:&whole_byte length:1];
    }
    return [[NSData alloc] initWithData:data];
}
@end
