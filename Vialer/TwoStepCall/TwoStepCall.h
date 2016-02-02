//
//  TwoStepCall.h
//  Copyright © 2015 VoIPGRID. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 *  Possible statusses a TwoStepCall can have.
 *
 *  If this enum is changed in any way, also update the TwoStepCallStatusStringArray in the implementation file.
 */
typedef NS_ENUM(NSInteger, TwoStepCallStatus) {
    /**
     *  Unknown call status.
     */
    TwoStepCallStatusUnknown,
    /**
     *  Call is being setup.
     */
    TwoStepCallStatusSetupCall,
    /**
     *  The first leg of the call to aNumber is being setup.
     */
    TwoStepCallStatusDialing_a,
    /**
     *  The second leg of the call to bNumber is being setup.
     */
    TwoStepCallStatusDialing_b,
    /**
     *  The calls are connected to one call.
     */
    TwoStepCallStatusConnected,
    /**
     *  The call has ended.
     */
    TwoStepCallStatusDisconnected,
    /**
     *  The user is unauthorized to make TwoStepCall.
     */
    TwoStepCallStatusUnAuthorized,
    /**
     *  Unable to connect aNumber.
     */
    TwoStepCallStatusFailed_a,
    /**
     *  Unable to connect bNumber.
     */
    TwoStepCallStatusFailed_b,
    /**
     *  Unable to setup the TwoStepCall.
     */
    TwoStepCallStatusFailedSetup,
    /**
     *  The call was made to an invalid number (aNumber or bNumber).
     */
    TwoStepCallStatusInvalidNumber,
    /**
     *  The call was canceled.
     */
    TwoStepCallStatusCanceled,
};

@class VoIPGRIDRequestOperationManager;

@interface TwoStepCall : NSObject

/**
*  The status of the call.
*/
@property (readonly, nonatomic) TwoStepCallStatus status;

/**
 *  The A number of the call (First leg).
 */
@property (readonly, nonatomic) NSString * _Nonnull aNumber;

/**
 *  The B number of the call (Second leg).
 */
@property (readonly, nonatomic) NSString * _Nonnull bNumber;

/**
 *  If true, it is possible to cancel the call.
 */
@property (readonly, nonatomic) BOOL canCancel;

/**
 *  When an error occures indicating by an error status like "failed_a", "failed_b"... specifics for the error can be obtained from this property.
 */
@property (nonatomic, readonly) NSError * _Nullable error;

@property (nonatomic, strong) VoIPGRIDRequestOperationManager * _Nonnull operationsManager;

/**
 *  Designated initializer to create a TwoStepCall with an A number and a B number.
 *
 *  @param aNumber The A number for the TwoStepCall, this number will be called first.
 *  @param bNumber The B number for the TwoStepCall, this number will be called when the first is connected.
 *
 *  @return TwoStepCall instance ready to call
 */
- (_Nonnull instancetype)initWithANumber:(NSString * _Nonnull)aNumber andBNumber:(NSString * _Nonnull)bNumber;

/**
 *  Start the TwoStep call.
 */
- (void)start;

/**
 *  This will fetch current callstatus.
 *
 *  @param timer The timer that will periodically call this method.
 */
- (void)fetchCallStatus:(NSTimer * _Nullable)timer;

/**
 *  Cancel the TwoStep call.
 */
- (void)cancel;

@end
