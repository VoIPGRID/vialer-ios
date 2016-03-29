//
//  Configuration.m
//  Copyright © 2015 VoIPGRID. All rights reserved.
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
NSString * const ConfigurationSideMenuButtonPressedState = @"SideMenuButtonPressedState";
NSString * const ConfigurationRecentsSegmentedControlTintColor = @"RecentsSegmentedControlTintColor";
NSString * const ConfigurationContactsTableSectionIndexColor = @"ContactsTableSectionIndexColor";
NSString * const ConfigurationNumberPadButtonTextColor = @"NumberPadButtonTextColor";
NSString * const ConfigurationNumberPadButtonPressedColor = @"NumberPadButtonPressedColor";
NSString * const ConfigurationRecentsFilterControlTintColor = @"RecentsFilterControlTintColor";
NSString * const ConfigurationLogInViewControllerButtonBorderColor = @"LogInViewControllerButtonBorderColor";
NSString * const ConfigurationLogInViewControllerButtonBackgroundColorForPressedState = @"LogInViewControllerButtonBackgroundColorForPressedState";
NSString * const ConfigurationActivateSIPAccountViewControllerButtonBorderColor = @"ActivateSIPAccountViewControllerButtonBorderColor";
NSString * const ConfigurationActivateSIPAccountViewControllerButtonBackgroundColorForPressedState = @"ActivateSIPAccountViewControllerButtonBackgroundColorForPressedState";
NSString * const ConfigurationVoIPGRIDBaseURLString = @"API";
NSString * const ConfigurationMiddleWareBaseURLString = @"Middelware BaseLink";

NSString * const ConfigurationPartnerURLKey = @"Partner";

static NSString * const ConfigurationColorsKey = @"Tint colors";
static NSString * const ConfigurationUrlsKey = @"URLS";

@interface Configuration ()
@property (strong, nonatomic) NSDictionary *dictionary;
@end

@implementation Configuration

#pragma mark - Initialization methods

// To make the singleton pattern testable.
static Configuration *_defaultConfiguration = nil;
static dispatch_once_t onceToken = 0;

#pragma mark - Lifecycle
+ (instancetype)defaultConfiguration {
    dispatch_once(&onceToken, ^{
        _defaultConfiguration = [[self alloc] init];
    });
    return _defaultConfiguration;
}

+ (void)setDefaultConfiguration:(Configuration *)defaultConfiguration {
    if (_defaultConfiguration != defaultConfiguration) {
        _defaultConfiguration = defaultConfiguration;

        if (!_defaultConfiguration) {
            onceToken = 0;
        } else {
            onceToken = -1;
        }
    }
}


- (NSDictionary *)dictionary {
    if (!_dictionary) {
        _dictionary = [NSDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"Config" ofType:@"plist"]];
        NSAssert(_dictionary, @"Config.plist not found!");
    }
    return _dictionary;
}

#pragma mark - Public instance methods

- (UIColor *)tintColorForKey:(NSString *)key {
    NSArray *color = self.dictionary[ConfigurationColorsKey][key];
    NSAssert(color != nil && color.count == 3 || color.count == 4, @"%@ - %@ not found in Config.plist!", ConfigurationColorsKey, key);
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

+ (UIColor *)colorFromArray:(NSArray *)array {
    CGFloat alpha = 1.f;
    if (array.count == 4) {
        alpha = [array[3] doubleValue];
    }
    return [UIColor colorWithRed:[array[0] intValue] / 255.f green:[array[1] intValue] / 255.f blue:[array[2] intValue] / 255.f alpha:alpha];
}

@end
