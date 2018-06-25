//
//  MiddlewareRequestOperationManager.h
//  Copyright © 2016 VoIPGRID. All rights reserved.
//

#import "VoIPGRIDRequestOperationManager.h"

@interface MiddlewareRequestOperationManager : VoIPGRIDRequestOperationManager


/**
 *  A convenience initializer to provide the base URL as an NSString.
 *
 *  @param baseURLString A NSString which represents the base URL.
 *
 *  @return a Middleware Request Operation Manager instance which talks to the given base URL.
 */
- (_Nullable instancetype)initWithBaseURLasString:(NSString * _Nonnull)baseURLString;

/**
 *  Create or update a Middleware device record.
 *
 *  For authentication a basic auth token is sent the the Middleware, this behavior is inherited from VoIPGRIDRequestOperationManager
 *
 *  @param apnsToken  The APNS token of the device record to create or update.
 *  @param sipAccount The SIP account of the device record to create or update.
 *  @param remoteLoggingId The remote logging id when the user enables Remote Logging
 *  @param completion Optional completion block giving access to an error object when one occurs.
 */
- (void)updateDeviceRecordWithAPNSToken:(NSString * _Nonnull)apnsToken sipAccount:(NSString * _Nonnull)sipAccount withCompletion:(nullable void (^) (NSError * _Nullable error))completion;

/**
 *  Delete a device record from the Middleware.
 *
 *  For authentication a basic auth token is sent the the Middleware, this behavior is inherited from VoIPGRIDRequestOperationManager
 *
 *  @param apnsToken  The APNS token of the device record to delete.
 *  @param sipAccount The SIP account of the device record to delete.
 *  @param completion Optional completion block giving access to an error object when one occurs.
 */
- (void)deleteDeviceRecordWithAPNSToken:(NSString * _Nonnull)apnsToken sipAccount:(NSString * _Nonnull)sipAccount withCompletion:(nullable void (^) (NSError * _Nullable error ))completion;

/**
 *  Tells the middleware that the user is able to receive the call.
 *
 *  @param originalPayload The payload that is first received from the middleware
 *  @param available       If the user is avaiable to receive the call.
 *  @param completion      Optional completion block giving access to an error object when one occurs.
 */
- (void)sentCallResponseToMiddleware:(NSDictionary * _Nonnull)originalPayload isAvailable:(BOOL)available withCompletion:(nullable void (^)(NSError * _Nullable error))completion;

/**
 *  Tells the middleware why the app rejected the call.
 *
 *  @param originalPayload The payload that is first received from the middleware
 *  @param available       If the user is avaiable to receive the call.
 *  @param completion      Optional completion block giving access to an error object when one occurs.
 */
- (void)sendHangupReasonToMiddleware:(NSString * _Nullable)hangupReason forUniqueKey:(NSString * _Nonnull)uniqueKey withCompletion:(void (^)(NSError *error))completion;

/**
 *  Log metrics to middleware.
 *
 *  @param payload      The payload with statistics
 *  @param completion   Optional completion block giving access to an error object when one occurs.
 */
- (void)sendMetricsToMiddleware:(NSDictionary *)payload withCompletion:(void(^) (NSError *error))completion;
@end
