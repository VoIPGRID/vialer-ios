//
//  TwoStepCall.h
//  Vialer
//
//  Created by Harold on 12/10/15.
//  Copyright © 2015 VoIPGRID. All rights reserved.
//

#import <Foundation/Foundation.h>

/** @warning If this enum is changed in any way, also update the TwoStepCallStatusStringArray in the implementation file */
typedef NS_ENUM(NSInteger, TwoStepCallStatus) {
    TwoStepCallStatusUnAuthorized,
    TwoStepCallStatusUnknown,
    TwoStepCallStatusDialing_a,
    TwoStepCallStatusConfirm,
    TwoStepCallStatusDialing_b,
    TwoStepCallStatusConnected,
    TwoStepCallStatusDisconnected,
    TwoStepCallStatusFailed_a,
    TwoStepCallStatusFailed_b,
    TwoStepCallStatusFailedSetup,
    TwoStepCallStatusInvalidNumber,
};

/** @warning If this string array is changed in any way, also update the TwoStepCallStatus ENUM in the header file */
NSString * _Nonnull const TwoStepCallStatusStringArray[] = {
    @"unauthorized",
    @"Unknown_Status",
    @"dialing_a",
    @"confirm",
    @"dialing_b",
    @"connected",
    @"disconnected",
    @"failed_a",
    @"failed_b",
    @"failed_setup",
    @"invalid_number",
    nil
};

@interface TwoStepCall : NSObject
/** KVO complient property to monitor changes to the status of the call */
@property (nonatomic, readonly)TwoStepCallStatus status;

/** Readonly property for the A number set during init */
@property (nonatomic, readonly, nonnull)NSString *aNumber;
/** Readonly property for the B number set during init */
@property (nonatomic, readonly, nonnull)NSString * bNumber;

/** When an error occures indicating by an error status like "failed_a", "failed_b"... specifics for the error can be obtained from this propery */
@property (nonatomic, readonly, nullable)NSError *error;

/**
 Designated initializer to create a TwoStepCall with an A number and a B number.

 @param aNumber The A number for the TwoStepCall, this number will be called first.
 @param bNumber The B number for the TwoStepCall, this number will be called when the first is connected.
 */
- (_Nonnull instancetype)initWithANumber:(NSString * _Nonnull)aNumber andBNumber:(NSString * _Nonnull)bNumber;

/**
 Once the call is initialized, it can be started using this function. Changed to the call status
 can be monitored using the callStatus property. An error condition will be indicated by the error property being set.
 */
- (void)start;

@end
