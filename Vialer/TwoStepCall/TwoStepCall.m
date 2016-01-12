//
//  TwoStepCall.m
//  Copyright © 2015 VoIPGRID. All rights reserved.
//

#import "TwoStepCall.h"

#import <CoreTelephony/CTCallCenter.h>
#import <CoreTelephony/CTCall.h>
#import "ConnectionHandler.h"
#import "VoIPGRIDRequestOperationManager.h"

static NSString * const TwoStepCallStatusKey = @"status";

@interface TwoStepCall()
@property (nonatomic) TwoStepCallStatus status;
@property (strong, nonatomic) NSString *aNumber;
@property (strong, nonatomic) NSString *bNumber;
@property (strong, nonatomic) NSError *error;
@property (strong, nonatomic) NSTimer *statusTimer;
@property (strong, nonatomic) CTCallCenter *callCenter;
@property (nonatomic) BOOL fetching;
@property (strong, nonatomic) NSString *callID;
@property (nonatomic) BOOL cancelingCall;
@property (nonatomic) BOOL cancelCallWhenPossible;
@property (nonatomic) BOOL canCancel;
@end

@implementation TwoStepCall

- (instancetype)initWithANumber:(NSString *)aNumber andBNumber:(NSString *)bNumber {
    if (self = [super init]) {
        self.aNumber = aNumber;
        self.bNumber = bNumber;
        self.status = TwoStepCallStatusUnknown;
        self.fetching = NO;
    }
    return self;
}

- (void)dealloc {
    [self.statusTimer invalidate];
}

#pragma mark - Properties

- (void)setANumber:(NSString *)aNumber {
    _aNumber = [self cleanPhonenumber:aNumber];
}

- (void)setBNumber:(NSString *)bNumber {
    _bNumber = [self cleanPhonenumber:bNumber];
}

- (CTCallCenter *)callCenter {
    if (!_callCenter) {
        _callCenter = [[CTCallCenter alloc] init];
    }
    return _callCenter;
}

- (void)setStatus:(TwoStepCallStatus)status {
    // Don't change status after the call was canceled.
    if (_status == TwoStepCallStatusCanceled) {
        return;
    }
    _status = status;

    // Check if cancel is possible in this stage.
    switch (status) {
        case TwoStepCallStatusUnknown:
        case TwoStepCallStatusSetupCall:
        case TwoStepCallStatusDialing_a:
        case TwoStepCallStatusConfirm:
        case TwoStepCallStatusDialing_b:
        case TwoStepCallStatusConnected:
            self.canCancel = YES;
            break;
        case TwoStepCallStatusUnAuthorized:
        case TwoStepCallStatusDisconnected:
        case TwoStepCallStatusFailed_a:
        case TwoStepCallStatusFailed_b:
        case TwoStepCallStatusFailedSetup:
        case TwoStepCallStatusInvalidNumber:
        case TwoStepCallStatusCanceled:
            self.canCancel = NO;
            break;
    }
}

#pragma mark - Actions

- (void)start {
    self.status = TwoStepCallStatusSetupCall;

    [[VoIPGRIDRequestOperationManager sharedRequestOperationManager] setupTwoStepCallWithANumber:self.aNumber bNumber:self.bNumber withCompletion:
     ^(NSString *callID, NSError *error) {
         if (error) {
             self.error = error;
             switch (error.code) {
                 case VGTwoStepCallErrorStatusUnAuthorized:
                     self.status = TwoStepCallStatusUnAuthorized;
                     break;
                 case VGTwoStepCallInvalidNumber:
                     self.status = TwoStepCallStatusInvalidNumber;
                     break;
                 default:
                     self.status = TwoStepCallStatusFailedSetup;
                     break;
             }
         } else {
             self.callID = callID;
             if (self.cancelCallWhenPossible) {
                 [self cancel];
                 return;
             }
             // Set fetch status to NO, no API call happening on this moment.
             self.fetching = NO;
             self.status = TwoStepCallStatusDialing_a;

             //Start a timer which requests the status of this call every second.
             self.statusTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(fetchCallStatus:) userInfo:nil repeats:YES];

             // When the user ends a call start dismissing the ConnectAB screen.
             __weak typeof (self) weakSelf = self;
             [self.callCenter setCallEventHandler:^(CTCall *call) {
                 if (call.callState == CTCallStateDisconnected) {
                     // Get the main queue so the status gets set on the correct thread.
                     dispatch_async(dispatch_get_main_queue(), ^{
                         weakSelf.status = TwoStepCallStatusDisconnected;
                         // Invalidate the timer so there are no more api calls made.
                         [weakSelf.statusTimer invalidate];
                     });
                 }
             }];
         }
     }];
}

- (void)cancel {

    // Don't cancel twice
    if (self.cancelingCall) {
        return;

    // If there is no call id, it isn't possible on this moment to cancel, as soon as the call is setup, it will be canceled.
    } else if (!self.callID) {
        self.status = TwoStepCallStatusCanceled;
        self.cancelCallWhenPossible = YES;
        return;
    }

    self.cancelingCall = YES;
    self.canCancel = NO;
    [[VoIPGRIDRequestOperationManager sharedRequestOperationManager] cancelTwoStepCallForCallId:self.callID withCompletion:^(BOOL success, NSError *error) {
        if (success) {
            self.status = TwoStepCallStatusCanceled;
            [self.statusTimer invalidate];
        }
        if (error) {
            self.error = error;
        }
    }];
}

- (void)fetchCallStatus:(NSTimer *)timer {
    // If there is an API call still going on, skip this update
    if (self.fetching) {
        return;
    }

    self.fetching = YES;
    [[VoIPGRIDRequestOperationManager sharedRequestOperationManager] twoStepCallStatusForCallId:self.callID withCompletion:
     ^(NSString *callStatus, NSError *error) {
         self.fetching = NO;
         if (error) {
             NSLog(@"Error Requesting Status for Call ID: %@ Error:%@", self.callID, error);
             [timer invalidate];
             self.status = [[self class] TwoStepCallStatusFromString:callStatus];
             self.error = error;

         } else {
             self.status = [[self class] TwoStepCallStatusFromString:callStatus];
             //If the call status is one of the following, invalidate the timer so it will stop polling.
             if (self.status == TwoStepCallStatusDisconnected || self.status == TwoStepCallStatusFailed_a || self.status == TwoStepCallStatusFailed_b) {
                 NSLog(@"Call status changed to: %@ invalidating timer", [[self class] statusStringFromTwoStepCallStatus:self.status]);
                 [timer invalidate];
             }
         }
     }];
}

#pragma mark - TwoStepCallStatus enum to NSString en vice versa
/**
 Given a String, this function returns the corresponding TwoStepCallStatus or TwoStepCallStatusUnknown if
 the status of an unknown string is requested.

 @param callStatus The string representation of a TwoStepCallStatus.
 @return TwoStepCallStatus corresponding to the given String or "TwoStepCallStatusUnknown".
 */
+ (TwoStepCallStatus)TwoStepCallStatusFromString:(NSString *)callStatus {
    NSInteger indexOfString = [[self callStatusStringArray] indexOfObject:callStatus];
    if (indexOfString == NSNotFound) {
        return TwoStepCallStatusUnknown;
    }
    return indexOfString;
}

/**
 Given a TwoStepCallStatus this functions returns a String representation of that status or the string at
 position 0 if an invalid status is supplied.

 @param callStatus The call status of which you want the string representation.
 @return The string representation of the given TwoStepCallStatus or the status at array position 0
 */
+ (NSString *)statusStringFromTwoStepCallStatus:(TwoStepCallStatus)callStatus {
    if (callStatus > [[[self class] callStatusStringArray] count]) {
        //The requested callStatus is beyond the bounds of the array, status is unknown.
        return [[[self class] callStatusStringArray] objectAtIndex:0];
    }
    return [[[self class] callStatusStringArray] objectAtIndex:callStatus];
}

/**
 A class function which initializes an array containing all String representations of the TwoStepCallStatus.
 @warning make sure that the order of the strings in the array corespond to the order of the TwoStepCallStatus enum.
 */
+ (NSArray *)callStatusStringArray {
    static NSArray *callStatusStringArray;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        callStatusStringArray = @[@"unauthorized",
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
                                  ];
    });
    return callStatusStringArray;
}

/**
 Phonenumbers could have characters that we don't need and will break the api call.

 This will strip any character that cannot be parsed.
 */
- (NSString *)cleanPhonenumber:(NSString *)phonenumber {
    phonenumber = [[phonenumber componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] componentsJoinedByString:@""];
    return [[phonenumber componentsSeparatedByCharactersInSet:[[NSCharacterSet characterSetWithCharactersInString:@"+0123456789"] invertedSet]] componentsJoinedByString:@""];
}

@end
