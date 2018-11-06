//
//  TwoStepCall.m
//  Copyright © 2015 VoIPGRID. All rights reserved.
//

#import "TwoStepCall.h"

#import <CoreTelephony/CTCallCenter.h>
#import <CoreTelephony/CTCall.h>
#import "PhoneNumberUtils.h"
#import "VoIPGRIDRequestOperationManager.h"

static NSString * const TwoStepCallStatusKey = @"status";
static NSString * const TwoStepCallCallIDKey = @"callid";

static NSString * const TwoStepCallErrorDomain = @"Vialer.TwoStepCall";

static NSString * const TwoStepCallErrorPhoneNumber = @"Extensions or phonenumbers not valid";

static int const TwoStepCallFetchInterval = 1.0;
static int const TwoStepCallCancelTimeout = 3.0;

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
    self = [super init];
    if (self) {
        self.aNumber = aNumber;
        self.bNumber = bNumber;
        self.fetching = NO;
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidEnterBackground:) name:UIApplicationDidEnterBackgroundNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidBecomeActive:) name:UIApplicationDidBecomeActiveNotification object:nil];
    }
    return self;
}

- (void)dealloc {
    VialerLogDebug(@"Testing dealloc");
    [self.statusTimer invalidate];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Properties

- (void)setANumber:(NSString *)aNumber {
    _aNumber = [PhoneNumberUtils cleanPhoneNumber:aNumber];
}

- (void)setBNumber:(NSString *)bNumber {
    _bNumber = [PhoneNumberUtils cleanPhoneNumber:bNumber];
}

- (CTCallCenter *)callCenter {
    if (!_callCenter) {
        _callCenter = [[CTCallCenter alloc] init];
    }
    return _callCenter;
}

- (VoIPGRIDRequestOperationManager *)operationsManager {
    if (!_operationsManager) {
        _operationsManager = [[VoIPGRIDRequestOperationManager alloc] initWithDefaultBaseURL];
    }
    return _operationsManager;
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

    NSDictionary *parameters = @{@"a_number" : self.aNumber,
                                 @"b_number" : self.bNumber,
                                 @"a_cli" : @"default_number",
                                 @"b_cli" : @"default_number",
                                 };

    [self.operationsManager setupTwoStepCallWithParameters:parameters withCompletion:^(NSURLResponse *operation, NSDictionary *responseData, NSError *error) {
        // Check if error.
        if (error) {
            NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)operation;
            if (httpResponse.statusCode == VoIPGRIDHttpErrorBadRequest) {
                /**
                 *  Request malfomed, the request returned the failure reason.
                 *
                 *  Possible reasons:
                 *  - Extensions or phonenumbers not valid.
                 *  - This number is not permitted.
                 */
                NSString *responseString = [responseData description];
                if (responseString.length > 0) {
                    if ([responseString isEqualToString:TwoStepCallErrorPhoneNumber]) {
                        self.status = TwoStepCallStatusInvalidNumber;
                        self.error = [NSError errorWithDomain:TwoStepCallErrorDomain code:TwoStepCallErrorSetupFailed userInfo:@{NSLocalizedDescriptionKey: NSLocalizedString(@"Invalid number used to setup call", nil)}];
                    } else {
                        self.error = [NSError errorWithDomain:TwoStepCallErrorDomain code:TwoStepCallErrorSetupFailed userInfo:@{NSLocalizedDescriptionKey: responseString}];
                    }
                }
            } else {
                self.status = TwoStepCallStatusFailedSetup;
                self.error = error;
            }
            return;
        }

        // Success.
        NSString *callID;
        if ((callID = [self getObjectForKey:TwoStepCallCallIDKey fromResponseObject:responseData])) {
            self.callID = callID;
        } else {
            self.error = [NSError errorWithDomain:VoIPGRIDRequestOperationManagerErrorDomain code:TwoStepCallErrorSetupFailed userInfo:@{NSLocalizedDescriptionKey: NSLocalizedString(@"Two step call failed", nil)}];
        }
        if (self.cancelCallWhenPossible) {
            [self cancel];
            return;
        }
        // Set fetch status to NO, no API call happening on this moment.
        self.fetching = NO;
        self.status = TwoStepCallStatusDialing_a;

        // Start a timer which requests the status of this call every second.
        self.statusTimer = [NSTimer scheduledTimerWithTimeInterval:TwoStepCallFetchInterval target:self selector:@selector(fetchCallStatus:) userInfo:nil repeats:YES];

        // When the user ends a call start dismissing the ConnectAB screen.
        [self setupCallCenter];

    }];
}

- (void)setupCallCenter {
    __weak typeof (self) weakSelf = self;
    [self.callCenter setCallEventHandler:^(CTCall *call) {
        if (call.callState == CTCallStateConnected) {
            // Do one more fetch to get the last updated call status before pauze.
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(TwoStepCallFetchInterval * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [weakSelf.statusTimer invalidate];
            });
        } else if (call.callState == CTCallStateDisconnected) {
            // Start up fetching again after call was ended.
            weakSelf.statusTimer = [NSTimer scheduledTimerWithTimeInterval:TwoStepCallFetchInterval target:weakSelf selector:@selector(fetchCallStatus:) userInfo:nil repeats:YES];
            [weakSelf.statusTimer fire];
            // If fetching failes, we should set the status to disconnected.
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(TwoStepCallCancelTimeout * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                weakSelf.status = TwoStepCallStatusDisconnected;
                // Invalidate the timer so there are no more api calls made.
                [weakSelf.statusTimer invalidate];
            });
        }
    }];
}

- (void)cancel {

    // Don't cancel twice.
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
    [self.operationsManager cancelTwoStepCallForCallId:self.callID withCompletion:^(NSURLResponse *operation, NSDictionary *responseData, NSError *error) {
        if (error) {
            self.error = [NSError errorWithDomain:TwoStepCallErrorDomain code:TwoStepCallErrorCancelFailed userInfo:@{NSLocalizedDescriptionKey: NSLocalizedString(@"Two step call cancel failed", nil)}];
            return;
        }

        self.status = TwoStepCallStatusCanceled;
        [self.statusTimer invalidate];
    }];
}

- (void)fetchCallStatus:(NSTimer *)timer {
    // If there is an API call still going on, skip this update.
    if (self.fetching) {
        return;
    }

    self.fetching = YES;
    [self.operationsManager twoStepCallStatusForCallId:self.callID withCompletion:^(NSURLResponse *operation, NSDictionary *responseData, NSError *error) {
        self.fetching = NO;
        if (error) {
            self.error = [NSError errorWithDomain:TwoStepCallErrorDomain code:TwoStepCallErrorStatusRequestFailed userInfo:@{NSUnderlyingErrorKey: error,
                                                                                                                             NSLocalizedDescriptionKey : NSLocalizedString(@"Two step call failed", nil)
                                                                                                                             }];
            VialerLogError(@"Error Requesting Status for Call ID: %@ Error:%@", self.callID, error);
            [timer invalidate];
            return;
        }

        // Get the callStatus from the response.
        NSString *callStatus = [self getObjectForKey:TwoStepCallStatusKey fromResponseObject:responseData];
        if (!callStatus) {
            self.error = [NSError errorWithDomain:TwoStepCallErrorDomain code:TwoStepCallErrorStatusRequestFailed userInfo:@{NSLocalizedDescriptionKey : NSLocalizedString(@"Two step call failed", nil)}];
            VialerLogError(@"Error Requesting Status for Call ID: %@ Error:%@", self.callID, error);
            [timer invalidate];
            return;
        }

        self.status = [[self class] TwoStepCallStatusFromString:callStatus];

        // If the call status is one of the following, invalidate the timer so it will stop polling.
        if (self.status == TwoStepCallStatusDisconnected || self.status == TwoStepCallStatusFailed_a || self.status == TwoStepCallStatusFailed_b) {
            VialerLogError(@"Call status changed to: %@ invalidating timer", [[self class] statusStringFromTwoStepCallStatus:self.status]);
            [timer invalidate];
        }
    }];
}

#pragma mark - UIApplication background/foreground

- (void)applicationDidEnterBackground:(NSNotification *)notification {
    [self.statusTimer invalidate];
}

- (void)applicationDidBecomeActive:(NSNotification *)notification {
    self.statusTimer = [NSTimer scheduledTimerWithTimeInterval:TwoStepCallFetchInterval target:self selector:@selector(fetchCallStatus:) userInfo:nil repeats:YES];
    [self.statusTimer fire];
}

#pragma mark - TwoStepCallStatus enum to NSString en vice versa
/**
 *  Given a String, this function returns the corresponding TwoStepCallStatus
 *
 *  @param callStatus The string representation of a TwoStepCallStatus.
 *
 *  @return TwoStepCallStatus corresponding to the given String or "TwoStepCallStatusUnknown".
 */
+ (TwoStepCallStatus)TwoStepCallStatusFromString:(NSString *)callStatus {
    NSInteger indexOfString = [[self callStatusStringArray] indexOfObject:callStatus];
    if (indexOfString == NSNotFound) {
        return TwoStepCallStatusUnknown;
    }
    return indexOfString;
}

/**
 *  Given a TwoStepCallStatus this functions returns a String representation of that status
 *
 *  @param callStatus The call status of which you want the string representation.
 *
 *  @return The string representation of the given TwoStepCallStatus or the status at array position 0
 */
+ (NSString *)statusStringFromTwoStepCallStatus:(TwoStepCallStatus)callStatus {
    if (callStatus > [[[self class] callStatusStringArray] count]) {
        //The requested callStatus is beyond the bounds of the array, status is unknown.
        return [[[self class] callStatusStringArray] objectAtIndex:0];
    }
    return [[[self class] callStatusStringArray] objectAtIndex:callStatus];
}

/**
 *  This initializes an array containing all String representations of the TwoStepCallStatus.
 *
 *  @return Array with string representation of TwoStepCallStatus.
 */
+ (NSArray *)callStatusStringArray {
    //  Warning make sure that the order of the strings in the array corespond to the order of the TwoStepCallStatus enum.
    static NSArray *callStatusStringArray;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        callStatusStringArray = @[@"Unknown_Status",
                                  @"setup",
                                  @"dialing_a",
                                  @"dialing_b",
                                  @"connected",
                                  @"disconnected",
                                  @"unauthorized",
                                  @"failed_a",
                                  @"failed_b",
                                  @"failed_setup",
                                  @"invalid_number",
                                  @"canceled",
                                  ];
    });
    return callStatusStringArray;
}

/**
 * Return the Object for the given key from a response object
 * @param key The key to search for in the respons object.
 * @param responseObject The response object to query for the given key.
 * @return The object found for the given key or nil.
 */
- (NSString *)getObjectForKey:(NSString *)key fromResponseObject:(id)responseObject {
    NSString *callStatus = nil;
    if ([[responseObject objectForKey:key] isKindOfClass:[NSString class]]) {
        callStatus = [responseObject objectForKey:key];
    }
    return callStatus;
}

@end
