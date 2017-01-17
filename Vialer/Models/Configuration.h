//
//  Configuration.h
//  Copyright © 2015 VoIPGRID. All rights reserved.
//

@import UIKit;
#import "ColorConfiguration.h"

// Known tint color names
extern NSString * const ConfigurationVoIPGRIDBaseURLString;
extern NSString * const ConfigurationMiddleWareBaseURLString;
extern NSString * const ConfigurationSIPDomain;
extern NSString * const ConfigurationPartnerURLKey;

// The Google Analytics custom dimension keys
extern NSString * const ConfigurationGADimensionClientIDIndex;
extern NSString * const ConfigurationGADimensionBuildIndex;

/**
 *  Class for accessing items from Config.plist. As a default the plist from the main bundle is used.
 */
@interface Configuration : NSObject

@property (readonly, nonatomic) ColorConfiguration *colorConfiguration;
/**
 * Obtain an instance to this class' Singleton.
 *
 * @return Configuration's singleton instance.
 */
+ (instancetype)defaultConfiguration;

/**
 *  Obtain an NSString containing an URL for the given key.
 *
 *  @param key The key for which to fetch the URL.
 *
 *  @return A NSString containing the URL value.
 */
- (NSString *)UrlForKey:(NSString *)key;

/**
 *  Obtain the Google Analytics custom dimension index for the given key.
 *
 *  @param key The key for which to fetch index.
 *
 *  @return An int representing the dimension index.
 */
- (int)customDimensionIndexForKey:(NSString *)key;


/**
 The logEntries token.

 @return NSString with the token.
 */
- (NSString *)logEntriesToken;

@end
