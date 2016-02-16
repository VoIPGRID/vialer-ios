//
//  SIPCallingViewController.m
//  Copyright © 2016 VoIPGRID. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import <CocoaLumberjack/CocoaLumberjack.h>
#import "SIPCallingViewController.h"
#import "SIPUtils.h"

static const DDLogLevel ddLogLevel = DDLogLevelVerbose;
static NSString * const SIPCallingViewControllerCallState = @"callState";
static NSString * const SIPCallingViewControllerMediaState = @"mediaState";
static double const SIPCallingViewControllerDismissTimeAfterHangup = 3.0;

@interface SIPCallingViewController()
@property (weak, nonatomic) IBOutlet UILabel *phoneNumberLabel;
@property (weak, nonatomic) IBOutlet UILabel *callStatusLabel;
@property (strong, nonatomic) NSString *phoneNumber;
@property (strong, nonatomic) VSLCall *call;
@property (strong, nonatomic) AVAudioSession *avAudioSession;
@property (strong, nonatomic) NSString *previousAVAudioSessionCategory;
@end

@implementation SIPCallingViewController

# pragma  mark - properties

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
}

- (void)setPhoneNumberLabel:(UILabel *)phoneNumberLabel {
    phoneNumberLabel.text = self.phoneNumber;
}

# pragma mark - actions

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

# pragma mark - IBActions

- (IBAction)endCallButtonPressed:(UIButton *)sender {
    if (self.call.callState != VSLCallStateDisconnected) {
        self.callStatusLabel.text = NSLocalizedString(@"Ending call...", nil);
        NSError *error;
        [self.call hangup:&error];
        if (error) {
            DDLogError(@"Error hangup call: %@", error);
        }
    }
}

# pragma mark - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context {
    if (object == self.call) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (self.call.callState == VSLCallStateDisconnected) {
                [self handleCallEnded];
            }
        });
    }
}

- (void)handleCallEnded {
    DDLogInfo(@"Ending call");
    self.callStatusLabel.text = NSLocalizedString(@"Call ended", nil);

    // No need to observe the call anymore.
    @try {
        [self.call removeObserver:self forKeyPath:SIPCallingViewControllerCallState];
    } @catch (NSException *exception) {
        DDLogInfo(@"Observer for keyPath callState was already removed. %@", exception);
    }

    @try {
        [self.call removeObserver:self forKeyPath:SIPCallingViewControllerMediaState];
    } @catch (NSException *exception) {
        DDLogInfo(@"Observer for keyPath mediaState was already removed. %@", exception);
    }

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
