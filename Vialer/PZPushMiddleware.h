//
//  PZPushMiddleWare.h
//  Vialer
//
//  Created by Karsten Westra on 18/06/15.
//  Copyright (c) 2015 VoIPGRID. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PZPushMiddleware : NSObject

+ (PZPushMiddleware *)sharedInstance;

- (NSString*)baseLink;

- (void)registerForVoIPNotifications;

- (void)handleReceivedNotificationForApplicationState:(UIApplicationState)state payload:(NSDictionary*)payload;

- (void)updateMiddleWareWithData:(NSDictionary*)data;

/** 
 * Updates the middelware. APNS token en sip Account used are the once which are stored in user defaults.
 */
- (void)updateDeviceRecord;
/**
 * Register a token with the PZ middleware which can be used to notify this device of incoming calls, etc.
 *
 * @param token the NSData object containing a APNS registration token used by a backend.
 */
- (void)updateDeviceRecordForToken:(NSData*)token;

/**
 * Unregisters a device from the middleware with the specified SIP account
 * @param sipAccount SIP account ID of the device to unregister
 */
- (void)unregisterSipAccount:(NSString *)sipAccount;

/**
 * Unregister the device from the middleware
 * @param token the APNS token of the device to Unregister
 * @param sipAccount SIP account ID of the device to unregister
 */
- (void)unregisterToken:(NSString *)token andSipAccount:(NSString *)sipAccount;

/**
 * The app returns the NSData containing a APNS token.
 *
 * @param deviceToken NSData object to convert to hex string.
 * @returns hexadecimal string containing APNS token.
 */
+ (NSString *) deviceTokenStringFromData:(NSData*)deviceToken;

@end
