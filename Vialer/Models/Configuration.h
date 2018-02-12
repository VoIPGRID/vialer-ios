//
//  Configuration.h
//  Copyright © 2015 VoIPGRID. All rights reserved.
//

@import UIKit;
#import "ColorConfiguration.h"

// Known tint color names
extern NSString * const _Nonnull ConfigurationVoIPGRIDBaseURLString;
extern NSString * const _Nonnull ConfigurationMiddleWareBaseURLString;
extern NSString * const _Nonnull ConfigurationSIPDomain;
extern NSString * const _Nonnull ConfigurationEncryptedSIPDomain;
extern NSString * const _Nonnull ConfigurationPartnerURLKey;

// The Google Analytics custom dimension keys
extern NSString * const _Nonnull ConfigurationGADimensionClientIDIndex;
extern NSString * const _Nonnull ConfigurationGADimensionBuildIndex;

/**
 *  Class for accessing items from Config.plist. As a default the plist from the main bundle is used.
 */
@interface Configuration : NSObject

@property (readonly, nonatomic) ColorConfiguration * _Nonnull colorConfiguration;
/**
 * Obtain an instance to this class' Singleton.
 *
 * @return Configuration's singleton instance.
 */
+ (instancetype _Nonnull)defaultConfiguration;

/**
 *  Obtain an NSString containing an URL for the given key.
 *
 *  @param key The key for which to fetch the URL.
 *
 *  @return A NSString containing the URL value.
 */
- (NSString * _Nonnull)UrlForKey:(NSString * _Nonnull)key;

/**
 *  Obtain the Google Analytics custom dimension index for the given key.
 *
 *  @param key The key for which to fetch index.
 *
 *  @return An int representing the dimension index.
 */
- (int)customDimensionIndexForKey:(NSString * _Nonnull)key;

/**
 * The logEntries token.
 *
 * @return NSString with the token.
 */
- (NSString * _Nonnull)logEntriesToken;

/**
 * The logEntries token for a partner.
 *
 * @return NSString with the token or nil.
 */
- (NSString * _Nullable)logEntriesPartnerToken;

/**
 * The Google tracking Id.
 *
 * @return NSString Google tracking id.
 */
- (NSString * _Nonnull)googleTrackingId;

/**
 * Get a list of available stun servers for SIP
 *
 * @return NSArray with Strings of stun servers or empty NSArray
 */
- (NSArray<NSString *> * _Nullable)stunServers;

@end
