//
//  Configuration.m
//  Vialer
//
//  Created by Maarten de Zwart on 11/09/15.
//  Copyright (c) 2015 VoIPGRID. All rights reserved.
//

#import "Configuration.h"

/** Key definition for Config file */
NSString * const ConfigurationTabBarBackgroundColor = @"TabBarBackgroundColor";
NSString * const ConfigurationTabBarTintColor = @"TabBarTintColor";
NSString * const ConfigurationNavigationBarTintColor = @"NavigationBarTintColor";
NSString * const ConfigurationNavigationBarBarTintColor = @"NavigationBarBarTintColor";
NSString * const ConfigurationConfigTextFieldBorderColor = @"ConfigTextFieldBorderColor";
NSString * const ConfigurationAvailabilityTableViewTintColor = @"AvailabilityTableViewTintColor";
NSString * const ConfigurationReachabilityBarBackgroundColor = @"ReachabilityBarBackgroundColor";
NSString * const ConfigurationRecentsTableViewTintColor = @"RecentsTableViewTintColor";
NSString * const ConfigurationContactSearchBarBarTintColor = @"ContactSearchBarBarTintColor";
NSString * const ConfigurationContactSearchBarTintColor = @"ContactSearchBarTintColor";
NSString * const ConfigurationLeftDrawerButtonTintColor = @"LeftDrawerButtonTintColor";
NSString * const ConfigurationTwoStepScreenBackgroundHeaderColor = @"TwoStepScreenBackgroundHeaderColor";
NSString * const ConfigurationTwoStepScreenInfoBarBackgroundColor = @"TwoStepScreenInfoBarBackgroundColor";
NSString * const ConfigurationTwoStepScreenBubblingColor = @"TwoStepScreenBubblingColor";
NSString * const ConfigurationTwoStepScreenSideAIconColor = @"TwoStepScreenSideAIconColor";
NSString * const ConfigurationTwoStepScreenSideBIconColor = @"TwoStepScreenSideBIconColor";
NSString * const ConfigurationTwoStepScreenVialerIconColor = @"TwoStepScreenVialerIconColor";
NSString * const ConfigurationGradientBackgroundColors = @"GradientBackgroundColors";
NSString * const ConfigurationGradientViewGradientStart = @"GradientStart";
NSString * const ConfigurationGradientViewGradientEnd = @"GradientEnd";
NSString * const ConfigurationGradientViewGradientAngle = @"GradientAngle";
NSString * const ConfigurationSideMenuTintColor = @"SideMenuTintColor";
NSString * const ConfigurationRecentsSegmentedControlTintColor = @"RecentsSegmentedControlTintColor";
NSString * const ConfigurationContactsTableSectionIndexColor = @"ContactsTableSectionIndexColor";
NSString * const ConfigurationNumberPadButtonTextColor = @"NumberPadButtonTextColor";
NSString * const ConfigurationNumberPadButtonPressedColor = @"NumberPadButtonPressedColor";

static NSString * const ConfigurationColorsKey = @"Tint colors";
static NSString * const ConfigurationUrlsKey = @"URLS";

@interface Configuration ()
@property (nonatomic, strong) NSDictionary *dictionary;
@end

@implementation Configuration

#pragma mark - Initialization methods

+ (instancetype)defaultConfiguration {
    static Configuration *configuration;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        configuration = [[Configuration alloc] init];
    });
    return configuration;
}

- (NSDictionary *)dictionary {
    if (!_dictionary) {
        _dictionary = [NSDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"Config" ofType:@"plist"]];
        NSAssert(_dictionary != nil, @"Config.plist not found!");
    }
    return _dictionary;
}

#pragma mark - Public instance methods

- (UIColor *)tintColorForKey:(NSString *)key {
    NSArray *color = self.dictionary[ConfigurationColorsKey][key];
    NSAssert(color != nil && color.count == 3, @"%@ - %@ not found in Config.plist!", ConfigurationColorsKey, key);
    return [[self class] colorFromArray:color];
}

- (NSDictionary *)tintColorDictionaryForKey:(NSString *)key {
    NSDictionary *colors = self.dictionary[ConfigurationColorsKey];
    return colors[key];
}

- (NSString *)UrlForKey:(NSString *)key {
    NSString *urlString = self.dictionary[ConfigurationUrlsKey][key];
    NSAssert(urlString != nil, @"%@ - %@, not found in Config.plist!", ConfigurationUrlsKey, key);
    return urlString;
}

#pragma mark - Public static methods

+ (UIColor *)tintColorForKey:(NSString *)key {
    return [[Configuration defaultConfiguration] tintColorForKey:key];
}

+ (NSDictionary *)tintColorDictionaryForKey:(NSString *)key {
    return [[Configuration defaultConfiguration] tintColorDictionaryForKey:key];
}

+ (NSString *)UrlForKey:(NSString *)key {
    return [[Configuration defaultConfiguration] UrlForKey:key];
}

+ (UIColor *)colorFromArray:(NSArray *)array {
    return [UIColor colorWithRed:[array[0] intValue] / 255.f green:[array[1] intValue] / 255.f blue:[array[2] intValue] / 255.f alpha:1.f];
}

@end
