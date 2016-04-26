//
//  SIPCallingViewController.m
//  Copyright © 2016 VoIPGRID. All rights reserved.
//

#import "SIPCallingViewController.h"

#import "AppDelegate.h"
#import <AVFoundation/AVFoundation.h>
#import "ContactUtils.h"
#import "DurationTimer.h"
#import "GAITracker.h"
#import "PhoneNumberModel.h"
#import "PhoneNumberUtils.h"
#import "SIPUtils.h"

static NSString * const SIPCallingViewControllerCallState = @"callState";
static NSString * const SIPCallingViewControllerMediaState = @"mediaState";
static NSString * const SIPCallingViewControllerSegueSIPCallingButtons = @"SipCallingButtonsSegue";
static NSString * const SIPCallingViewControllerUnwindToVialerRootViewControllerSegue = @"UnwindToVialerRootViewControllerSegue";
static double const SIPCallingViewControllerDismissTimeAfterHangup = 1.0;

@interface SIPCallingViewController()
@property (weak, nonatomic) IBOutlet UILabel *phoneNumberLabel;
@property (weak, nonatomic) IBOutlet UILabel *callStatusLabel;
@property (strong, nonatomic) NSString *phoneNumberLabelText;
@property (strong, nonatomic) VSLCall *call;
@property (strong, nonatomic) AVAudioSession *avAudioSession;
@property (strong, nonatomic) NSString *previousAVAudioSessionCategory;
@property (weak, nonatomic) SipCallingButtonsViewController *sipCallingButtonsVC;
@property (strong, nonatomic) DurationTimer *durationTimer;
@end

@implementation SIPCallingViewController

#pragma mark - View life cycle

- (void)viewDidLoad {
    [super viewDidLoad];
    self.phoneNumberLabel.text = self.phoneNumberLabelText;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [GAITracker trackScreenForControllerName:NSStringFromClass([self class])];
}

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

- (void)setPhoneNumberLabelText:(NSString *)phoneNumberLabelText {
    _phoneNumberLabelText = phoneNumberLabelText;
    self.phoneNumberLabel.text = phoneNumberLabelText;
}

#pragma mark - actions

- (void)handleOutgoingCallWithPhoneNumber:(NSString *)phoneNumber withContact:(CNContact *)contact {
    NSString *cleanPhoneNumber = [PhoneNumberUtils cleanPhoneNumber:phoneNumber];
    self.previousAVAudioSessionCategory = self.avAudioSession.category;
    self.phoneNumberLabelText = cleanPhoneNumber;

    if (contact) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
            [PhoneNumberModel getCallNameFromContact:contact andPhoneNumber:phoneNumber withCompletion:^(PhoneNumberModel * _Nonnull phoneNumberModel) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    self.phoneNumberLabelText = phoneNumberModel.callerInfo;
                });
            }];
        });
    }

    VSLAccount *account = [SIPUtils addSIPAccountToEndpoint];
    [account callNumber:cleanPhoneNumber withCompletion:^(NSError *error, VSLCall *call) {
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

- (void)handleIncomingCallWithVSLCall:(VSLCall *)call {
    self.previousAVAudioSessionCategory = self.avAudioSession.category;
    self.call = call;

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        [PhoneNumberModel getCallName:call withCompletion:^(PhoneNumberModel * _Nonnull phoneNumberModel) {
            dispatch_async(dispatch_get_main_queue(), ^{
                self.phoneNumberLabelText = phoneNumberModel.callerInfo;
            });
        }];
    });

    NSError *error;
    [self.call answer:&error];
    if (error) {
        DDLogError(@"Error accepting call: %@", error);
        NSError *setAudioCategoryError;
        [self.avAudioSession setCategory:self.previousAVAudioSessionCategory error:&setAudioCategoryError];
        if (setAudioCategoryError) {
            DDLogError(@"Error setting the audio session category: %@", setAudioCategoryError);
        }
    }
    [UIDevice currentDevice].proximityMonitoringEnabled = YES;
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

    self.endCallButton.enabled = NO;

    // Wait a little while before dismissing the view.
    double timeToWaitBeforeDismissing = SIPCallingViewControllerDismissTimeAfterHangup;
#ifdef DEBUG
    // Increase the dismiss time so snapshot can take a proper screenshot
    if ([AppDelegate isSnapshotScreenshotRun]) {
        timeToWaitBeforeDismissing = 5.0;
    }
#endif
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(timeToWaitBeforeDismissing * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (self.call.incoming) {
            [self performSegueWithIdentifier:SIPCallingViewControllerUnwindToVialerRootViewControllerSegue sender:self];
        } else {
            [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
        }
    });
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

- (IBAction)hideNumberpad:(UIButton *)sender {
    [self.sipCallingButtonsVC hideNumberpad];
}

#pragma mark - Segues

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:SIPCallingViewControllerSegueSIPCallingButtons]) {
        self.sipCallingButtonsVC = ((UINavigationController *)segue.destinationViewController).viewControllers[0];
        self.sipCallingButtonsVC.call = self.call;
        self.sipCallingButtonsVC.delegate = self;
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
            if (self.durationTimer == nil) {
                self.durationTimer = [[DurationTimer alloc] initAndStartDurationTimerWithTimeInterval:1.0 andDurationTimerStatusUpdateBlock:^(NSInteger durationTimer) {
                    self.callStatusLabel.text = [NSString stringWithFormat:@"%02d:%02d", (int)(durationTimer / 60), (int)(durationTimer % 60)];
                }];
            }
            break;
        }
        case VSLCallStateDisconnected: {
            self.callStatusLabel.text = NSLocalizedString(@"Call ended", nil);
            if  (self.durationTimer) {
                [self.durationTimer stop];
                self.durationTimer = nil;
            }
            break;
        }
    }
}

#pragma mark - SipCallingButtonsViewControllerDelegate

- (void)keypadChangedVisibility:(BOOL)visible {
    self.hideButton.hidden = !visible;
    self.callStatusLabel.hidden = visible;

    if (!visible) {
        self.phoneNumberLabel.text = self.phoneNumberLabelText;
    }
}

- (void)DTMFSend:(NSString *)character {
    // Check if this is the first character pressed.
    if ([self.phoneNumberLabel.text isEqualToString:self.phoneNumberLabelText]) {
        self.phoneNumberLabel.text = character;
    } else {
        self.phoneNumberLabel.text = [self.phoneNumberLabel.text stringByAppendingString:character];
    }
}

@end