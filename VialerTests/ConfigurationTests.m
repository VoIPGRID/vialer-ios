//
//  ConfigurationTests.m
//  Copyright © 2015 VoIPGRID. All rights reserved.
//

#import "Configuration.h"
@import XCTest;

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

@end
