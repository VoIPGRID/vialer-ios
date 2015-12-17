//
//  ContactUtilsTests.m
//  Vialer
//
//  Created by Redmer Loen on 04-01-16.
//  Copyright © 2016 VoIPGRID. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "ContactUtils.h"
#import <OCMock/OCMock.h>

@interface ContactUtilsTests : XCTestCase
@property (strong, nonatomic) CNMutableContact *contact;
@end

@implementation ContactUtilsTests

- (void)setUp {
    [super setUp];
    self.contact = [[CNMutableContact alloc] init];

    self.contact.givenName = @"John";
    self.contact.familyName = @"Appleseed";
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testFamilyNameIsBoldForContact {
    // Given
    NSString *fullName = [CNContactFormatter stringFromContact:self.contact style:CNContactFormatterStyleFullName];
    NSMutableAttributedString *fullNameAttrString = [[NSMutableAttributedString alloc] initWithString: fullName];
    NSRange boldedRange = NSMakeRange(0, self.contact.givenName.length);

    [fullNameAttrString addAttribute:NSFontAttributeName
                               value:[UIFont fontWithName:@"HelveticaNeue-Bold" size:17.0]
                               range:boldedRange];

    NSMutableAttributedString *string = [ContactUtils getFormattedStyledContact:self.contact];

    // Then
    XCTAssertEqualObjects(string, fullNameAttrString);
}

- (void)testGivenNameIsBoldWithoutLastNameForContact {
    // Given
    self.contact.familyName = @"";
    NSString *fullName = [CNContactFormatter stringFromContact:self.contact style:CNContactFormatterStyleFullName];
    NSMutableAttributedString *fullNameAttrString = [[NSMutableAttributedString alloc] initWithString: fullName];
    NSRange boldedRange = NSMakeRange(0, self.contact.givenName.length);

    [fullNameAttrString addAttribute:NSFontAttributeName
                               value:[UIFont fontWithName:@"HelveticaNeue-Bold" size:17.0]
                               range:boldedRange];

    NSMutableAttributedString *contactUtilsString = [ContactUtils getFormattedStyledContact:self.contact];

    // Then
    XCTAssertEqualObjects(contactUtilsString, fullNameAttrString);
}

- (void)testContactAttributedStringWhenThereIsNoFullName {
    // Given
    NSString *emailAddress = @"john@appleseed.com";
    CNMutableContact *contact = [[CNMutableContact alloc] init];
    contact.emailAddresses = @[[[CNLabeledValue alloc] initWithLabel:CNLabelHome value:emailAddress]];

    NSMutableAttributedString *stringToCompareTo = [[NSMutableAttributedString alloc] initWithString:emailAddress];
    NSMutableAttributedString *contactUtilsString = [ContactUtils getFormattedStyledContact:contact];

    // Then
    XCTAssertEqualObjects(contactUtilsString, stringToCompareTo);
}

- (void)testFamilyNameIsFirstAndBoldFamilyName {
    // Given
    id classMock = OCMClassMock([CNContactFormatter class]);
    OCMStub([classMock nameOrderForContact:[OCMArg any]]).andReturn(CNContactDisplayNameOrderFamilyNameFirst);
    OCMStub([classMock stringFromContact:[OCMArg any] style:CNContactFormatterStyleFullName]).andReturn(@"Appleseed John");

    NSString *fullName = [CNContactFormatter stringFromContact:self.contact style:CNContactFormatterStyleFullName];
    NSMutableAttributedString *fullNameAttrString = [[NSMutableAttributedString alloc] initWithString: fullName];
    NSRange boldedRange = NSMakeRange(0, self.contact.familyName.length);

    [fullNameAttrString addAttribute:NSFontAttributeName
                               value:[UIFont fontWithName:@"HelveticaNeue-Bold" size:17.0]
                               range:boldedRange];

    NSMutableAttributedString *string = [ContactUtils getFormattedStyledContact:self.contact];

    // Then
    XCTAssertEqualObjects(string, fullNameAttrString);
    [classMock stopMocking];
}

- (void)testFamilyNameIsFirstAndBoldGivenName {
    // Given
    self.contact.familyName = @"";
    id classMock = OCMClassMock([CNContactFormatter class]);
    OCMStub([classMock nameOrderForContact:[OCMArg any]]).andReturn(CNContactDisplayNameOrderFamilyNameFirst);

    NSString *fullName = [CNContactFormatter stringFromContact:self.contact style:CNContactFormatterStyleFullName];
    NSMutableAttributedString *fullNameAttrString = [[NSMutableAttributedString alloc] initWithString: fullName];
    NSRange boldedRange = NSMakeRange(0, self.contact.givenName.length);

    [fullNameAttrString addAttribute:NSFontAttributeName
                               value:[UIFont fontWithName:@"HelveticaNeue-Bold" size:17.0]
                               range:boldedRange];

    NSMutableAttributedString *string = [ContactUtils getFormattedStyledContact:self.contact];

    // Then
    XCTAssertEqualObjects(string, fullNameAttrString);
    [classMock stopMocking];
}

- (void)testBoldedLengthGreaterThenFullName {
    id classMock = OCMClassMock([CNContactFormatter class]);
    OCMStub([classMock stringFromContact:[OCMArg any] style:CNContactFormatterStyleFullName]).andReturn(@"J A");

    NSMutableAttributedString *fullNameAttrString = [[NSMutableAttributedString alloc] initWithString: @"J A"];
    NSRange boldedRange = NSMakeRange(0, 3);

    [fullNameAttrString addAttribute:NSFontAttributeName
                               value:[UIFont fontWithName:@"HelveticaNeue-Bold" size:17.0]
                               range:boldedRange];


    NSMutableAttributedString *string = [ContactUtils getFormattedStyledContact:self.contact];

    // Then
    XCTAssertEqualObjects(string, fullNameAttrString);
    [classMock stopMocking];
}

@end
