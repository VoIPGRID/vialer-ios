//
//  Configuration.h
//  Copyright © 2015 VoIPGRID. All rights reserved.
//

@import UIKit;
#import "ColorConfiguration.h"

// The Google Analytics custom dimension keys
extern NSString * const _Nonnull ConfigurationGADimensionClientIDIndex;
extern NSString * const _Nonnull ConfigurationGADimensionBuildIndex;

/**
 *  Class for accessing items from Config.plist. As a default the plist from the main bundle is used.
 */
@interface Configuration : NSObject
//@property (readonly, nonatomic) ColorConfiguration * _Nonnull colorConfiguration;
/**
 * Obtain an instance to this class' Singleton.
 *
 * @return Configuration's singleton instance.
 */
+ (instancetype _Nonnull)defaultConfiguration;

@end
