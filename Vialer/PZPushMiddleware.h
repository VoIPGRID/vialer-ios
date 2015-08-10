//
//  PZPushMiddleWare.h
//  Vialer
//
//  Created by Karsten Westra on 18/06/15.
//  Copyright (c) 2015 VoIPGRID. All rights reserved.
//

#import <Foundation/Foundation.h>

@class AppDelegate;

@interface PZPushMiddleware : NSObject

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
- (void)unregisterToken:(NSString *)token;

/**
 * The app returns the NSData containing a APNS token.
 *
 * @param deviceToken NSData object to convert to hex string.
 * @returns hexadecimal string containing APNS token.
 */
+ (NSString *) deviceTokenStringFromData:(NSData*)deviceToken;

@end
