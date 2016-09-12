//
//  ConfigurationTests.m
//  Copyright © 2015 VoIPGRID. All rights reserved.
//

#import "Configuration.h"
@import XCTest;

@interface Configuration ()
@property (strong, nonatomic) NSDictionary *configPlist;
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

- (void)testFetchingACustomDimensionIndex {
    NSString *gaDimensionKey = @"test dimension";
    NSNumber *gaDimensionValue = @56;
    NSDictionary *testConfigPlist = [self createGACustomDimensionPlistWithKey:gaDimensionKey
                                                                     andValue:gaDimensionValue];

    Configuration *testConfiguration = [[Configuration alloc] init];
    testConfiguration.configPlist = testConfigPlist;

    int returnedIndex = [testConfiguration customDimensionIndexForKey:gaDimensionKey];
    NSAssert(returnedIndex == gaDimensionValue.intValue, @"Values should have been equal") ;
}

- (void)testFetchingACustomDimensionIndexThrowsExeptionWhenKeyNotPresent {
    Configuration *testConfiguration = [[Configuration alloc] init];
    testConfiguration.configPlist = @{};

    XCTAssertThrowsSpecificNamed([testConfiguration customDimensionIndexForKey:@"Unknown Key"],
                                 NSException, NSInternalInconsistencyException,
                                 @"Should throw NSInternalInconsistencyException");
}


- (NSDictionary *)createGACustomDimensionPlistWithKey:(NSString *)key andValue:(id)value {
    NSString *customDimensionDictKey = @"GA Custom Dimensions";
    NSDictionary *dimensionDict = @{key : value};
    return @{customDimensionDictKey : dimensionDict};
}

@end
