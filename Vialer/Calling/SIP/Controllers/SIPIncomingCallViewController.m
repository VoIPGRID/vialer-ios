//
//  SIPIncomingCallViewController.m
//  Copyright © 2016 VoIPGRID. All rights reserved.
//

#import "SIPIncomingCallViewController.h"
#import "PhoneNumberModel.h"
#import "SIPUtils.h"
#import <VialerSIPLib/VialerSIPLib.h>
#import <VialerSIPLib/VSLRingtone.h>
#import "Vialer-Swift.h"

static NSString * const SIPIncomingCallViewControllerShowSIPCallingSegue = @"SIPCallingSegue";
static NSString * const SIPIncomingCallViewControllerCallState = @"callState";
static NSString * const SIPIncomingCallViewControllerMediaState = @"mediaState";
static NSString * const SIPIncomingCallViewControllerRingtoneName = @"ringtone";
static NSString * const SIPIncomingCallViewControllerRingtoneExtension = @"wav";
static double const SIPIncomingCallViewControllerDismissTimeAfterHangup = 1.0;

@interface SIPIncomingCallViewController()
@property (strong, nonatomic) VSLRingtone *ringtone;
@property (strong, nonatomic) NSString *phoneNumber;
@property (weak, nonatomic) IBOutlet UIButton *acceptCallButton;
@property (weak, nonatomic) IBOutlet UILabel *incomingCallStatusLabel;
@property (weak, nonatomic) IBOutlet UIButton *declineCallButton;
@property (weak, nonatomic) IBOutlet UILabel *incomingPhoneNumberLabel;
@end

@implementation SIPIncomingCallViewController

# pragma mark - Life cycle

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [VialerGAITracker trackScreenForControllerWithName:NSStringFromClass([self class])];
    self.incomingPhoneNumberLabel.text = self.phoneNumber;
    [self.call addObserver:self forKeyPath:SIPIncomingCallViewControllerCallState options:0 context:NULL];
    [self.call addObserver:self forKeyPath:SIPIncomingCallViewControllerMediaState options:0 context:NULL];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.call removeObserver:self forKeyPath:SIPIncomingCallViewControllerCallState];
    [self.call removeObserver:self forKeyPath:SIPIncomingCallViewControllerMediaState];
    [self.ringtone stop];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.destinationViewController isKindOfClass:[SIPCallingViewController class]]) {
        SIPCallingViewController *sipCallingVC = (SIPCallingViewController *)segue.destinationViewController;
        sipCallingVC.activeCall = self.call;
    }
}

# pragma mark - properties

- (VSLRingtone *)ringtone {
    if (!_ringtone) {
        NSURL *fileUrl = [[NSBundle mainBundle] URLForResource:SIPIncomingCallViewControllerRingtoneName
                                                 withExtension:SIPIncomingCallViewControllerRingtoneExtension];
        _ringtone = [[VSLRingtone alloc] initWithRingtonePath:fileUrl];
    }
    return _ringtone;
}

- (void)setCall:(VSLCall *)call {
    _call = call;
    [self.ringtone start];

    dispatch_async(dispatch_get_main_queue(), ^{
        if (call.callerName) {
            self.phoneNumber = [NSString stringWithFormat:@"%@\n%@", call.callerName, call.callerNumber];
        } else {
            self.phoneNumber = call.callerNumber;
        }
    });

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        [PhoneNumberModel getCallName:call withCompletion:^(PhoneNumberModel * _Nonnull phoneNumberModel) {
            dispatch_async(dispatch_get_main_queue(), ^{
                self.phoneNumber = phoneNumberModel.callerInfo;
            });
        }];
    });
}

- (void)setPhoneNumber:(NSString *)phoneNumber {
    _phoneNumber = phoneNumber;
    self.incomingPhoneNumberLabel.text = phoneNumber;
}

#pragma mark - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context {
    if (object == self.call) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (self.call.callState == VSLCallStateDisconnected) {
                [self.ringtone stop];
                self.declineCallButton.enabled = NO;
                self.acceptCallButton.enabled = NO;

                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(SIPIncomingCallViewControllerDismissTimeAfterHangup * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [self dismissViewControllerAnimated:NO completion:nil];
                });
            }
        });
    }
}

#pragma mark - IBActions

- (IBAction)declineCallButtonPressed:(UIButton * _Nonnull)sender {
    VialerLogDebug(@"User pressed \"Decline call\" for call: %ld", (long)self.call.callId);
    [VialerGAITracker declineIncomingCallEvent];
    NSError *error;
    [self.call decline:&error];
    if (error) {
        VialerLogError(@"Error declining call: %@", error);
    }
    [[VialerStats sharedInstance] incomingCallFailedDeclinedWithCall:self.call];
    self.incomingCallStatusLabel.text = NSLocalizedString(@"Declined call", nil);
}

- (IBAction)acceptCallButtonPressed:(UIButton * _Nonnull)sender {
    VialerLogDebug(@"User pressed \"Accept call\" for call: %ld", (long)self.call.callId);
    [VialerGAITracker acceptIncomingCallEvent];
    [self.ringtone stop];
    [[VialerSIPLib sharedInstance].callManager answerCall:self.call completion:^(NSError * _Nullable error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self performSegueWithIdentifier:SIPIncomingCallViewControllerShowSIPCallingSegue sender:nil];
        });
    }];
}

@end
