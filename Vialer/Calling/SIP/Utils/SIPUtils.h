//
//  SIPUtils.h
//  Copyright © 2016 VoIPGRID. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "VialerSIPLib/VialerSIPLib.h"
#import "VialerSIPLib/VSLRingtone.h"

@interface SIPUtils : NSObject

/**
 *  Setup the SIP endpoint with the VialerSIPLib.
 *
 *  @return BOOL
 */
+ (BOOL)setupSIPEndpoint;

/**
 *  Remove the SIP endpoint.
 */
+ (void)removeSIPEndpoint;

+ (BOOL)updateCodecs;

/**
 *  Add the sipAccount of the current SystemUser to the endpoint.
 *
 *  @return BOOL YES if the adding of the account was a success.
 */
+ (VSLAccount * _Nullable)addSIPAccountToEndpoint;

/**
 *  Register the sip account with the endpoint.
 *
 *  @return BOOL YES if the registration was a success.
 */
+ (void)registerSIPAccountWithEndpointWithCompletion:(void (^_Nonnull)(BOOL success, VSLAccount *_Nullable account))completion;

/**
 *  Get a VSLCall instance based on a callId.
 *
 *  @param callId NSString with the callId that needs the be found.
 *
 *  @return VSLCall instance or nil.
 */
+ (VSLCall * _Nullable)getCallWithId:(NSString *_Nonnull)callId __attribute__((unavailable("Deprecated, use VSLCallManager -callWithCallId: instead")));

/**
 *  Check if there is another call in progress.
 *
 *  @param receivedCall VSLCall instance of the call that is incoming.
 *
 *  @return BOOL YES if there is another call in progress.
 */
+ (BOOL)anotherCallInProgress:(VSLCall * _Nonnull)receivedCall;

/**
 *  Get the first active call.
 *
 *  @return A VSLCall instance or nil.
 */
+ (VSLCall * _Nullable)getFirstActiveCall;

+ (VSLCodecConfiguration * _Nonnull)codecConfiguration;
@end
