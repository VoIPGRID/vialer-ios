//
//  Configuration.h
//  Vialer
//
//  Created by Maarten de Zwart on 11/09/15.
//  Copyright (c) 2015 VoIPGRID. All rights reserved.
//

#import <Foundation/Foundation.h>

// Known tint color names
extern NSString * const kTintColorTabBar;
extern NSString * const kTintColorNavigationBar;
extern NSString * const kTintColorTable;
extern NSString * const kBarTintColorSearchBar;
extern NSString * const kTintColorSearchBar;
extern NSString * const kTintColorMessage;

/** Generic class for accessing the Config.plist items, default the Config.plist from the main bundle is used.
 If you only need one value, you can access it by the static class functions e.g.
 
 `[Configuration tintColorForKey:kTintColorTable];`
 
 Otherwise create an instance of the configuration and access the member functions.
 
     Configuration *config = [Configuration new];
     UIColor *tableColor = [config tintColorForKey:kTintColorTable];
     UIColor *messagecolor = [config tintColorForKey:kTintColorMessage];
 
 */
@interface Configuration : NSObject

/** Generic method to get the UIColor for the specific key
 @param key NSString as the key for the NSArray containing the color configuration 
 @result UIColor instance */
- (UIColor *)tintColorForKey:(NSString *)key;

/** Generic method to get the Url as NSString for the specific key
 @param key NSString as the key for the URLS Dictionary part
 @result Url NSString instance
 */
- (NSString *)UrlForKey:(NSString *)key;

/** Generic method to get an object from the configuration dictionary.
 @param A list of keys to dive into dictionaries.
 @result An instance of the object in the configuration.
 */
- (id)objectInConfigKeyed:(NSString *)firstKey, ... NS_REQUIRES_NIL_TERMINATION;

/**  Class method for easy access to a color
 @see -tintColorForKey:
 */
+ (UIColor *)tintColorForKey:(NSString *)key;

/** Class method for easy access to an url
 @see -UrlForKey:
 */
+ (NSString *)UrlForKey:(NSString *)key;

@end
