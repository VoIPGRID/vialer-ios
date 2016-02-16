//
//  APNSHandler.h
//  Copyright © 2016 voipgrid.com. All rights reserved.
//

#import <Foundation/Foundation.h>
@import PushKit;

/**
 * The APNS Handler class is a singleton responsible for registering with the APNS servers
 * and implementing the required delegate functions.
 * The reason why this class is a singlton:
 * According to the PKPushRegistry doc: "Typically, you create a push registry object, configure it, and keep it running for the duration of your app."
 */
@interface APNSHandler : NSObject <PKPushRegistryDelegate>

/**
 * Obtain an instance to this class' Singleton.
 *
 * @return APNS Handler singleton instance.
 */
+ (instancetype)sharedHandler;

/**
 * Register for APNS VoIP messages
 *
 * To register for VoIP APNS type messages this function needs to be called.
 * It will trigger the receipt of an APNS token from Apple's servers.
 *
 * You will also need to enable background mode for your app to receive APNS messages
 * using: "App target" -> capabilities -> background modes -> Voice over IP.
 */
- (void)registerForVoIPNotifications;

/**
 *  Class function returning the stored APNS token.
 *
 *  @return A NSString representation of the locally stored APNS Token or nil if not available.
 */
+ (NSString *)storedAPNSToken;
@end
