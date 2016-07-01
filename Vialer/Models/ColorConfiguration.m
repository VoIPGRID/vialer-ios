//
//  ColorConfiguration.m
//  Copyright © 2016 VoIPGRID. All rights reserved.
//

#import "ColorConfiguration.h"

static NSString * const PrimaryColorDictKey = @"Primary colors";
static NSString * const TintColorDictKey = @"Tint colors";

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

NSString * const ConfigurationBackgroundGradientStartColor = @"BackgroundGradientStartColor";
NSString * const ConfigurationBackgroundGradientEndColor = @"BackgroundGradientEndColor";
CGFloat const ConfigurationBackgroundGradientAngle = 300;

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
NSString * const ConfigurationSideMenuHeaderBackgroundColor = @"SideMenuHeaderBackgroundColor";

@interface ColorConfiguration ()
@property (strong, nonatomic) NSDictionary *configPlist;
@property (strong, nonatomic) NSDictionary *tintColorsDictionary;
@property (strong, nonatomic) NSDictionary *primaryColorsDictionary;
@end

@implementation ColorConfiguration

- (instancetype)initWithConfigPlist:(NSDictionary *)configPlist {
    self = [super init];
    if (self) {
        self.configPlist = configPlist;
    }
    return self;
}

- (NSDictionary *)primaryColorsDictionary {
    if (!_primaryColorsDictionary) {
        _primaryColorsDictionary = self.configPlist[PrimaryColorDictKey];
        NSAssert(_primaryColorsDictionary, @"Could not find Primary colors dictionary in plist");
    }
    return _primaryColorsDictionary;
}

- (NSDictionary *)tintColorsDictionary {
    if (! _tintColorsDictionary) {
        _tintColorsDictionary = self.configPlist[TintColorDictKey];
        NSAssert(_tintColorsDictionary, @"Could not find Tint colors dictionary in plist");
    }
    return _tintColorsDictionary;
}

/**
 *  Given a key for a primary color a UIColor will be returned
 *
 *  @param key A primary color
 *
 *  @return An UIColor
 */
- (UIColor *)primaryColorForKey:(NSString *)key {
    NSArray *colorArray = self.primaryColorsDictionary[key];
    NSAssert(colorArray.count == 3 || colorArray.count == 4, @"Primary color for key; %@ should have 3 or 4 values", key);

    return [self colorFromArray:colorArray];
}

/**
 *  Given an array of RGB values the function returns an UIColor.
 *
 *  @param array An NSArray containing 3 values for RGB an on optional value for Alpha.
 *
 *  @return An UIColor representing the given RGB(a) values
 */
- (UIColor *)colorFromArray:(NSArray <NSNumber *> *)array {
    NSAssert(array.count == 3 || array.count == 4, @"A color array should have 3 or 4 entries");
    CGFloat alpha = 1.f;
    if (array.count == 4) {
        alpha = [array[3] doubleValue];
    }
    return [UIColor colorWithRed:array[0].doubleValue / 255
                           green:array[1].doubleValue / 255
                            blue:array[2].doubleValue / 255
                           alpha:alpha];
}

- (UIColor *)colorForKey:(NSString *)key {
    id color = self.tintColorsDictionary[key];

    if ([color isKindOfClass:[NSString class]]) {
        return [self primaryColorForKey:(NSString *)color];

    } else if ([color isKindOfClass:[NSArray class]]) {
        return [self colorFromArray:(NSArray *)color];

    } else {
        NSAssert(color, @"No color found for key %@", key);
        return nil;
    }
}

@end
