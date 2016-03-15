//
//  ConfigurationTests.m
//  Copyright © 2015 VoIPGRID. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "Configuration.h"

@interface Configuration ()
@property (strong, nonatomic) NSDictionary *dictionary;
+ (void)setDefaultConfiguration:(Configuration *)defaultConfiguration;
@end

@interface ConfigurationTests : XCTestCase
@property (nonatomic) Configuration *configuration;
@end

@implementation ConfigurationTests

- (void)setUp {
    [super setUp];
    self.configuration = [[Configuration alloc] init];
}

- (void)tearDown {
    self.configuration = nil;
    [super tearDown];
}

- (void)testDefaultConfigurationCanBeInitialised {
    XCTAssert([[Configuration defaultConfiguration] isKindOfClass:[Configuration class]], @"There should be a default configuration");
    [Configuration setDefaultConfiguration:nil];
}


- (void)testConfigurationCannotCreateColorFromWrongDictWithToSmallArray {
    NSDictionary *dict = @{@"Tint colors":
                               @{@"test Color": @[@255, @255]}
                           };
    self.configuration.dictionary = dict;

    XCTAssertThrows([self.configuration tintColorForKey:@"test Color"], @"Should not be able to create a color from 2 items.");
}

- (void)testConfigurationCannotCreateColorFromDictWithToBigArray {
    NSDictionary *dict = @{@"Tint colors":
                               @{@"test Color": @[@255, @255, @255, @255, @1]}
                           };
    self.configuration.dictionary = dict;

    XCTAssertThrows([self.configuration tintColorForKey:@"test Color"], @"Should not be able to create a color from 5 items.");
}

- (void)testConfigurationCanCreateColorWithAlphaOneFromDict {
    NSDictionary *dict = @{@"Tint colors":
                               @{@"test Color": @[@255, @255, @255]}
                           };
    self.configuration.dictionary = dict;
    UIColor *color = [UIColor colorWithRed:255 green:255 blue:255 alpha:1];

    XCTAssertTrue(CGColorEqualToColor([self.configuration tintColorForKey:@"test Color"].CGColor, color.CGColor), @"configuration should be able to create a white color.");
}

- (void)testConfigurationCanCreateColorWithAlphaSetInDict {
    NSDictionary *dict = @{@"Tint colors":
                               @{@"test Color": @[@255,@255,@255, @0.5]}
                           };
    self.configuration.dictionary = dict;
    UIColor *color = [UIColor colorWithRed:255 green:255 blue:255 alpha:0.5];

    XCTAssertTrue(CGColorEqualToColor([self.configuration tintColorForKey:@"test Color"].CGColor, color.CGColor), @"configuration should be able to create a white color with alpha.");
}

@end
