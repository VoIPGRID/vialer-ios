//
//  DDLogWrapper.h
//  Copyright © 2016 Devhouse Spindle. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 *  A wrapper around LumberJackLogger so it can be used in Swift with ease.
 */
@interface DDLogWrapper : NSObject
/**
 *  Setup logging
 */
+ (void)setup;

/**
 *  Log a verbose message
 *
 *  @param message NSString message
 */
+ (void)logVerbose:(NSString * _Nonnull)message;

/**
 *  Log an Info message
 *
 *  @param message NSString message
 */
+ (void)logInfo:(NSString * _Nonnull)message;

/**
 *  Log a warning message
 *
 *  @param message NSString message
 */
+ (void)logWarn:(NSString * _Nonnull)message;

/**
 *  Log an error message
 *
 *  @param message NSString message
 */
+ (void)logError:(NSString * _Nonnull)message;

@end
