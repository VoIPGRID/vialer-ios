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
static NSString * const SIPCallingButtonsViewControllerCallState    = @"callState";
static NSString * const SIPCallingButtonsViewControllerMediaState   = @"mediaState";
static NSString * const SIPCallingButtonsViewControllerSpeaker      = @"speaker";

@interface SipCallingButtonsViewController ()
@property (strong, nonatomic) IBOutletCollection(UILabel) NSArray *sipCallingLabels;
@property (weak, nonatomic) IBOutlet SipCallingButton *numbersButton;
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
    [self.call removeObserver:self forKeyPath:SIPCallingButtonsViewControllerSpeaker];
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
    if (_call && call) {
        [_call removeObserver:self forKeyPath:SIPCallingButtonsViewControllerCallState];
        [_call removeObserver:self forKeyPath:SIPCallingButtonsViewControllerMediaState];
        [_call removeObserver:self forKeyPath:SIPCallingButtonsViewControllerSpeaker];
    }
    _call = call;
    [call addObserver:self forKeyPath:SIPCallingButtonsViewControllerCallState options:0 context:NULL];
    [call addObserver:self forKeyPath:SIPCallingButtonsViewControllerMediaState options:0 context:NULL];
    [call addObserver:self forKeyPath:SIPCallingButtonsViewControllerSpeaker options:0 context:NULL];
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

- (IBAction)speakerButtonPressed:(SipCallingButton *)sender {
    [self.call toggleSpeaker];
}

- (IBAction)numbersButton:(SipCallingButton *)sender {

}

- (void)updateButtons {
    dispatch_async(dispatch_get_main_queue(), ^{
        DDLogInfo(@"callstate: %ld", (long)self.call.callState);
        DDLogInfo(@"mediastate: %ld", (long)self.call.mediaState);
        DDLogInfo(@"speaker: %ld", (long)self.call.speaker);
        switch (self.call.callState) {
            case VSLCallStateNull: {
                self.holdButton.enabled     = NO;
                self.muteButton.enabled     = NO;
                self.speakerButton.enabled  = NO;
                break;
            }
            case VSLCallStateCalling: {
                self.holdButton.enabled     = NO;
                self.muteButton.enabled     = NO;
                self.speakerButton.enabled  = NO;
                break;
            }
            case VSLCallStateIncoming: {
                self.holdButton.enabled     = NO;
                self.muteButton.enabled     = NO;
                self.speakerButton.enabled  = NO;
                break;
            }
            case VSLCallEarlyState: {
                self.holdButton.enabled     = NO;
                self.muteButton.enabled     = NO;
                self.speakerButton.enabled  = NO;
                break;
            }
            case VSLCallStateConnecting: {
                self.holdButton.enabled     = NO;
                self.muteButton.enabled     = NO;
                self.speakerButton.enabled  = NO;
                break;
            }
            case VSLCallStateConfirmed: {
                self.holdButton.enabled     = YES;
                self.muteButton.enabled     = YES;
                self.speakerButton.enabled  = YES;
                break;
            }
            case VSLCallStateDisconnected: {
                self.holdButton.enabled     = NO;
                self.muteButton.enabled     = NO;
                self.speakerButton.enabled  = NO;
                break;
            }
        }
        self.holdButton.active = self.call.onHold;
        self.muteButton.active = self.call.muted;
        self.speakerButton.active = self.call.speaker;
    });
}

#pragma mark - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context {
    if (object == self.call) {
        [self updateButtons];
    }
}

@end