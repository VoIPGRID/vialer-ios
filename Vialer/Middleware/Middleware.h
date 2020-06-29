//
//  Middleware.h
//  Copyright © 2016 VoIPGRID. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 * The Middleware class communicates with the Middleware server.
 */
@interface Middleware : NSObject

/**
 *  Notification which will be posted when the middleware detects a registration
 *  on another device.
 */
extern NSString * const _Nonnull MiddlewareRegistrationOnOtherDeviceNotification;

extern NSString * const _Nonnull MiddlewareAccountRegistrationIsDoneNotification;

/**
 *  Sent APNS token to Middleware.
 *
 *  When the App obtains an APNS token, for the purpose of informing it about
 *  an incoming call, this function will sent the given token to the Middleware.
 *
 *  @param apnsToken NSString representation of an APNS token
 */
- (void)sentAPNSToken:(NSString * _Nonnull) apnsToken;

/**
 *  Handle APNS Payload.
 *
 *  When an APNS message with payload is received from the Middleware, this function
 *  can be called to process it.
 *
 *  @param payload The payload received through an APNS message.
 */
- (void)handleReceivedAPSNPayload:(NSDictionary *_Nonnull)payload;

/**
 *  When remote logging is enabled in the settings, this function will update the
 *  middleware with the remote logging id.
 */
- (void)updateDeviceRegistrationWithRemoteLoggingId;

- (void)deleteDeviceRegistration: (NSString *_Nonnull) apnsToken;

@end
