//
//  TwoStepCall.h
//  Copyright © 2015 VoIPGRID. All rights reserved.
//

#import <Foundation/Foundation.h>

/** @warning If this enum is changed in any way, also update the TwoStepCallStatusStringArray in the implementation file */
typedef NS_ENUM(NSInteger, TwoStepCallStatus) {
    TwoStepCallStatusUnknown,
    TwoStepCallStatusSetupCall,
    TwoStepCallStatusDialing_a,
    TwoStepCallStatusConfirm,
    TwoStepCallStatusDialing_b,
    TwoStepCallStatusConnected,
    TwoStepCallStatusDisconnected,
    TwoStepCallStatusUnAuthorized,
    TwoStepCallStatusFailed_a,
    TwoStepCallStatusFailed_b,
    TwoStepCallStatusFailedSetup,
    TwoStepCallStatusInvalidNumber,
    TwoStepCallStatusCanceled,
};

@interface TwoStepCall : NSObject
/** KVO complient property to monitor changes to the status of the call */
@property (readonly, nonatomic) TwoStepCallStatus status;

/** Readonly property for the A number set during init */
@property (readonly, nonatomic) NSString * _Nonnull aNumber;
/** Readonly property for the B number set during init */
@property (readonly, nonatomic) NSString * _Nonnull bNumber;

/** Readonly property which will tell if it is possible to cancel the call */
@property (readonly, nonatomic) BOOL canCancel;

/** When an error occures indicating by an error status like "failed_a", "failed_b"... specifics for the error can be obtained from this propery */
@property (nonatomic, readonly) NSError * _Nullable error;

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

/**
 The call can be canceled or dismissed with this method.
 */
- (void)cancel;

@end
