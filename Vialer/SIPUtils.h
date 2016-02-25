//
//  SIPUtils.h
//  Copyright © 2016 VoIPGRID. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "VialerSIPLib-iOS/VialerSIPLib.h"
#import "VialerSIPLib-iOS/VSLRingtone.h"

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

/**
 *  Add the sipAccount of the current SystemUser to the endpoint.
 *
 *  @return BOOL YES if the adding of the account was a success.
 */
+ (VSLAccount * _Nullable)addSIPAccountToEndpoint;

/**
 *  Clean the phone number so it's usable to setup a SIP call.
 *
 *  @param phoneNumber the phonenumber to be cleaned.
 *
 *  @return NSString a cleaned phonennumber
 */
+ (NSString * _Nonnull)cleanPhoneNumber:(NSString *_Nonnull)phoneNumber;

/**
 *  Register the sip account with the endpoint.
 *
 *  @return BOOL YES if the registration was a success.
 */
+ (BOOL)registerSIPAccountWithEndpoint;

@end
