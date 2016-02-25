//
//  VoIPGRIDRequestOperationManager+Middleware.h
//  Copyright © 2016 VoIPGRID. All rights reserved.
//

#import "VoIPGRIDRequestOperationManager.h"
/**
 *  An category on VoIPGRIDRequestOperationManager responsible for communicating with the Middleware endpoint.
 */
@interface VoIPGRIDRequestOperationManager (Middleware)
/**
 *  Create or update a Middleware device record.
 *
 *  For authentication a basic auth token is sent the the Middleware, this behavior is inherited from VoIPGRIDRequestOperationManager
 *
 *  @param apnsToken  The APNS token of the device record to create or update.
 *  @param sipAccount The SIP account of the device record to create or update.
 *  @param completion Optional completion block giving access to an error object when one occurs.
 */
- (void)updateDeviceRecordWithAPNSToken:(NSString * _Nonnull)apnsToken sipAccount:(NSString * _Nonnull)sipAccount withCompletion:(nullable void (^) (NSError *_Nullable error))completion;

/**
 *  Delete a device record from the Middleware.
 *
 *  For authentication a basic auth token is sent the the Middleware, this behavior is inherited from VoIPGRIDRequestOperationManager
 *
 *  @param apnsToken  The APNS token of the device record to delete.
 *  @param sipAccount The SIP account of the device record to delete.
 *  @param completion Optional completion block giving access to an error object when one occurs.
 */
- (void)deleteDeviceRecordWithAPNSToken:(NSString * _Nonnull)apnsToken sipAccount:(NSString * _Nonnull)sipAccount withCompletion:(nullable void (^) (NSError *_Nullable error ))completion;

/**
 *  Tells the middleware that the user is able to receive the call.
 *
 *  @param originalPayload The payload that is first received from the middleware.
 *  @param available       If the user is avaiable to receive the call.
 *  @param completion      Optional complection block giving access to an error object when one occurs.
 */
- (void)sentCallResponseToMiddleware:(NSDictionary * _Nonnull)originalPayload isAvailable:(BOOL)available withCompletion:(nullable void (^)(NSError * _Nullable error))completion;

@end
