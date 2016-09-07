//
//  ColorConfiguration.m
//  Copyright © 2016 VoIPGRID. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "ColorConfiguration.h"

static NSString * const PrimaryColorDictKey = @"Primary colors";
static NSString * const TintColorDictKey = @"Tint colors";


@interface ColorConfigurationTests : XCTestCase
@end

@interface ColorConfiguration ()
@property (strong, nonatomic) NSDictionary *primaryColorsDictionary;
- (UIColor *)primaryColorForKey:(NSString *)key;
@end

@implementation ColorConfigurationTests

- (void)testColorCreationFromDict {
    // Given
    NSNumber *r = @150;
    NSNumber *g = @200;
    NSNumber *b = @250;


    NSArray *colorArray = [NSArray arrayWithObjects:r, g, b, nil];
    NSString *testColorName = @"test Color";

    NSDictionary *testPrimaryColorDict = @{testColorName : colorArray};

    ColorConfiguration *testColorConfiguration = [[ColorConfiguration alloc] initWithConfigPlist:@{}];
    testColorConfiguration.primaryColorsDictionary = testPrimaryColorDict;

    // When
    UIColor *returnedColor = [testColorConfiguration primaryColorForKey:testColorName];

    // Then
    UIColor *expectedColor = [UIColor colorWithRed:r.doubleValue/255 green:g.doubleValue/255 blue:b.doubleValue/255 alpha:1];
    XCTAssertTrue(CGColorEqualToColor(returnedColor.CGColor, expectedColor.CGColor), @"Colors should have been equal");
}

- (void)testColorCreationFromDictWithAlpha {
    // Given
    NSNumber *r = @150;
    NSNumber *g = @200;
    NSNumber *b = @250;
    NSNumber *alpha = @.5;


    NSArray *colorArray = [NSArray arrayWithObjects:r, g, b, alpha ,nil];
    NSString *testColorName = @"test Color";

    NSDictionary *testPrimaryColorDict = @{testColorName : colorArray};

    ColorConfiguration *testColorConfiguration = [[ColorConfiguration alloc] initWithConfigPlist:@{}];
    testColorConfiguration.primaryColorsDictionary = testPrimaryColorDict;

    // When
    UIColor *returnedColor = [testColorConfiguration primaryColorForKey:testColorName];

    // Then
    UIColor *expectedColor = [UIColor colorWithRed:r.doubleValue/255 green:g.doubleValue/255 blue:b.doubleValue/255 alpha:alpha.doubleValue];
    XCTAssertTrue(CGColorEqualToColor(returnedColor.CGColor, expectedColor.CGColor), @"Colors should have been equal");
}

- (void)testKeyReferencingAPrimaryColorReturnsColor {
    // Given
    NSNumber *r = @150;
    NSNumber *g = @200;
    NSNumber *b = @250;

    NSString *primaryColorEntryName = @"some color";
    NSArray *primaryColorEntryArray = [NSArray arrayWithObjects:r, g, b ,nil];
    NSDictionary *primaryColorDict = @{primaryColorEntryName : primaryColorEntryArray};

    NSString *tintTestColorEntryName = @"test Color";
    NSString *tintTestColorEntryReferencingPrimary = primaryColorEntryName;
    NSDictionary *tintColorsDict = @{tintTestColorEntryName : tintTestColorEntryReferencingPrimary};

    NSDictionary *configPlist = @{PrimaryColorDictKey : primaryColorDict,
                                  TintColorDictKey : tintColorsDict};

    // When
    ColorConfiguration *testColorConfiguration = [[ColorConfiguration alloc] initWithConfigPlist:configPlist];
    UIColor *returnedColor= [testColorConfiguration colorForKey:tintTestColorEntryName];

    // Then
    UIColor *expectedColor = [UIColor colorWithRed:r.doubleValue/255 green:g.doubleValue/255 blue:b.doubleValue/255 alpha:1.f];
    XCTAssertTrue(CGColorEqualToColor(returnedColor.CGColor, expectedColor.CGColor), @"Colors should have been equal");
}

- (void)testConfigurationCannotCreateColorFromWrongDictWithToSmallArray {
    // Given
    NSString *tintColorEntryName = @"some color";

    NSDictionary *configPlist = @{PrimaryColorDictKey : @{},
                                  TintColorDictKey : @{tintColorEntryName : @[@255, @255]}
                                  };
    // When
    ColorConfiguration *testColorConfiguration = [[ColorConfiguration alloc] initWithConfigPlist:configPlist];

    // Then
    XCTAssertThrows([testColorConfiguration colorForKey:tintColorEntryName], @"Should not be able to create a color from 2 items.");
}

- (NSString *)colorAsString:(UIColor *)color {
    const CGFloat *colorComponents = CGColorGetComponents(color.CGColor);
    return [NSString stringWithFormat:@"r:%f - g:%f - b:%f", colorComponents[0], colorComponents[1], colorComponents[2]];
}

@end
