//
//  RoundedAndColoredUIButtonTests.m
//  Copyright © 2015 VoIPGRID. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "RoundedAndColoredUIButton.h"

@interface RoundedAndColoredUIButtonTests : XCTestCase
@property (nonatomic) RoundedAndColoredUIButton *button;
@end

@implementation RoundedAndColoredUIButtonTests

- (void)setUp {
    [super setUp];
    self.button = [[RoundedAndColoredUIButton alloc] init];
}

- (void)tearDown {
    self.button = nil;
    [super tearDown];
}

- (void)testCanSetCornerRadius {
    XCTAssertNoThrow(self.button.cornerRadius = 1, @"It should be possible to set the corner radius.");
}

- (void)testCornerRadiusIsSet {
    XCTAssertEqual(self.button.layer.cornerRadius, 0, @"There should be no radius set on default");
    self.button.cornerRadius = 1;
    XCTAssertEqual(self.button.layer.cornerRadius, 1, @"the proper radius should have been set");
}

- (void)testCanSetBorderWidth {
    XCTAssertNoThrow(self.button.borderWidth = 1, @"It should be possible to set the border width.");
}

- (void)testBorderWidthIsSet {
    XCTAssertEqual(self.button.layer.borderWidth, 0, @"There should be no border set on default");
    self.button.borderWidth = 1;
    XCTAssertEqual(self.button.layer.borderWidth, 1, @"the proper border width should have been set");
}

- (void)testCanSetBorderColor {
    XCTAssertNoThrow(self.button.borderColor = [UIColor whiteColor], @"It should be possible to set the border color.");
}

- (void)testBorderColorIsSet {
    UIColor *color = [UIColor whiteColor];
    self.button.borderColor = color;
    XCTAssertEqual(self.button.layer.borderColor, color.CGColor, @"the proper color should have been set");
}

- (void)testCanSetBackgroundColorForPressedState {
    XCTAssertNoThrow(self.button.backgroundColorForPressedState = [UIColor whiteColor], @"It should be possible to set the background color in pressed state.");
}

- (void)testWhenButtonNotPressedThereShouldBeNoBackground {
    XCTAssertNil(self.button.backgroundColor, @"There should be no background Color when not pressed");
}

- (void)testWhenButtonPressedThereShouldBeABackground {
    UIColor *color = [UIColor whiteColor];
    self.button.backgroundColorForPressedState = color;
    self.button.highlighted = YES;
    XCTAssertEqualObjects(self.button.backgroundColor, color, @"There should be a background color when button pressed");
}

@end
