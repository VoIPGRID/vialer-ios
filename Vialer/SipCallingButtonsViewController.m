//
//  SipCallingButtonsViewController.m
//  Copyright © 2015 VoIPGRID. All rights reserved.
//

#import "SipCallingButtonsViewController.h"

#import <CocoaLumberjack/CocoaLumberjack.h>
#import "Configuration.h"
#import "SipCallingButton.h"
#import <VialerSIPLib-iOS/VialerSIPLib.h>

static float const SipCallingButtonsPressedAlpha = 0.5;
static const DDLogLevel ddLogLevel = DDLogLevelVerbose;
static NSString * const SIPCallingButtonsViewControllerCallState = @"callState";
static NSString * const SIPCallingButtonsViewControllerMediaState = @"mediaState";

@interface SipCallingButtonsViewController ()
@property (strong, nonatomic) IBOutletCollection(SipCallingButton) NSArray *sipCallingButtons;
@property (strong, nonatomic) IBOutletCollection(UILabel) NSArray *sipCallingLabels;
@property (weak, nonatomic) IBOutlet SipCallingButton *soundOffButton;
@property (weak, nonatomic) IBOutlet SipCallingButton *numbersButton;
@property (weak, nonatomic) IBOutlet SipCallingButton *speakerButton;
@property (strong, nonatomic) UIColor *pressedColor;
@property (strong, nonatomic) UIColor *textColor;
@end

@implementation SipCallingButtonsViewController

#pragma mark - View Life Cycle

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self updateButtons];
}

- (void)dealloc {
    [self.call removeObserver:self forKeyPath:SIPCallingButtonsViewControllerCallState];
    [self.call removeObserver:self forKeyPath:SIPCallingButtonsViewControllerMediaState];
}

#pragma mark - Properties

- (UIColor *)pressedColor {
    if (!_pressedColor) {
        _pressedColor = [[Configuration tintColorForKey:ConfigurationNumberPadButtonPressedColor] colorWithAlphaComponent:SipCallingButtonsPressedAlpha];
    }
    return _pressedColor;
}

- (UIColor *)textColor {
    if (!_textColor) {
        _textColor = [Configuration tintColorForKey:ConfigurationNumberPadButtonTextColor];
    }
    return _textColor;
}

- (void)setCall:(VSLCall *)call {
    if (_call) {
        [_call removeObserver:self forKeyPath:SIPCallingButtonsViewControllerCallState];
        [_call removeObserver:self forKeyPath:SIPCallingButtonsViewControllerMediaState];
    }
    _call = call;
    [call addObserver:self forKeyPath:SIPCallingButtonsViewControllerCallState options:0 context:NULL];
    [call addObserver:self forKeyPath:SIPCallingButtonsViewControllerMediaState options:0 context:NULL];
    [self updateButtons];
}

#pragma mark - Button actions

- (void)holdButtonPressed:(SipCallingButton *)sender {
    NSError *error;
    [self.call toggleHold:&error];
    if (error) {
        DDLogError(@"Error hold call: %@", error);
    } else {
        [self updateButtons];
    }
}

- (IBAction)muteButtonPressed:(SipCallingButton *)sender {
    NSError *error;
    [self.call toggleMute:&error];
    if (error) {
        DDLogError(@"Error mute call: %@", error);
    } else {
        [self updateButtons];
    }
}

- (IBAction)numbersButton:(SipCallingButton *)sender {

}

- (IBAction)speakerButton:(SipCallingButton *)sender {
    [sender setSelected:!sender.isSelected];
}

- (void)updateButtons {
    dispatch_async(dispatch_get_main_queue(), ^{
        DDLogInfo(@"callstate: %d", self.call.callState);
        switch (self.call.callState) {
            case VSLCallStateNull: {
                self.holdButton.enabled = NO;
                self.muteButton.enabled = NO;
                break;
            }
            case VSLCallStateCalling: {
                self.holdButton.enabled = NO;
                self.muteButton.enabled = NO;
                break;
            }
            case VSLCallStateIncoming: {
                self.holdButton.enabled = NO;
                self.muteButton.enabled = NO;
                break;
            }
            case VSLCallEarlyState: {
                self.holdButton.enabled = NO;
                self.muteButton.enabled = NO;
                break;
            }
            case VSLCallStateConnecting: {
                self.holdButton.enabled = NO;
                self.muteButton.enabled = NO;
                break;
            }
            case VSLCallStateConfirmed: {
                self.holdButton.enabled = YES;
                self.muteButton.enabled = YES;
                break;
            }
            case VSLCallStateDisconnected: {
                self.holdButton.enabled = NO;
                self.muteButton.enabled = NO;
                break;
            }
        }
        self.holdButton.active = self.call.onHold;
        self.muteButton.active = self.call.muted;
    });
}

#pragma mark - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context {
    if (object == self.call) {
        [self updateButtons];
    }
}

@end