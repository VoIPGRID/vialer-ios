//
//  SIPCallingViewController.m
//  Copyright © 2016 VoIPGRID. All rights reserved.
//

#import "SIPCallingViewController.h"

#import <AVFoundation/AVFoundation.h>
#import <CocoaLumberjack/CocoaLumberjack.h>
#import "SipCallingButtonsViewController.h"
#import "SIPUtils.h"

static const DDLogLevel ddLogLevel = DDLogLevelVerbose;
static NSString * const SIPCallingViewControllerCallState = @"callState";
static NSString * const SIPCallingViewControllerMediaState = @"mediaState";
static NSString * const SIPCallingViewControllerSegueSIPCallingButtons = @"SipCallingButtonsSegue";
static double const SIPCallingViewControllerDismissTimeAfterHangup = 3.0;

@interface SIPCallingViewController()
@property (weak, nonatomic) IBOutlet UILabel *phoneNumberLabel;
@property (weak, nonatomic) IBOutlet UILabel *callStatusLabel;
@property (strong, nonatomic) NSString *phoneNumber;
@property (strong, nonatomic) VSLCall *call;
@property (strong, nonatomic) AVAudioSession *avAudioSession;
@property (strong, nonatomic) NSString *previousAVAudioSessionCategory;
@property (weak, nonatomic) SipCallingButtonsViewController *sipCallingButtonsVC;
@end

@implementation SIPCallingViewController

#pragma mark - View life cycle

- (void)dealloc {
    [self.call removeObserver:self forKeyPath:SIPCallingViewControllerCallState];
    [self.call removeObserver:self forKeyPath:SIPCallingViewControllerMediaState];
}

#pragma mark - Properties

- (AVAudioSession *)avAudioSession {
    if (!_avAudioSession) {
        _avAudioSession = [AVAudioSession sharedInstance];
    }
    return _avAudioSession;
}

- (void)setCall:(VSLCall *)call {
    if (_call) {
        [_call removeObserver:self forKeyPath:SIPCallingViewControllerCallState];
        [_call removeObserver:self forKeyPath:SIPCallingViewControllerMediaState];
    }
    _call = call;
    [call addObserver:self forKeyPath:SIPCallingViewControllerCallState options:0 context:NULL];
    [call addObserver:self forKeyPath:SIPCallingViewControllerMediaState options:0 context:NULL];

    self.sipCallingButtonsVC.call = call;
}

- (void)setPhoneNumberLabel:(UILabel *)phoneNumberLabel {
    phoneNumberLabel.text = self.phoneNumber;
}

#pragma mark - actions

- (void)handleOutgoingCallWithPhoneNumber:(NSString *)phoneNumber {
    self.phoneNumber = [SIPUtils cleanPhoneNumber:phoneNumber];
    self.previousAVAudioSessionCategory = self.avAudioSession.category;

    VSLAccount *account = [SIPUtils addSIPAccountToEndpoint];

    if (account) {
        [account callNumber:self.phoneNumber withCompletion:^(NSError *error, VSLCall *call) {
            [UIDevice currentDevice].proximityMonitoringEnabled = YES;
            if (error) {
                DDLogError(@"%@", error);
                NSError *setAudioCategoryError;
                [self.avAudioSession setCategory:self.previousAVAudioSessionCategory error:&setAudioCategoryError];
                if (setAudioCategoryError) {
                    DDLogError(@"Error setting the audio session category: %@", setAudioCategoryError);
                }
            } else {
                self.call = call;
            }
        }];
    }
}

#pragma mark - IBActions

- (IBAction)endCallButtonPressed:(UIButton *)sender {
    if (self.call.callState != VSLCallStateDisconnected) {
        self.callStatusLabel.text = NSLocalizedString(@"Ending call...", nil);
        NSError *error;
        [self.call hangup:&error];
        if (error) {
            DDLogError(@"Error hangup call: %@", error);
        } else {
            self.endCallButton.enabled = NO;
        }
    }
}

#pragma mark - Segues

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:SIPCallingViewControllerSegueSIPCallingButtons]) {
        self.sipCallingButtonsVC = segue.destinationViewController;
        self.sipCallingButtonsVC.call = self.call;
    }
}
# pragma mark - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context {
    if (object == self.call) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self updateUI];
            if (self.call.callState == VSLCallStateDisconnected) {
                [self handleCallEnded];
            }
        });
    }
}

- (void)updateUI {
    switch (self.call.callState) {
        case VSLCallStateNull: {
            self.callStatusLabel.text = nil;
            break;
        }
        case VSLCallStateCalling: {
            self.callStatusLabel.text = NSLocalizedString(@"Calling...", nil);
            break;
        }
        case VSLCallStateIncoming: {
            self.callStatusLabel.text = NSLocalizedString(@"Incoming call...", nil);
            break;
        }
        case VSLCallEarlyState: {
            self.callStatusLabel.text = NSLocalizedString(@"Calling...", nil);
            break;
        }
        case VSLCallStateConnecting: {
            self.callStatusLabel.text = NSLocalizedString(@"Connecting...", nil);
            break;
        }
        case VSLCallStateConfirmed: {
            self.callStatusLabel.text = NSLocalizedString(@"0:00", nil);
            break;
        }
        case VSLCallStateDisconnected: {
            self.callStatusLabel.text = NSLocalizedString(@"Call ended", nil);
            break;
        }
    }
}

- (void)handleCallEnded {
    DDLogInfo(@"Ending call");
    [UIDevice currentDevice].proximityMonitoringEnabled = NO;

    // Restore the old AudioSessionCategory.
    NSError *setAudioCategoryError;
    [self.avAudioSession setCategory:self.previousAVAudioSessionCategory error:&setAudioCategoryError];
    if (setAudioCategoryError) {
        DDLogError(@"Error setting the audio session category: %@", setAudioCategoryError);
    }

    // Wait a little while before dismissing the view.
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(SIPCallingViewControllerDismissTimeAfterHangup * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
    });
}

@end
