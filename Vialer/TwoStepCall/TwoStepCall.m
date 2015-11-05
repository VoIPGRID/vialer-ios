//
//  TwoStepCall.m
//  Vialer
//
//  Created by Harold on 12/10/15.
//  Copyright © 2015 VoIPGRID. All rights reserved.
//

#import "TwoStepCall.h"

#import "VoIPGRIDRequestOperationManager.h"

static NSString * const TwoStepCallIDKey = @"callID";
static NSString * const TwoStepCallStatusKey = @"status";

@interface TwoStepCall()
@property (nonatomic)TwoStepCallStatus status;
@property (nonatomic, strong)NSString *aNumber;
@property (nonatomic, strong)NSString *bNumber;
@property (nonatomic, strong)NSError *error;
@property (nonatomic, strong)NSTimer *statusTimer;
@end

@implementation TwoStepCall

- (instancetype)initWithANumber:(NSString *)aNumber andBNumber:(NSString *)bNumber {
    if (self = [super init]) {
        self.aNumber = aNumber;
        self.bNumber = bNumber;
        self.status = TwoStepCallStatusUnknown;
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

- (void)start {
    [[VoIPGRIDRequestOperationManager sharedRequestOperationManager] setupTwoStepCallWithANumber:self.aNumber bNumber:self.bNumber withCompletion:
     ^(NSString *callID, NSError * error) {
         if (error) {
             self.error = error;
             switch (error.code) {
                 case VGTwoStepCallErrorStatusUnAuthorized:
                     self.status = TwoStepCallStatusUnAuthorized;
                     break;
                 case VGTwoStepCallErrorSetupFailed:
                     self.status = TwoStepCallStatusFailedSetup;
                     break;
                 case VGTwoStepCallInvalidNumber:
                     self.status = TwoStepCallStatusInvalidNumber;
                     break;
                 default:
                     self.status = TwoStepCallStatusUnknown;
                     break;
             }
         } else {
             //Start a timer which requests the status of this call every second.
             NSDictionary *userInfo = @{TwoStepCallIDKey : callID};
             self.statusTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(fetchCallStatus:) userInfo:userInfo repeats:YES];
         }
     }];
}

- (void)fetchCallStatus:(NSTimer *)timer {
    NSString *callID = [[timer userInfo] objectForKey:TwoStepCallIDKey];

    [[VoIPGRIDRequestOperationManager sharedRequestOperationManager] twoStepCallStatusForCallId:callID withCompletion:
     ^(NSString *callStatus, NSError *error) {
         if (error) {
             NSLog(@"Error Requesting Status for Call ID: %@ Error:%@", callID, error);
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

#pragma mark - KVO automatic behaviour override
/**
 Overridden setter for status to manually fire KVO notifications only when the status actually changes
 */
- (void)setStatus:(TwoStepCallStatus)newStatus {
    if (_status != newStatus) {
        [self willChangeValueForKey:TwoStepCallStatusKey];
        _status = newStatus;
        [self didChangeValueForKey:TwoStepCallStatusKey];
    }
}

/**
 By overriding this function and by overriding the getter you can manually control when an KVO event is fired
 */
+ (BOOL)automaticallyNotifiesObserversForKey:(NSString *)key {
    if ([key isEqualToString:TwoStepCallStatusKey]) {
        return NO;
    } else {
        return [super automaticallyNotifiesObserversForKey:key];
    }
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
