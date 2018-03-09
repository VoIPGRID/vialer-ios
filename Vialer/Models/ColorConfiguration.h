//
//  ColorConfiguration.h
//  Copyright © 2016 VoIPGRID. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString * const _Nonnull ConfigurationTabBarBackgroundColor;
extern NSString * const _Nonnull ConfigurationTabBarTintColor;
extern NSString * const _Nonnull ConfigurationNavigationBarTintColor;
extern NSString * const _Nonnull ConfigurationNavigationBarBarTintColor;
extern NSString * const _Nonnull ConfigurationConfigTextFieldBorderColor;
extern NSString * const _Nonnull ConfigurationAvailabilityTableViewTintColor;
extern NSString * const _Nonnull ConfigurationReachabilityBarBackgroundColor;
extern NSString * const _Nonnull ConfigurationRecentsTableViewTintColor;
extern NSString * const _Nonnull ConfigurationContactSearchBarBarTintColor;
extern NSString * const _Nonnull ConfigurationContactSearchBarTintColor;
extern NSString * const _Nonnull ConfigurationLeftDrawerButtonTintColor;
extern NSString * const _Nonnull ConfigurationTwoStepScreenBackgroundHeaderColor;
extern NSString * const _Nonnull ConfigurationTwoStepScreenInfoBarBackgroundColor;
extern NSString * const _Nonnull ConfigurationTwoStepScreenBubblingColor;
extern NSString * const _Nonnull ConfigurationTwoStepScreenSideAIconColor;
extern NSString * const _Nonnull ConfigurationTwoStepScreenSideBIconColor;
extern NSString * const _Nonnull ConfigurationTwoStepScreenVialerIconColor;

extern NSString * const _Nonnull ConfigurationBackgroundGradientStartColor;
extern NSString * const _Nonnull ConfigurationBackgroundGradientEndColor;
extern CGFloat const ConfigurationBackgroundGradientAngle;

extern NSString * const _Nonnull ConfigurationSideMenuTintColor;
extern NSString * const _Nonnull ConfigurationSideMenuButtonPressedState;
extern NSString * const _Nonnull ConfigurationRecentsSegmentedControlTintColor;
extern NSString * const _Nonnull ConfigurationContactsTableSectionIndexColor;
extern NSString * const _Nonnull ConfigurationNumberPadButtonTextColor;
extern NSString * const _Nonnull ConfigurationNumberPadButtonPressedColor;
extern NSString * const _Nonnull ConfigurationRecentsFilterControlTintColor;
extern NSString * const _Nonnull ConfigurationLogInViewControllerButtonBorderColor;
extern NSString * const _Nonnull ConfigurationLogInViewControllerButtonBackgroundColorForPressedState;
extern NSString * const _Nonnull ConfigurationActivateSIPAccountViewControllerButtonBorderColor;
extern NSString * const _Nonnull ConfigurationActivateSIPAccountViewControllerButtonBackgroundColorForPressedState;
extern NSString * const _Nonnull ConfigurationSideMenuHeaderBackgroundColor;

/**
 This class represents the color configuration as defined in the Config.plist.
 */
@interface ColorConfiguration : NSObject
/**
 *  This initializer is not to be used.
 */
- (instancetype _Nonnull)init __attribute__((unavailable("init not available")));

/**
 *  This is the designated initializer for this class. Do not use init.
 *
 *  @param configPlist A NSDictionary representing the contents of the Config.plist file.
 *
 *  @return An ColorConfiguration instance.
 */
- (instancetype _Nonnull)initWithConfigPlist:(NSDictionary * _Nonnull)configPlist NS_DESIGNATED_INITIALIZER;

/**
 *  Obtain an UIColor for the key specified.
 *
 *  @param key The key for which to fetch the color.
 *
 *  @return An instance to a UIColor.
 */
- (UIColor * _Nullable)colorForKey:(NSString * _Nonnull)key;

@end
